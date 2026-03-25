import 'types.dart';

/// Per-day chart rows + summary totals (Weekly / Monthly period windows).
class DailySettlementResult {
  final List<SettlementData> days;
  final int totalSales;
  final int totalExpenses;
  final int totalProfit;
  final int totalOrders;

  DailySettlementResult({
    required this.days,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalProfit,
    required this.totalOrders,
  });

  static DailySettlementResult empty() {
    return DailySettlementResult(
      days: [],
      totalSales: 0,
      totalExpenses: 0,
      totalProfit: 0,
      totalOrders: 0,
    );
  }
}
