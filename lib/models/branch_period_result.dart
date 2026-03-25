import 'types.dart';

/// Per-day chart rows + summary totals (Weekly tab and Monthly tab period windows).
class DailySettlementResult {
  final List<SettlementData> days;
  final int totalSales;
  final int totalExpenses;
  final int totalProfit;
  final int totalOrders;
  final int totalBuyIn;
  final int totalGames;
  final int totalRolling;
  final double avgRolling;
  final int totalWinLoss;
  final double winRatePercent;

  DailySettlementResult({
    required this.days,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalProfit,
    required this.totalOrders,
    required this.totalBuyIn,
    required this.totalGames,
    required this.totalRolling,
    required this.avgRolling,
    required this.totalWinLoss,
    required this.winRatePercent,
  });

  static DailySettlementResult empty() {
    return DailySettlementResult(
      days: [],
      totalSales: 0,
      totalExpenses: 0,
      totalProfit: 0,
      totalOrders: 0,
      totalBuyIn: 0,
      totalGames: 0,
      totalRolling: 0,
      avgRolling: 0,
      totalWinLoss: 0,
      winRatePercent: 0,
    );
  }
}
