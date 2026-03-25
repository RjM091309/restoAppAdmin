import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../models/types.dart';

/// Flutter top-menu data for a branch.
///
/// Matches the admin logic in `restoAdmin/src/components/analytics/MenuReport.tsx`:
/// - product selection uses `/api/analytics/top-selling` (limit = top-N)
/// - displayed value uses `netSales` from `/api/analytics/menu-report`, matched by product name
class TopMenuService {
  TopMenuService._();
  static final TopMenuService instance = TopMenuService._();

  static String _normalizeMenuName(String value) {
    // More forgiving key for fuzzy matching.
    // - replace NBSP with space
    // - remove zero-width spaces
    // - collapse whitespace runs
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static String _jsTrimLowerKey(String value) {
    // Exact-ish replica of JS: `.trim().toLowerCase()` (no internal whitespace collapsing).
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .trim()
        .toLowerCase();
  }

  static String _ymd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _double(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// [branchId] numeric string; `0` or invalid = all branches (no filter).
  /// Default range: month-to-date (1st of month → today).
  Future<List<MenuItem>> fetchTopMenu({
    required String branchId,
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = start ?? DateTime(now.year, now.month, 1);
    final endDate = end ?? today;
    final bid = int.tryParse(branchId) ?? 0;
    final effectiveLimit = limit.clamp(1, 50);

    final startStr = _ymd(startDate);
    final endStr = _ymd(endDate);

    final qpTopSelling = <String, String>{
      'start_date': startStr,
      'end_date': endStr,
      'limit': '$effectiveLimit',
    };
    final qpMenuReport = <String, String>{
      'start_date': startStr,
      'end_date': endStr,
    };
    if (bid > 0) {
      qpTopSelling['branch_id'] = '$bid';
      qpMenuReport['branch_id'] = '$bid';
    }

    try {
      final topSellingUri = Uri.parse('$analyticsBaseUrl/api/analytics/top-selling')
          .replace(queryParameters: qpTopSelling);
      final menuReportUri =
          Uri.parse('$analyticsBaseUrl/api/analytics/menu-report').replace(queryParameters: qpMenuReport);

      final topSellingRes = await http.get(topSellingUri, headers: {'Content-Type': 'application/json'});
      if (topSellingRes.statusCode != 200) return [];

      final menuReportRes = await http.get(menuReportUri, headers: {'Content-Type': 'application/json'});
      if (menuReportRes.statusCode != 200) return [];

      final topSellingJson = jsonDecode(topSellingRes.body);
      final menuReportJson = jsonDecode(menuReportRes.body);
      if (topSellingJson is! Map || menuReportJson is! Map) return [];
      if (topSellingJson['success'] != true || menuReportJson['success'] != true) return [];

      final topList = (topSellingJson['data'] as Map)['data'];
      final menuList = (menuReportJson['data'] as Map)['data'];
      if (topList is! List || menuList is! List) return [];

      // Map by product name (case-insensitive) to replicate `rows.find(...)` behavior in MenuReport.tsx.
      final menuByName = <String, Map<String, dynamic>>{};
      final menuById = <String, Map<String, dynamic>>{};
      for (final row in menuList) {
        if (row is! Map) continue;
        final goods = (row['goods'] ?? '').toString();
        if (goods.isEmpty) continue;
        final rowMap = Map<String, dynamic>.from(row);
        final idVal = row['id'];
        if (idVal != null) {
          menuById[idVal.toString()] = rowMap;
        }
        final normKey = _normalizeMenuName(goods);
        final jsKey = _jsTrimLowerKey(goods);
        menuByName[normKey] = rowMap;
        // Also store JS key to maximize chance of exact match.
        menuByName[jsKey] = menuByName[jsKey] ?? rowMap;
      }

      final out = <MenuItem>[];
      for (final row in topList) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final name = (m['MENU_NAME'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final price = _double(m['MENU_PRICE']).round();
        final fallbackQty = _int(m['total_quantity']);
        final fallbackRevenue = _double(m['total_revenue']).round();

        final topId = m['IDNo'];
        final menuRow =
            (topId != null ? menuById[topId.toString()] : null) ??
            (() {
              final normKey = _normalizeMenuName(name);
              final jsKey = _jsTrimLowerKey(name);
              return menuByName[normKey] ?? menuByName[jsKey];
            })();
        final totalSales = menuRow != null ? _double(menuRow['netSales']).round() : fallbackRevenue;
        final totalOrders = menuRow != null ? _int(menuRow['salesQty']) : fallbackQty;

        out.add(MenuItem(
          id: '${m['IDNo'] ?? name.hashCode}',
          name: name,
          price: price,
          totalSales: totalSales,
          totalOrders: totalOrders,
        ));
      }

      return out;
    } catch (_) {
      return [];
    }
  }
}
