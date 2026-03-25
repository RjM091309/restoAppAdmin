import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_config.dart';
import 'auth_service.dart';
import '../models/realtime_data.dart';

class BranchCardData {
  final String id;
  final String name;
  final String code;

  const BranchCardData({
    required this.id,
    required this.name,
    required this.code,
  });
}

class BranchPerformanceData {
  final int id;
  final String name;
  final int totalSales;
  final int totalExpenses;
  final int totalOrders;

  const BranchPerformanceData({
    required this.id,
    required this.name,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalOrders,
  });
}

class DashboardSummaryData {
  final int totalSales;
  final int totalExpenses;
  final int totalProfit;

  const DashboardSummaryData({
    required this.totalSales,
    required this.totalExpenses,
    required this.totalProfit,
  });

  const DashboardSummaryData.empty()
      : totalSales = 0,
        totalExpenses = 0,
        totalProfit = 0;
}

class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  final StreamController<RealtimeData> _realtimeController = StreamController<RealtimeData>.broadcast();

  Stream<RealtimeData> get realtimeStream => _realtimeController.stream;

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _toYYYYMMDD(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode != 200) return null;
      return _parseJson(res.body);
    } catch (_) {
      return null;
    }
  }

  Future<List<BranchCardData>> fetchBranches() async {
    try {
      final token = await AuthService.instance.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(Uri.parse('$apiBaseUrl/branch'), headers: headers);
      if (res.statusCode != 200) return const [];
      final json = _parseJson(res.body);
      if (json == null || json['success'] != true) return const [];
      final rawList = json['data'];
      if (rawList is! List) return const [];
      return rawList.map((e) {
        final m = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        return BranchCardData(
          id: (m['IDNo'] ?? '').toString(),
          name: (m['BRANCH_NAME'] ?? '').toString().trim(),
          code: (m['BRANCH_CODE'] ?? '').toString().trim(),
        );
      }).where((b) => b.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<RealtimeData> fetchRealtime() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return const RealtimeData.empty();
      final res = await http.get(
        Uri.parse(realtimeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) return const RealtimeData.empty();
      final json = _parseJson(res.body);
      if (json == null) return const RealtimeData.empty();
      return RealtimeData.fromJson(json);
    } catch (_) {
      return const RealtimeData.empty();
    }
  }

  Future<List<BranchPerformanceData>> fetchBranchPerformance() async {
    try {
      final now = DateTime.now();
      final start = _toYYYYMMDD(DateTime(now.year, now.month, 1));
      final end = _toYYYYMMDD(now);

      final branchSalesUri = Uri.parse(
        '$analyticsBaseUrl/api/analytics/branch-sales?start_date=$start&end_date=$end',
      );
      final branchSalesJson = await _getJson(branchSalesUri);
      if (branchSalesJson == null || branchSalesJson['success'] != true) return const [];
      final rootData = branchSalesJson['data'];
      if (rootData is! Map || rootData['data'] is! List) return const [];
      final branchRows = rootData['data'] as List;

      final rows = await Future.wait(branchRows.map((row) async {
        final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
        final branchId = _toInt(m['branch_id']);
        if (branchId <= 0) return null;

        // RealTime "branch stats" tiles should match Monthly "Sales / Month" and "Profit / Month".
        // Monthly uses `daily-sales` aggregated over MTD, while `branch-sales` can differ depending on backend logic.
        final dailySalesUri = Uri.parse(
          '$analyticsBaseUrl/api/analytics/daily-sales?branch_id=$branchId&start_date=$start&end_date=$end',
        );
        final expenseUri = Uri.parse(
          '$analyticsBaseUrl/api/analytics/expense-summary?branch_id=$branchId&start_date=$start&end_date=$end',
        );

        final results = await Future.wait([
          _getJson(dailySalesUri),
          _getJson(expenseUri),
        ]);

        final dailySalesJson = results[0];
        final expenseJson = results[1];

        int totalSalesFromDaily = 0;
        if (dailySalesJson != null && dailySalesJson['success'] == true) {
          final d = dailySalesJson['data'];
          if (d is Map && d['data'] is List) {
            for (final item in (d['data'] as List)) {
              if (item is! Map) continue;
              totalSalesFromDaily += _toInt(item['total_sales']);
            }
          }
        }

        int totalExpense = 0;
        if (expenseJson != null && expenseJson['success'] == true) {
          final expenseData = expenseJson['data'];
          if (expenseData is Map) {
            totalExpense = _toInt(expenseData['total_expense']);
          }
        }

        return BranchPerformanceData(
          id: branchId,
          name: (m['branch_name'] ?? '').toString().trim(),
          // Fallback to `branch-sales` if daily-sales is empty/unavailable.
          totalSales: totalSalesFromDaily > 0 ? totalSalesFromDaily : _toInt(m['total_sales']),
          totalExpenses: totalExpense,
          totalOrders: _toInt(m['order_count']),
        );
      }));

      return rows.whereType<BranchPerformanceData>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<DashboardSummaryData> fetchDashboardSummary() async {
    try {
      final now = DateTime.now();
      final start = _toYYYYMMDD(DateTime(now.year, now.month, 1));
      final end = _toYYYYMMDD(now);

      final dailySalesUri = Uri.parse(
        '$analyticsBaseUrl/api/analytics/daily-sales?start_date=$start&end_date=$end',
      );
      final expenseSummaryUri = Uri.parse(
        '$analyticsBaseUrl/api/analytics/expense-summary?start_date=$start&end_date=$end',
      );
      // If `daily-sales` returns an empty payload (some backends do this depending on implementation),
      // fall back to `branch-sales` totals so the "Sales / Month" and "Profit / Month" tiles stay correct.
      final branchSalesUri = Uri.parse(
        '$analyticsBaseUrl/api/analytics/branch-sales?start_date=$start&end_date=$end',
      );

      final results = await Future.wait([
        _getJson(dailySalesUri),
        _getJson(expenseSummaryUri),
        _getJson(branchSalesUri),
      ]);
      final dailySalesJson = results[0];
      final expenseSummaryJson = results[1];
      final branchSalesJson = results[2];

      int totalSalesFromDaily = 0;
      if (dailySalesJson != null && dailySalesJson['success'] == true) {
        final d = dailySalesJson['data'];
        if (d is Map && d['data'] is List) {
          for (final item in (d['data'] as List)) {
            if (item is! Map) continue;
            totalSalesFromDaily += _toInt(item['total_sales']);
          }
        }
      }

      int totalSalesFromBranch = 0;
      if (branchSalesJson != null && branchSalesJson['success'] == true) {
        final rootData = branchSalesJson['data'];
        if (rootData is Map && rootData['data'] is List) {
          for (final row in (rootData['data'] as List)) {
            if (row is! Map) continue;
            totalSalesFromBranch += _toInt(row['total_sales']);
          }
        }
      }

      final totalSales = totalSalesFromDaily > 0 ? totalSalesFromDaily : totalSalesFromBranch;

      int totalExpenses = 0;
      if (expenseSummaryJson != null && expenseSummaryJson['success'] == true) {
        final d = expenseSummaryJson['data'];
        if (d is Map) {
          totalExpenses = _toInt(d['total_expense']);
        }
      }

      return DashboardSummaryData(
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        totalProfit: totalSales - totalExpenses,
      );
    } catch (_) {
      return const DashboardSummaryData.empty();
    }
  }

  Map<String, dynamic>? _parseJson(String body) {
    try {
      if (body.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Connect to Socket.IO and push each 'realtime' payload to [realtimeStream].
  void connectSocket() {
    if (_socket != null && _socket!.connected) return;
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .build(),
    );
    _socket!.on('realtime', (data) {
      try {
        final map = data is Map ? Map<String, dynamic>.from(data) : _parseJson(data is String ? data : '{}');
        if (map != null) _realtimeController.add(RealtimeData.fromJson(map));
      } catch (_) {}
    });
    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});
    _socket!.onError((err) {});
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnectSocket();
    _realtimeController.close();
  }
}
