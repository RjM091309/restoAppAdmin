import '../models/branch_period_result.dart';
import 'branch_period_analytics_service.dart';

export '../models/branch_period_result.dart';

/// Weekly tab: branch period analytics from PyServer ([BranchPeriodAnalyticsService]).
class DailySettlementService {
  DailySettlementService._();
  static final DailySettlementService instance = DailySettlementService._();

  /// Fetches branch analytics for Weekly tab (last 7 days or custom range).
  Future<DailySettlementResult> fetch({
    required String branchId,
    DateTime? start,
    DateTime? end,
    DateTime? summaryStart,
    DateTime? summaryEnd,
    int weekOffset = 0,
    bool useWeekdayLabels = true,
  }) {
    return BranchPeriodAnalyticsService.instance.fetch(
      branchId: branchId,
      start: start,
      end: end,
      summaryStart: summaryStart,
      summaryEnd: summaryEnd,
      weekOffset: weekOffset,
      useWeekdayLabels: useWeekdayLabels,
    );
  }
}
