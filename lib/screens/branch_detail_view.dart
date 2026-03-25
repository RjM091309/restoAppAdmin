import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'daily_settlement_view.dart';
import 'topmenu_view.dart';
import 'monthly_view.dart';
import 'expenses_view.dart';

/// Detail screen for a selected branch: header shows branch name, 4 tabs (Weekly, Monthly, Top Menu, Expenses).
class BranchDetailView extends StatefulWidget {
  const BranchDetailView({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  final String branchId;
  final String branchName;

  static void open(BuildContext context, {required String branchId, required String branchName}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => BranchDetailView(
          branchId: branchId,
          branchName: branchName,
        ),
      ),
    );
  }

  @override
  State<BranchDetailView> createState() => _BranchDetailViewState();
}

class _BranchDetailViewState extends State<BranchDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<MonthlyViewState> _monthlyKey = GlobalKey<MonthlyViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Nearest tab from scroll position — [TabController.index] often lags until swipe ends.
  int _effectiveTabIndex() {
    final n = _tabController.length;
    final v = _tabController.animation?.value ?? _tabController.index.toDouble();
    return (v + 0.5).floor().clamp(0, n - 1);
  }

  Widget _monthlyAppBarTrailing() {
    final s = _monthlyKey.currentState;
    if (s == null) {
      return buildMonthlyPeriodToolbar(
        rangeText: '',
        canGoPrevious: false,
        canGoNext: false,
        onPrevious: () {},
        onNext: () {},
      );
    }
    return buildMonthlyPeriodToolbar(
      rangeText: s.periodRangeLabel,
      canGoPrevious: s.canNavigatePrevious,
      canGoNext: s.canNavigateNext,
      onPrevious: s.navigatePrevious,
      onNext: s.navigateNext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final showMonthlyTrailing = _effectiveTabIndex() == 1;
        // Top menu should always show current month (MTD), not the sliding monthly window.
        final now = DateTime.now();
        final topMenuStartDate = DateTime(now.year, now.month, 1);
        final topMenuEndDate = DateTime(now.year, now.month, now.day);
        return Scaffold(
          backgroundColor: surfaceColor,
          appBar: AppBar(
            title: Text(
              widget.branchName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            backgroundColor: surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              iconSize: 32,
              padding: const EdgeInsets.all(12),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: primaryIndigo,
                      unselectedLabelColor: Colors.grey[400],
                      indicatorColor: primaryIndigo,
                      dividerColor: borderColor,
                      tabs: [
                        Tab(text: l10n.navWeekly),
                        Tab(text: l10n.navMonthly),
                        Tab(text: l10n.menuTitle),
                        Tab(text: l10n.expensesTitle),
                      ],
                    ),
                  ),
                  if (showMonthlyTrailing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 2),
                      child: _monthlyAppBarTrailing(),
                    ),
                ],
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final padding = MediaQuery.of(context).padding;
              final fallbackHeight =
                  MediaQuery.sizeOf(context).height - (padding.top + padding.bottom);
              final height =
                  maxH.isFinite && maxH > 0 ? maxH : fallbackHeight.clamp(200.0, double.infinity);
              return SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DailySettlementView(branchId: widget.branchId),
                      MonthlyView(
                        key: _monthlyKey,
                        branchId: widget.branchId,
                        onToolbarChanged: () {
                          if (mounted) setState(() {});
                        },
                      ),
                      TopMenuView(
                        branchId: widget.branchId,
                        startDate: topMenuStartDate,
                        endDate: topMenuEndDate,
                      ),
                      ExpensesView(branchId: widget.branchId),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
