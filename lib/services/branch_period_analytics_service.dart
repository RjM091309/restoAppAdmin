import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../models/branch_period_result.dart';
import '../models/types.dart';

/// Shared PyServer analytics calls for date-range branch charts (Weekly + Monthly UIs).
class BranchPeriodAnalyticsService {
  BranchPeriodAnalyticsService._();
  static final BranchPeriodAnalyticsService instance = BranchPeriodAnalyticsService._();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
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

  static String _dateLabel(
    String yyyyMmDd,
    DateTime today,
    List<String> weekdays, {
    required bool useWeekdayLabels,
  }) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length != 3) return yyyyMmDd;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      final dt = DateTime(y, m, d);
      if (useWeekdayLabels && dt.year == today.year && dt.month == today.month && dt.day == today.day) {
        return 'Today';
      }
      if (!useWeekdayLabels) return d.toString();
      return weekdays[dt.weekday - 1];
    } catch (_) {
      return yyyyMmDd;
    }
  }

  String _toYYYYMMDD(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Map<String, dynamic>? _parseJson(String body) {
    try {
      if (body.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Branch analytics for a chart window + optional summary range (PyServer).
  Future<DailySettlementResult> fetch({
    required String branchId,
    DateTime? start,
    DateTime? end,
    DateTime? summaryStart,
    DateTime? summaryEnd,
    int weekOffset = 0,
    bool useWeekdayLabels = true,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime chartStartDate;
    DateTime chartEndDate;
    DateTime summaryStartDate;
    DateTime summaryEndDate;
    if (start != null && end != null) {
      chartStartDate = start;
      chartEndDate = end;
      summaryStartDate = summaryStart ?? start;
      summaryEndDate = summaryEnd ?? end;
    } else {
      chartEndDate = today.add(Duration(days: weekOffset * 7));
      chartStartDate = chartEndDate.subtract(const Duration(days: 6));
      summaryEndDate = summaryEnd ?? today;
      summaryStartDate = summaryStart ?? today;
    }
    final chartStartStr = _toYYYYMMDD(chartStartDate);
    final chartEndStr = _toYYYYMMDD(chartEndDate);
    final summaryStartStr = _toYYYYMMDD(summaryStartDate);
    final summaryEndStr = _toYYYYMMDD(summaryEndDate);
    try {
      final branchIdInt = int.tryParse(branchId) ?? 0;
      final hasBranchFilter = branchIdInt > 0;

      // When branchId == '0', treat as "all branches": omit `branch_id` query param.
      final chartQ = hasBranchFilter
          ? 'branch_id=$branchIdInt&start_date=$chartStartStr&end_date=$chartEndStr'
          : 'start_date=$chartStartStr&end_date=$chartEndStr';
      final rangeDays = chartEndDate.difference(chartStartDate).inDays + 1;
      final previousWeekStartDate = chartStartDate.subtract(Duration(days: rangeDays));
      final previousWeekEndDate = chartStartDate.subtract(const Duration(days: 1));
      final previousWeekQ =
          hasBranchFilter
              ? 'branch_id=$branchIdInt&start_date=${_toYYYYMMDD(previousWeekStartDate)}&end_date=${_toYYYYMMDD(previousWeekEndDate)}'
              : 'start_date=${_toYYYYMMDD(previousWeekStartDate)}&end_date=${_toYYYYMMDD(previousWeekEndDate)}';
      final summaryQ = hasBranchFilter
          ? 'branch_id=$branchIdInt&start_date=$summaryStartStr&end_date=$summaryEndStr'
          : 'start_date=$summaryStartStr&end_date=$summaryEndStr';
      final chartDailySalesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-sales?$chartQ');
      final chartDailyOrdersUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-orders?$chartQ');
      final chartDailyExpensesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-expenses?$chartQ');
      final previousWeekDailySalesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-sales?$previousWeekQ');
      final previousWeekDailyExpensesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-expenses?$previousWeekQ');
      final summaryDailySalesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-sales?$summaryQ');
      final summaryDailyOrdersUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-orders?$summaryQ');
      final summaryDailyExpensesUri = Uri.parse('$analyticsBaseUrl/api/analytics/daily-expenses?$summaryQ');
      final expenseSummaryUri = Uri.parse('$analyticsBaseUrl/api/analytics/expense-summary?$summaryQ');
      final branchSalesUri = Uri.parse('$analyticsBaseUrl/api/analytics/branch-sales?$summaryQ');

      final results = await Future.wait([
        _getJson(chartDailySalesUri),
        _getJson(chartDailyOrdersUri),
        _getJson(chartDailyExpensesUri),
        _getJson(previousWeekDailySalesUri),
        _getJson(previousWeekDailyExpensesUri),
        _getJson(summaryDailySalesUri),
        _getJson(summaryDailyOrdersUri),
        _getJson(summaryDailyExpensesUri),
        _getJson(expenseSummaryUri),
        _getJson(branchSalesUri),
      ]);

      final chartDailySalesJson = results[0];
      final chartDailyOrdersJson = results[1];
      final chartDailyExpensesJson = results[2];
      final previousWeekDailySalesJson = results[3];
      final previousWeekDailyExpensesJson = results[4];
      final summaryDailySalesJson = results[5];
      final summaryDailyOrdersJson = results[6];
      final summaryDailyExpensesJson = results[7];
      final expenseSummaryJson = results[8];
      final branchSalesJson = results[9];

      final salesByDate = <String, int>{};
      final netByDate = <String, int>{};
      final discountByDate = <String, int>{};
      final ordersByDate = <String, int>{};
      final expensesByDate = <String, int>{};
      final previousPeriodSalesByDate = <String, int>{};
      final previousPeriodExpensesByDate = <String, int>{};

      if (chartDailySalesJson != null && chartDailySalesJson['success'] == true) {
        final data = chartDailySalesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            final date = (m['sale_date'] ?? '').toString();
            if (date.isEmpty) continue;
            salesByDate[date] = _toInt(m['total_sales']);
            netByDate[date] = _toInt(m['net_sales']);
            discountByDate[date] = _toInt(m['discount']);
          }
        }
      }

      if (chartDailyOrdersJson != null && chartDailyOrdersJson['success'] == true) {
        final data = chartDailyOrdersJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            final date = (m['sale_date'] ?? '').toString();
            if (date.isEmpty) continue;
            ordersByDate[date] = _toInt(m['order_count']);
          }
        }
      }

      if (chartDailyExpensesJson != null && chartDailyExpensesJson['success'] == true) {
        final data = chartDailyExpensesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            final date = (m['expense_date'] ?? '').toString();
            if (date.isEmpty) continue;
            expensesByDate[date] = _toInt(m['total_expense']);
          }
        }
      }

      if (previousWeekDailySalesJson != null && previousWeekDailySalesJson['success'] == true) {
        final data = previousWeekDailySalesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            final date = (m['sale_date'] ?? '').toString();
            if (date.isEmpty) continue;
            previousPeriodSalesByDate[date] = _toInt(m['total_sales']);
          }
        }
      }

      if (previousWeekDailyExpensesJson != null && previousWeekDailyExpensesJson['success'] == true) {
        final data = previousWeekDailyExpensesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            final date = (m['expense_date'] ?? '').toString();
            if (date.isEmpty) continue;
            previousPeriodExpensesByDate[date] = _toInt(m['total_expense']);
          }
        }
      }

      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayCount = chartEndDate.difference(chartStartDate).inDays + 1;
      final days = <SettlementData>[];
      for (var i = 0; i < dayCount; i++) {
        final d = chartStartDate.add(Duration(days: i));
        final date = _toYYYYMMDD(d);
        final sales = salesByDate[date] ?? 0;
        final expenses = expensesByDate[date] ?? 0;
        int lastWeekSales = 0;
        int lastWeekProfit = 0;
        try {
          final previousDate = d.subtract(Duration(days: rangeDays));
          final previousKey = _toYYYYMMDD(previousDate);
          lastWeekSales = previousPeriodSalesByDate[previousKey] ?? 0;
          final lastWeekExpenses = previousPeriodExpensesByDate[previousKey] ?? 0;
          lastWeekProfit = lastWeekSales - lastWeekExpenses;
        } catch (_) {}
        days.add(SettlementData(
          date: _dateLabel(
            date,
            today,
            weekdays,
            useWeekdayLabels: useWeekdayLabels,
          ),
          numGames: ordersByDate[date] ?? 0,
          buyIn: sales,
          lastWeekSales: lastWeekSales,
          lastWeekProfit: lastWeekProfit,
          rolling: netByDate[date] ?? sales,
          winLoss: sales - expenses,
          commission: discountByDate[date] ?? 0,
          expenses: expenses,
        ));
      }

      int totalSalesFromDaily = 0;
      if (summaryDailySalesJson != null && summaryDailySalesJson['success'] == true) {
        final data = summaryDailySalesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            totalSalesFromDaily += _toInt(m['total_sales']);
          }
        }
      }

      int totalExpensesFromDaily = 0;
      if (summaryDailyExpensesJson != null && summaryDailyExpensesJson['success'] == true) {
        final data = summaryDailyExpensesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            totalExpensesFromDaily += _toInt(m['total_expense']);
          }
        }
      }

      int totalOrdersFromDaily = 0;
      if (summaryDailyOrdersJson != null && summaryDailyOrdersJson['success'] == true) {
        final data = summaryDailyOrdersJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            totalOrdersFromDaily += _toInt(m['order_count']);
          }
        }
      }

      int totalSalesFromBranch = 0;
      int totalOrdersFromBranch = 0;
      if (branchSalesJson != null && branchSalesJson['success'] == true) {
        final data = branchSalesJson['data'];
        if (data is Map && data['data'] is List) {
          for (final row in data['data'] as List) {
            final m = Map<String, dynamic>.from((row as Map).cast<String, dynamic>());
            if (_toInt(m['branch_id']) == branchIdInt) {
              totalSalesFromBranch = _toInt(m['total_sales']);
              totalOrdersFromBranch = _toInt(m['order_count']);
              break;
            }
          }
        }
      }

      int totalExpensesFromSummary = 0;
      if (expenseSummaryJson != null && expenseSummaryJson['success'] == true) {
        final data = expenseSummaryJson['data'];
        if (data is Map) {
          totalExpensesFromSummary = _toInt(data['total_expense']);
        }
      }

      final totalSales = totalSalesFromDaily > 0 ? totalSalesFromDaily : totalSalesFromBranch;
      final totalExpenses = totalExpensesFromSummary > 0 ? totalExpensesFromSummary : totalExpensesFromDaily;
      final totalOrders = totalOrdersFromBranch > 0 ? totalOrdersFromBranch : totalOrdersFromDaily;
      final totalProfit = totalSales - totalExpenses;

      return DailySettlementResult(
        days: days,
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        totalProfit: totalProfit,
        totalOrders: totalOrders,
      );
    } catch (_) {
      return DailySettlementResult.empty();
    }
  }
}
