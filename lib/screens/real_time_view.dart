import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../generated/app_localizations.dart';
import '../models/realtime_data.dart';
import 'branch_detail_view.dart';
import '../services/realtime_service.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';
import '../widgets/active_view_scope.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/stat_card.dart';

final _fmt = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

Color _statCardAccent(StatCardColor color) {
  switch (color) {
    case StatCardColor.primary:
      return primaryIndigo;
    case StatCardColor.purple:
      return accentPurple;
    case StatCardColor.emerald:
      return emeraldAccent;
    case StatCardColor.rose:
      return roseAccent;
    case StatCardColor.amber:
      return amberAccent;
    case StatCardColor.teal:
      return tealAccent;
    case StatCardColor.brown:
      return brownAccent;
  }
}

/// 3 columns only when cells are wide enough; otherwise 2 columns to avoid cramped branch tiles.
int _branchGridCrossAxisCount(double width) {
  if (width >= 820) return 3;
  return 2;
}

/// Branch tiles use a denser 3-band layout (name / sales / profit+expenses).
double _branchGridAspectRatio(double width, bool landscape) {
  final isTabletWidth = width > 600 && width <= 1400;
  final isTabletPortrait = !landscape && width >= 600 && width < 900;
  if (landscape) return 1.85;
  // Mobile portrait: keep cards shorter and denser.
  if (width < 400) return 1.24;
  // Portrait tablets (e.g. iPad Mini width 768) should use shorter cards.
  if (isTabletPortrait) return 2.10;
  if (isTabletWidth) return 1.32;
  return 1.32;
}

/// Branch grid cell: prominent name, stacked sales, side-by-side profit & expenses (all amounts via [_fmt]).
Widget _branchPerformanceTile({
  required AppLocalizations l10n,
  required String branchName,
  required int totalSales,
  required int profit,
  required int expenses,
  required IconData icon,
  required StatCardColor color,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final accent = _statCardAccent(color);
      final isMobileTile = constraints.maxWidth < 200;
      final isCompact = constraints.maxHeight < 100 || constraints.maxWidth < 132;
      final pad = isCompact ? 8.5 : (isMobileTile ? 9.5 : 11.0);
      final nameFs = isCompact ? 12.0 : (isMobileTile ? 13.0 : 14.0);
      final salesLabelFs = isCompact ? 10.0 : (isMobileTile ? 10.5 : 11.0);
      final salesValueFs = isCompact ? 16.0 : (isMobileTile ? 17.5 : 19.0);
      final subLabelFs = isCompact ? 10.5 : (isMobileTile ? 11.0 : 12.0);
      final subValueFs = isCompact ? 12.0 : (isMobileTile ? 13.0 : 14.0);
      final iconBox = isCompact ? 6.0 : 8.0;
      final iconSize = isCompact ? 16.0 : 20.0;
      final sectionGap = isCompact ? 4.0 : (isMobileTile ? 4.0 : 5.0);
      final salesGap = isCompact ? 1.0 : (isMobileTile ? 1.0 : 2.0);

      return Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: isCompact ? 18 : 22,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 10),
                Expanded(
                  child: Text(
                    branchName,
                    style: TextStyle(
                      fontSize: nameFs,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconBox),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: iconSize, color: accent),
                ),
                SizedBox(width: isCompact ? 7 : (isMobileTile ? 8 : 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.branchTotalSalesHead.toUpperCase(),
                        style: TextStyle(
                          fontSize: salesLabelFs,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: salesGap),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fmt.format(totalSales),
                          style: TextStyle(
                            fontSize: salesValueFs,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionGap),
            Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.08)),
            SizedBox(height: sectionGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _branchMetricColumn(
                    label: l10n.branchProfitShort,
                    value: _fmt.format(profit),
                    labelFontSize: subLabelFs,
                    valueFontSize: subValueFs,
                    valueColor: emeraldAccent,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : (isMobileTile ? 6 : 8)),
                  child: SizedBox(
                    height: isCompact ? 30 : (isMobileTile ? 32 : 36),
                    child: VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                Expanded(
                  child: _branchMetricColumn(
                    label: l10n.branchExpensesShort,
                    value: _fmt.format(expenses),
                    labelFontSize: subLabelFs,
                    valueFontSize: subValueFs,
                    valueColor: amberAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _branchMetricColumn({
  required String label,
  required String value,
  required double labelFontSize,
  required double valueFontSize,
  required Color valueColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: labelFontSize,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: Colors.grey[500],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: labelFontSize > 10.5 ? 3 : 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ),
    ],
  );
}

Widget _skeletonGameCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 38, height: 38, borderRadius: 10),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 100, height: 14, borderRadius: 4),
                    SkeletonBox(width: 50, height: 18, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonBox(width: 70, height: 14, borderRadius: 4),
                    SizedBox(width: 12),
                    SkeletonBox(width: 70, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

class RealTimeView extends StatefulWidget {
  const RealTimeView({super.key, this.onPollTick});

  /// Called every time the realtime poll runs (same 3s). Use to sync e.g. notification fetch so toast/red dot update with ongoing games.
  final VoidCallback? onPollTick;

  @override
  State<RealTimeView> createState() => _RealTimeViewState();
}

class _RealTimeViewState extends State<RealTimeView> {
  final RealtimeService _service = RealtimeService.instance;
  RealtimeData _data = const RealtimeData.empty();
  List<BranchCardData> _branches = const [];
  List<BranchPerformanceData> _branchPerformance = const [];
  DashboardSummaryData _summary = const DashboardSummaryData.empty();
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // HTTP polling: refresh realtime data for UI. Notifications are created by server-side job only; app just fetches (GET).
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      widget.onPollTick?.call();
      Future.wait([
        _service.fetchBranches(),
        _service.fetchBranchPerformance(),
        _service.fetchDashboardSummary(),
      ]).then((result) {
        if (!mounted) return;
        setState(() {
          _branches = result[0] as List<BranchCardData>;
          _branchPerformance = result[1] as List<BranchPerformanceData>;
          _summary = result[2] as DashboardSummaryData;
        });
      });
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final futures = await Future.wait([
      _service.fetchBranches(),
      _service.fetchBranchPerformance(),
      _service.fetchDashboardSummary(),
    ]);
    final branches = futures[0] as List<BranchCardData>;
    final branchPerformance = futures[1] as List<BranchPerformanceData>;
    final summary = futures[2] as DashboardSummaryData;
    if (!mounted) return;
    if (ActiveViewScope.find(context)?.activeView != ViewType.realTime) return;
    setState(() {
      _branches = branches;
      _branchPerformance = branchPerformance;
      _summary = summary;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _localizedBranchName(AppLocalizations l10n, String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name.contains('kim')) return l10n.branchKimHyungje;
    if (name.contains('blue moon')) return l10n.branchBlueMoon;
    if (name.contains('daraejung') || name.contains('daraejeong')) {
      return l10n.branchDaraejeong;
    }
    if (name.contains('eesome')) return l10n.branchEssom;
    if (name.contains('paik')) return l10n.branchGeumhoBanjeom;
    return rawName;
  }

  int _branchDisplayOrder(String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name.contains('kim')) return 0; // 1st
    if (name.contains('blue moon')) return 1; // 2nd
    if (name.contains('daraejung') || name.contains('daraejeong')) return 2; // 3rd
    if (name.contains('eesome')) return 3; // 4th
    if (name.contains('paik') || name.contains('keumho') || name.contains('geumho')) return 4; // 5th
    if (name.contains('3core')) return 5; // 6th
    return 999;
  }

  Widget _buildSkeletonContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = _branchGridCrossAxisCount(w);
            final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
            final aspectRatio = _branchGridAspectRatio(w, isLandscape);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: List.generate(6, (_) => _skeletonStatCard()),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 18, height: 18, borderRadius: 6),
                        SizedBox(width: 8),
                        SkeletonBox(width: 120, height: 16, borderRadius: 4),
                      ],
                    ),
                    SkeletonBox(width: 36, height: 22, borderRadius: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(6, (_) => _skeletonGameCard()),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _skeletonStatCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 100 || constraints.maxWidth < 132;
        final padding = isCompact ? 10.0 : 14.0;
        final gap = isCompact ? 8.0 : 10.0;
        final iconBox = isCompact ? 30.0 : 36.0;
        final titleH = isCompact ? 10.0 : 12.0;
        final salesH = isCompact ? 16.0 : 20.0;
        final subH = isCompact ? 11.0 : 12.0;
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox(width: 3, height: 20, borderRadius: 4),
                  SizedBox(width: gap),
                  Expanded(child: SkeletonBox(width: double.infinity, height: titleH, borderRadius: 4)),
                ],
              ),
              SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: iconBox, height: iconBox, borderRadius: 10),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 56, height: titleH * 0.85, borderRadius: 4),
                        SizedBox(height: gap * 0.4),
                        SkeletonBox(width: 120, height: salesH, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 36, height: titleH * 0.9, borderRadius: 4),
                        const SizedBox(height: 4),
                        SkeletonBox(width: 72, height: subH, borderRadius: 4),
                      ],
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 36, height: titleH * 0.9, borderRadius: 4),
                        const SizedBox(height: 4),
                        SkeletonBox(width: 72, height: subH, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Wraps a StatCard so tapping it opens branch detail (Weekly/Monthly/Top Menu/Expenses).
  Widget _wrapStatCardTap(BuildContext context, String branchId, String branchName, Widget statCard) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => BranchDetailView.open(
          context,
          branchId: branchId,
          branchName: branchName,
        ),
        borderRadius: BorderRadius.circular(16),
        child: statCard,
      ),
    );
  }

  /// One card per data: title (매출/월, 지출/월, 순익/월) + value. Right side: trend badge.
  Widget _buildDataCard(String title, String value, IconData icon, Color color, {String? trendValue, bool? trendIsUp}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          if (trendValue != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (trendIsUp ?? true) ? emeraldAccent.withValues(alpha: 0.2) : roseAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(trendIsUp ?? true) ? '+' : '-'}$trendValue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (trendIsUp ?? true) ? emeraldAccent : roseAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading && _branchPerformance.isEmpty) {
      return _buildSkeletonContent(context);
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
              final branchCards = _branchPerformance.isNotEmpty
                  ? _branchPerformance
                  : _branches.map((b) => BranchPerformanceData(
                        id: int.tryParse(b.id) ?? 0,
                        name: b.name,
                        totalSales: 0,
                        totalExpenses: 0,
                        totalOrders: 0,
                      )).toList();
              // Keep card positions stable across refreshes.
              final sortedBranchCards = [...branchCards]..sort((a, b) {
                final byOrder = _branchDisplayOrder(a.name).compareTo(_branchDisplayOrder(b.name));
                if (byOrder != 0) return byOrder;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });
              final crossAxisCount = _branchGridCrossAxisCount(w);
              final aspectRatio = _branchGridAspectRatio(w, isLandscape);
              return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: (branchCards.isEmpty
                  ? [
                      StatCard(
                        label: l10n.noBranchesToday,
                        value: _fmt.format(0),
                        icon: Icons.store_mall_directory_outlined,
                        color: StatCardColor.primary,
                      ),
                    ]
                  : sortedBranchCards.asMap().entries.map((entry) {
                final idx = entry.key;
                final branch = entry.value;
                final colors = <StatCardColor>[
                  StatCardColor.primary,
                  StatCardColor.emerald,
                  StatCardColor.brown,
                  StatCardColor.rose,
                  StatCardColor.amber,
                  StatCardColor.purple,
                ];
                final icons = <IconData>[
                  Icons.storefront,
                  Icons.store,
                  Icons.store_mall_directory,
                  Icons.home_work,
                  Icons.location_city,
                  Icons.apartment,
                ];
                final name = _localizedBranchName(l10n, branch.name);
                final profit = branch.totalSales - branch.totalExpenses;
                return _wrapStatCardTap(
                  context,
                  branch.id.toString(),
                  name,
                  _branchPerformanceTile(
                    l10n: l10n,
                    branchName: name,
                    totalSales: branch.totalSales,
                    profit: profit,
                    expenses: branch.totalExpenses,
                    icon: icons[idx % icons.length],
                    color: colors[idx % colors.length],
                  ),
                );
              }).toList()),
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, size: 18, color: primaryIndigo),
                          const SizedBox(width: 8),
                          Text(l10n.activeBranches, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primaryIndigo.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(l10n.live, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryIndigo)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final totalSales = _summary.totalSales;
                      final totalExpenses = _summary.totalExpenses;
                      final totalProfit = _summary.totalProfit;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDataCard(l10n.sales, _fmt.format(totalSales), Icons.trending_up_rounded, primaryIndigo, trendValue: '5%', trendIsUp: true),
                          const SizedBox(height: 12),
                          _buildDataCard(l10n.expenses, _fmt.format(totalExpenses), Icons.trending_down_rounded, amberAccent, trendValue: '1%', trendIsUp: false),
                          const SizedBox(height: 12),
                          _buildDataCard(l10n.profit, _fmt.format(totalProfit), Icons.account_balance_wallet_rounded, emeraldAccent, trendValue: '8%', trendIsUp: true),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
