import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../models/types.dart';

class ExpensesAnalyticsService {
  ExpensesAnalyticsService._();
  static final ExpensesAnalyticsService instance = ExpensesAnalyticsService._();

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _toYYYYMMDD(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (res.statusCode != 200) return null;
      if (res.body.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<List<ExpenseCategoryItem>> fetchExpenseRankings({
    required String branchId,
    int topN = 7,
  }) async {
    final now = DateTime.now();
    final startCurrent = DateTime(now.year, now.month, 1);
    final endCurrent = DateTime(now.year, now.month, now.day);
    final prevMonth = now.month - 1;
    final prevYear = prevMonth <= 0 ? now.year - 1 : now.year;
    final prevMonthFixed = prevMonth <= 0 ? 12 : prevMonth;
    final startPrevious = DateTime(prevYear, prevMonthFixed, 1);
    final endPrevious = DateTime(prevYear, prevMonthFixed + 1, 0); // last day

    final bid = int.tryParse(branchId) ?? 0;

    Map<String, double> curByKey = {};
    Map<String, String> nameByKey = {};
    Map<String, String> catIdByKey = {};

    Future<void> loadInto({
      required DateTime start,
      required DateTime end,
      required bool isCurrent,
    }) async {
      final qp = <String, String>{
        'start_date': _toYYYYMMDD(start),
        'end_date': _toYYYYMMDD(end),
      };
      if (bid > 0) qp['branch_id'] = '$bid';

      final uri = Uri.parse('$analyticsBaseUrl/api/analytics/expense-breakdown')
          .replace(queryParameters: qp);

      final json = await _getJson(uri);
      if (json == null || json['success'] != true) return;
      final dataRoot = json['data'];
      if (dataRoot is! Map) return;
      final list = dataRoot['data'];
      if (list is! List) return;

      for (final row in list) {
        if (row is! Map) continue;
        final expCat = (row['exp_cat'] ?? '').toString().trim();
        final expName = (row['exp_name'] ?? '').toString().trim();
        if (expCat.isEmpty && expName.isEmpty) continue;

        // Use both fields to preserve uniqueness like backend grouping.
        final key = '$expCat|$expName';
        final totalAmount = _toDouble(row['total_amount']);

        // UI expects:
        // - item.name (big) = subname  => exp_name
        // - item.categoryId (small) = name => exp_cat
        nameByKey[key] = expName.isNotEmpty ? expName : expCat;
        catIdByKey[key] = expCat.isNotEmpty ? expCat : expName;

        if (isCurrent) {
          curByKey[key] = (curByKey[key] ?? 0) + totalAmount;
        } else {
          // We'll reuse curByKey for previous too by keeping a second map below.
        }
      }
    }

    final prevByKey = <String, double>{};

    Future<void> loadPrevious() async {
      final qp = <String, String>{
        'start_date': _toYYYYMMDD(startPrevious),
        'end_date': _toYYYYMMDD(endPrevious),
      };
      if (bid > 0) qp['branch_id'] = '$bid';

      final uri = Uri.parse('$analyticsBaseUrl/api/analytics/expense-breakdown')
          .replace(queryParameters: qp);

      final json = await _getJson(uri);
      if (json == null || json['success'] != true) return;
      final dataRoot = json['data'];
      if (dataRoot is! Map) return;
      final list = dataRoot['data'];
      if (list is! List) return;

      for (final row in list) {
        if (row is! Map) continue;
        final expCat = (row['exp_cat'] ?? '').toString().trim();
        final expName = (row['exp_name'] ?? '').toString().trim();
        if (expCat.isEmpty && expName.isEmpty) continue;

        final key = '$expCat|$expName';
        final totalAmount = _toDouble(row['total_amount']);
        prevByKey[key] = (prevByKey[key] ?? 0) + totalAmount;

        nameByKey[key] = expName.isNotEmpty ? expName : expCat;
        catIdByKey[key] = expCat.isNotEmpty ? expCat : expName;
      }
    }

    try {
      await loadInto(start: startCurrent, end: endCurrent, isCurrent: true);
      await loadPrevious();
    } catch (_) {
      return const [];
    }

    final keys = <String>{...curByKey.keys, ...prevByKey.keys};
    final list = <ExpenseCategoryItem>[];
    for (final key in keys) {
      final currentMonth = curByKey[key] ?? 0;
      final previousMonth = prevByKey[key] ?? 0;
      final change = currentMonth - previousMonth;

      list.add(
        ExpenseCategoryItem(
          rank: 0, // assigned after sorting
          name: nameByKey[key] ?? key,
          categoryId: catIdByKey[key] ?? '',
          currentMonth: currentMonth.toInt(),
          previousMonth: previousMonth.toInt(),
          change: change.toInt(),
        ),
      );
    }

    list.sort((a, b) => b.currentMonth.compareTo(a.currentMonth));
    final top = list.take(topN).toList();
    return top.asMap().entries.map((e) {
      final item = e.value;
      return ExpenseCategoryItem(
        rank: e.key + 1,
        name: item.name,
        categoryId: item.categoryId,
        currentMonth: item.currentMonth,
        previousMonth: item.previousMonth,
        change: item.change,
      );
    }).toList();
  }
}

