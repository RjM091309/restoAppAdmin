import '../models/branch_period_result.dart';
import '../models/types.dart';
import 'realtime_service.dart';

Map<String, dynamic> dailySettlementResultToJson(DailySettlementResult r) {
  return <String, dynamic>{
    'totalSales': r.totalSales,
    'totalExpenses': r.totalExpenses,
    'totalProfit': r.totalProfit,
    'totalOrders': r.totalOrders,
    'days': r.days
        .map((d) => <String, dynamic>{
              'date': d.date,
              'numGames': d.numGames,
              'buyIn': d.buyIn,
              'lastWeekSales': d.lastWeekSales,
              'lastWeekProfit': d.lastWeekProfit,
              'rolling': d.rolling,
              'winLoss': d.winLoss,
              'commission': d.commission,
              'expenses': d.expenses,
            })
        .toList(),
  };
}

DailySettlementResult dailySettlementResultFromJson(Map<String, dynamic> m) {
  final daysRaw = m['days'];
  final days = <SettlementData>[];
  if (daysRaw is List) {
    for (final row in daysRaw) {
      if (row is! Map) continue;
      final mm = Map<String, dynamic>.from(row as Map);
      days.add(SettlementData(
        date: (mm['date'] ?? '').toString(),
        numGames: _i(mm['numGames']),
        buyIn: _i(mm['buyIn']),
        lastWeekSales: _i(mm['lastWeekSales']),
        lastWeekProfit: _i(mm['lastWeekProfit']),
        rolling: _i(mm['rolling']),
        winLoss: _i(mm['winLoss']),
        commission: _i(mm['commission']),
        expenses: _i(mm['expenses']),
      ));
    }
  }
  return DailySettlementResult(
    days: days,
    totalSales: _i(m['totalSales']),
    totalExpenses: _i(m['totalExpenses']),
    totalProfit: _i(m['totalProfit']),
    totalOrders: _i(m['totalOrders']),
  );
}

List<Map<String, dynamic>> menuItemsToJson(List<MenuItem> items) {
  return items
      .map((e) => <String, dynamic>{
            'id': e.id,
            'name': e.name,
            'price': e.price,
            'totalSales': e.totalSales,
            'totalOrders': e.totalOrders,
          })
      .toList();
}

List<MenuItem> menuItemsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <MenuItem>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final m = Map<String, dynamic>.from(row as Map);
    out.add(MenuItem(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      price: _i(m['price']),
      totalSales: _i(m['totalSales']),
      totalOrders: _i(m['totalOrders']),
    ));
  }
  return out;
}

List<Map<String, dynamic>> expenseItemsToJson(List<ExpenseCategoryItem> items) {
  return items
      .map((e) => <String, dynamic>{
            'rank': e.rank,
            'name': e.name,
            'categoryId': e.categoryId,
            'currentMonth': e.currentMonth,
            'previousMonth': e.previousMonth,
            'change': e.change,
          })
      .toList();
}

List<ExpenseCategoryItem> expenseItemsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <ExpenseCategoryItem>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final m = Map<String, dynamic>.from(row as Map);
    out.add(ExpenseCategoryItem(
      rank: _i(m['rank']),
      name: (m['name'] ?? '').toString(),
      categoryId: (m['categoryId'] ?? '').toString(),
      currentMonth: _i(m['currentMonth']),
      previousMonth: _i(m['previousMonth']),
      change: _i(m['change']),
    ));
  }
  return out;
}

List<Map<String, dynamic>> branchesToJson(List<BranchCardData> branches) {
  return branches
      .map((b) => <String, dynamic>{
            'id': b.id,
            'name': b.name,
            'code': b.code,
          })
      .toList();
}

List<BranchCardData> branchesFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <BranchCardData>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final m = Map<String, dynamic>.from(row as Map);
    final id = (m['id'] ?? '').toString();
    if (id.isEmpty) continue;
    out.add(BranchCardData(
      id: id,
      name: (m['name'] ?? '').toString(),
      code: (m['code'] ?? '').toString(),
    ));
  }
  return out;
}

List<Map<String, dynamic>> branchPerformanceToJson(List<BranchPerformanceData> list) {
  return list
      .map((e) => <String, dynamic>{
            'id': e.id,
            'name': e.name,
            'totalSales': e.totalSales,
            'totalExpenses': e.totalExpenses,
            'totalOrders': e.totalOrders,
          })
      .toList();
}

List<BranchPerformanceData> branchPerformanceFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <BranchPerformanceData>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final m = Map<String, dynamic>.from(row as Map);
    out.add(BranchPerformanceData(
      id: _i(m['id']),
      name: (m['name'] ?? '').toString(),
      totalSales: _i(m['totalSales']),
      totalExpenses: _i(m['totalExpenses']),
      totalOrders: _i(m['totalOrders']),
    ));
  }
  return out;
}

Map<String, dynamic> dashboardSummaryToJson(DashboardSummaryData s) {
  return <String, dynamic>{
    'totalSales': s.totalSales,
    'totalExpenses': s.totalExpenses,
    'totalProfit': s.totalProfit,
  };
}

DashboardSummaryData dashboardSummaryFromJson(Map<String, dynamic> m) {
  return DashboardSummaryData(
    totalSales: _i(m['totalSales']),
    totalExpenses: _i(m['totalExpenses']),
    totalProfit: _i(m['totalProfit']),
  );
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

