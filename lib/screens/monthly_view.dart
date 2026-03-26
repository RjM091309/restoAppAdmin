import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../generated/app_localizations.dart';
import '../services/monthly_service.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';
import '../widgets/active_view_scope.dart';
import '../widgets/skeleton_box.dart';

String _fmt(num v) {
  return NumberFormat.compact(locale: 'en_PH').format(v);
}

String _fmtWL(int v) {
  final s = NumberFormat.compact(locale: 'en_PH').format(v.abs());
  return v >= 0 ? '+$s' : '-$s';
}

class _VerticalMonthlySalesBar extends StatelessWidget {
  final String date;
  final int thisMonthSales;
  final int lastMonthSales;
  final int maxSales;
  final bool animate;
  final bool isExpanded;

  const _VerticalMonthlySalesBar({
    required this.date,
    required this.thisMonthSales,
    required this.lastMonthSales,
    required this.maxSales,
    required this.animate,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final isSmall = media.width < 400;
    final labelFontSize = isExpanded ? 16.0 : (isCompact ? 10.0 : (isSmall ? 11.0 : 13.0));
    final thisMonthFontSize = isExpanded ? 15.0 : (isCompact ? 9.0 : (isSmall ? 10.0 : 12.0));
    final dateFontSize = isExpanded ? 14.0 : (isCompact ? 9.0 : (isSmall ? 10.0 : 12.0));
    final labelAreaHeight = isCompact ? 44.0 : (isSmall ? 50.0 : 56.0);
    final barMaxWidth = isCompact ? 32.0 : (isSmall ? 40.0 : 48.0);
    final sidePadding = isCompact ? 2.0 : 3.0;
    final barGap = 0.0;
    final labelBarGap = isCompact ? 4.0 : 6.0;
    final dateTopGap = isCompact ? 6.0 : 10.0;

    final maxY = maxSales <= 0 ? 1.0 : (maxSales * 1.15).toDouble();

    return LayoutBuilder(
      builder: (context, c) {
        final barMaxHeight = ((c.maxHeight - labelAreaHeight) * 0.92).clamp(20.0, 200.0);
        final thisMonthHeight = (thisMonthSales / maxY * barMaxHeight).clamp(0.0, barMaxHeight);
        final lastMonthHeight = (lastMonthSales / maxY * barMaxHeight).clamp(0.0, barMaxHeight);
        final rawWidth = c.maxWidth.isFinite ? c.maxWidth : 80.0;
        final maxContentWidth = (rawWidth - sidePadding * 2).clamp(40.0, 500.0);
        final barWidth = ((maxContentWidth - barGap) / 2).clamp(10.0, barMaxWidth);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_fmt(lastMonthSales), style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w700, color: Colors.grey.shade400)),
                          SizedBox(height: labelBarGap),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: animate ? lastMonthHeight : 0,
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade500,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: barGap),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_fmt(thisMonthSales), style: TextStyle(fontSize: thisMonthFontSize, fontWeight: FontWeight.w700, color: primaryIndigo)),
                          SizedBox(height: labelBarGap),
                          Transform.translate(
                            offset: const Offset(-0.8, 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              height: animate ? thisMonthHeight : 0,
                              width: barWidth,
                              decoration: BoxDecoration(
                                color: primaryIndigo,
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: dateTopGap),
            Text(
              date,
              style: TextStyle(fontSize: dateFontSize, fontWeight: FontWeight.w500, color: const Color(0xFFBDBDBD)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }
}

class _HorizontalMonthlyProfitBar extends StatelessWidget {
  /// Vertical gap between This Month / Last Month bars; must match [_commissionChartCard] row height math.
  static const double kBetweenBarsGap = 6.0;

  final String date;
  final int thisMonthProfit;
  final int lastMonthProfit;
  final double maxProfitAbs;
  final double barHeight;
  final bool animate;
  final bool isExpanded;

  const _HorizontalMonthlyProfitBar({
    required this.date,
    required this.thisMonthProfit,
    required this.lastMonthProfit,
    required this.maxProfitAbs,
    required this.barHeight,
    required this.animate,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final thisMonthRatio = maxProfitAbs > 0 ? (thisMonthProfit.abs() / maxProfitAbs) : 0.0;
    final lastMonthRatio = maxProfitAbs > 0 ? (lastMonthProfit.abs() / maxProfitAbs) : 0.0;
    final baseFontSize = isExpanded ? 16.0 : 10.0;
    final dateWidth = isExpanded ? 48.0 : 32.0;
    final valueWidth = isExpanded ? 92.0 : 72.0;
    final double dateToBarsGap = isExpanded ? 14.0 : 12.0;
    final double barsToValuesGap = isExpanded ? 12.0 : 10.0;

    return LayoutBuilder(
      builder: (context, rowConstraints) {
        final rowMaxH = rowConstraints.maxHeight;
        final compactFontSize = barHeight <= 6 ? 8.0 : (barHeight <= 8 ? 9.0 : baseFontSize);
        final valueGap = barHeight <= 6 ? 0.0 : 1.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: dateWidth,
              child: Text(date, style: TextStyle(fontSize: compactFontSize, color: const Color(0xFFBDBDBD))),
            ),
            SizedBox(width: dateToBarsGap),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final maxW = c.maxWidth;
                  // Row can give a loose maxHeight; tighten to the row's real height to avoid overflow.
                  final ch = c.maxHeight;
                  final rh = rowMaxH;
                  var boundH = double.infinity;
                  if (ch.isFinite && ch > 0) boundH = ch;
                  if (rh.isFinite && rh > 0) boundH = min(boundH, rh);
                  if (!boundH.isFinite || boundH <= 0) boundH = 40.0;
                  final gap = min(
                    _HorizontalMonthlyProfitBar.kBetweenBarsGap,
                    max(0.0, boundH * 0.22),
                  );
                  final hBar = min(barHeight, max(0.0, (boundH - gap) / 2));
                  final thisMonthW = (animate ? maxW * thisMonthRatio : 0.0).clamp(0.0, maxW);
                  final lastMonthW = (animate ? maxW * lastMonthRatio : 0.0).clamp(0.0, maxW);
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: hBar,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: hBar,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  width: thisMonthW,
                                  height: hBar,
                                  decoration: BoxDecoration(
                                    color: amberAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            height: hBar,
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: hBar,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  width: lastMonthW,
                                  height: hBar,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade500,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: barsToValuesGap),
            SizedBox(
              width: valueWidth,
              child: rowMaxH.isFinite && rowMaxH > 0
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: rowMaxH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fmtWL(thisMonthProfit),
                              style: TextStyle(fontSize: compactFontSize, fontWeight: FontWeight.w600, color: amberAccent, height: 1.0),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                            SizedBox(height: valueGap),
                            Text(
                              _fmtWL(lastMonthProfit),
                              style: TextStyle(fontSize: compactFontSize, fontWeight: FontWeight.w600, color: Colors.grey.shade400, height: 1.0),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtWL(thisMonthProfit),
                          style: TextStyle(fontSize: compactFontSize, fontWeight: FontWeight.w600, color: amberAccent, height: 1.0),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                        ),
                        SizedBox(height: valueGap),
                        Text(
                          _fmtWL(lastMonthProfit),
                          style: TextStyle(fontSize: compactFontSize, fontWeight: FontWeight.w600, color: Colors.grey.shade400, height: 1.0),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

Widget _profitLegendDot(Color color) {
  return Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Period label + prev/next for Monthly tab — used in [BranchDetailView] app bar (right) and was inline in body.
Widget buildMonthlyPeriodToolbar({
  required String rangeText,
  required bool canGoPrevious,
  required bool canGoNext,
  required VoidCallback onPrevious,
  required VoidCallback onNext,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (rangeText.isNotEmpty) ...[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 148),
          child: Text(
            'Showing days $rangeText',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 14),
      ],
      DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          type: MaterialType.transparency,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Previous period',
                child: SizedBox(
                  width: 40,
                  height: 36,
                  child: IconButton(
                    onPressed: canGoPrevious ? onPrevious : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: canGoPrevious ? Colors.white : Colors.grey[600],
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: canGoPrevious ? Colors.white : Colors.grey[600],
                      disabledForegroundColor: Colors.grey[700],
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: borderColorSubtle,
              ),
              Tooltip(
                message: 'Next period',
                child: SizedBox(
                  width: 40,
                  height: 36,
                  child: IconButton(
                    onPressed: canGoNext ? onNext : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: canGoNext ? Colors.white : Colors.grey[600],
                    ),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: canGoNext ? Colors.white : Colors.grey[600],
                      disabledForegroundColor: Colors.grey[700],
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Expanded / fullscreen: fetch MTD (start of month → today) and list all days in a scroll view.
class _MonthlyProfitFullscreenBody extends StatefulWidget {
  const _MonthlyProfitFullscreenBody({
    required this.branchId,
    required this.chartAnimate,
    this.onClose,
  });

  final String branchId;
  final bool chartAnimate;
  final VoidCallback? onClose;

  @override
  State<_MonthlyProfitFullscreenBody> createState() => _MonthlyProfitFullscreenBodyState();
}

class _MonthlyProfitFullscreenBodyState extends State<_MonthlyProfitFullscreenBody> {
  late Future<DailySettlementResult> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    _future = MonthlyService.instance.fetchPeriodForBranch(
      branchId: widget.branchId,
      start: startOfMonth,
      end: today,
      summaryStart: startOfMonth,
      summaryEnd: today,
      useWeekdayLabels: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final padding = isCompact ? 12.0 : 16.0;
    const titleSize = 18.0;
    final rowGap = isCompact ? 8.0 : 10.0;
    const rowH = 54.0;
    final innerGap = _HorizontalMonthlyProfitBar.kBetweenBarsGap;
    final barH = ((rowH - innerGap) / 2).clamp(3.0, 20.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, size: isCompact ? 16 : 18, color: amberAccent),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(child: Text(AppLocalizations.of(context).monthlyProfit, style: const TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.white))),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  iconSize: isCompact ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey[400],
                ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _profitLegendDot(amberAccent),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).thisMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              _profitLegendDot(Colors.grey.shade500),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).lastMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 14),
          Expanded(
            child: FutureBuilder<DailySettlementResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryIndigo));
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                    child: Text('Failed to load monthly profit', style: TextStyle(color: Colors.grey[400])),
                  );
                }
                final days = snapshot.data!.days;
                if (days.isEmpty) {
                  return Center(child: Text('No data', style: TextStyle(color: Colors.grey[400])));
                }
                final maxThis = days.map((e) => e.winLoss.abs()).reduce((a, b) => a > b ? a : b);
                final maxLast = days.map((e) => e.lastWeekProfit.abs()).reduce((a, b) => a > b ? a : b);
                final maxProfitAbs = (maxThis > maxLast ? maxThis : maxLast).toDouble();
                final scale = maxProfitAbs > 0 ? maxProfitAbs : 1.0;
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => SizedBox(height: rowGap),
                  itemBuilder: (context, i) {
                    return SizedBox(
                      height: rowH,
                      child: _HorizontalMonthlyProfitBar(
                        date: days[i].date,
                        thisMonthProfit: days[i].winLoss,
                        lastMonthProfit: days[i].lastWeekProfit,
                        maxProfitAbs: scale,
                        barHeight: barH,
                        animate: widget.chartAnimate,
                        isExpanded: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyView extends StatefulWidget {
  const MonthlyView({super.key, this.branchId = '0', this.onToolbarChanged});

  final String branchId;
  /// Notifies parent (e.g. [BranchDetailView]) to rebuild app bar period controls.
  final VoidCallback? onToolbarChanged;

  @override
  State<MonthlyView> createState() => MonthlyViewState();
}

class MonthlyViewState extends State<MonthlyView> with AutomaticKeepAliveClientMixin {
  bool _chartAnimate = false;
  bool _wasActive = false;
  bool _loading = true;
  bool _periodNavLoading = false;
  String? _error;
  DailySettlementResult _result = DailySettlementResult.empty();
  DateTime? _windowEnd;
  DateTime? _windowStart;
  int _loadSeq = 0;

  @override
  bool get wantKeepAlive => true;

  void _notifyToolbarChanged() => widget.onToolbarChanged?.call();

  /// Range label for app bar, e.g. `16-25`.
  String get periodRangeLabel {
    if (_windowStart == null || _windowEnd == null) return '';
    return '${_windowStart!.day}-${_windowEnd!.day}';
  }

  /// Exposes current window boundaries for other tabs (e.g. TopMenu).
  DateTime? get windowStart => _windowStart;

  /// Exposes current window boundaries for other tabs (e.g. TopMenu).
  DateTime? get windowEnd => _windowEnd;

  bool get canNavigatePrevious {
    if (_loading || _periodNavLoading) return false;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return (_windowStart ?? startOfMonth).isAfter(startOfMonth);
  }

  bool get canNavigateNext {
    if (_loading || _periodNavLoading) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (_windowEnd ?? today).isBefore(today);
  }

  void navigatePrevious() {
    if (_loading || _periodNavLoading) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextEnd = (_windowStart ?? today).subtract(const Duration(days: 1));
    // Lock immediately (before async) to prevent spam taps.
    setState(() => _periodNavLoading = true);
    _notifyToolbarChanged();
    _load(overrideWindowEnd: nextEnd);
  }

  void navigateNext() {
    if (_loading || _periodNavLoading) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final candidateEnd = (_windowEnd ?? today).add(const Duration(days: 10));
    final nextEnd = candidateEnd.isAfter(today) ? today : candidateEnd;
    // Lock immediately (before async) to prevent spam taps.
    setState(() => _periodNavLoading = true);
    _notifyToolbarChanged();
    _load(overrideWindowEnd: nextEnd);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = ActiveViewScope.maybeOf(context)?.activeView;
    if (active == null) return;
    final isActiveNow = active == ViewType.monthly;
    if (isActiveNow && !_wasActive && _result.days.isNotEmpty) {
      _restartChartAnimation();
    }
    _wasActive = isActiveNow;
  }

  void _restartChartAnimation() {
    if (!mounted) return;
    setState(() => _chartAnimate = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _chartAnimate = true);
    });
  }

  @override
  void didUpdateWidget(MonthlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) {
      _windowEnd = null;
      _windowStart = null;
      _load();
    }
  }

  /// [overrideWindowEnd] — prev/next: no full-screen skeleton; keep showing previous data until fetch completes.
  Future<void> _load({DateTime? overrideWindowEnd}) async {
    final periodNav = overrideWindowEnd != null;
    final seq = ++_loadSeq;
    if (periodNav) {
      setState(() {
        _error = null;
        _periodNavLoading = true;
      });
    } else {
      setState(() {
        _error = null;
        _loading = true;
        _periodNavLoading = false;
      });
    }
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final end = overrideWindowEnd ?? _windowEnd ?? today;
      final clampedEnd = end.isAfter(today) ? today : end;
      final startCandidate = clampedEnd.subtract(const Duration(days: 9));
      final start = startCandidate.isBefore(startOfMonth) ? startOfMonth : startCandidate;
      final result = await MonthlyService.instance.fetchPeriodForBranch(
        branchId: widget.branchId,
        start: start,
        end: clampedEnd,
        summaryStart: startOfMonth,
        summaryEnd: today,
        useWeekdayLabels: false,
      );
      if (!mounted) return;
      if (seq != _loadSeq) return; // ignore stale/out-of-order responses
      // If navigation fetch returns empty due to transient backend issues, keep existing data to avoid UI "blink".
      if (periodNav && result.days.isEmpty && _result.days.isNotEmpty) {
        setState(() => _periodNavLoading = false);
        _notifyToolbarChanged();
        return;
      }
      setState(() {
        _result = result;
        _windowStart = start;
        _windowEnd = clampedEnd;
        if (!periodNav) {
          _loading = false;
        } else {
          _periodNavLoading = false;
        }
      });
      _notifyToolbarChanged();
      if (!periodNav) _restartChartAnimation();
    } catch (_) {
      if (!mounted) return;
      if (seq != _loadSeq) return;
      if (periodNav) {
        setState(() => _periodNavLoading = false);
        _notifyToolbarChanged();
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load monthly data';
        });
      }
    }
  }

  Widget _buildSkeletonContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.85,
              children: List.generate(4, (_) => _skeletonMetricTile()),
            );
          },
        ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonBox(height: 14, width: 160, borderRadius: 4),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBox(width: 26, height: 26, borderRadius: 8),
                      SizedBox(width: 10),
                      SkeletonBox(width: 26, height: 26, borderRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: MediaQuery.sizeOf(context).height > 600 ? 24 : 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait = constraints.maxWidth < 600;
            final spacing = isPortrait ? 28.0 : 20.0;
            final h = (isPortrait ? 360.0 : 320.0) * (MediaQuery.sizeOf(context).height / 700).clamp(0.85, 1.15);
            final hBottom = (isPortrait ? 380.0 : 340.0) * (MediaQuery.sizeOf(context).height / 700).clamp(0.85, 1.15);
            final hProfit = hBottom * 1.28;
            if (isPortrait) {
              return Column(
                children: [
                  SizedBox(height: h, child: _skeletonChartCard()),
                  SizedBox(height: spacing),
                  SizedBox(height: hProfit, child: _skeletonChartCard()),
                  SizedBox(height: spacing),
                  SizedBox(height: hBottom, child: _skeletonChartCard()),
                  SizedBox(height: spacing),
                  SizedBox(height: hBottom, child: _skeletonChartCard()),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: h, child: _skeletonChartCard()),
                SizedBox(height: spacing),
                SizedBox(height: hProfit, child: _skeletonChartCard()),
                SizedBox(height: spacing),
                SizedBox(height: hBottom, child: _skeletonChartCard()),
              ],
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _skeletonMetricTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(height: 10, width: 80, borderRadius: 4),
          SizedBox(height: 8),
          SkeletonBox(height: 18, width: 60, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _skeletonChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 20, height: 20, borderRadius: 6),
              SizedBox(width: 8),
              SkeletonBox(width: 140, height: 16, borderRadius: 4),
            ],
          ),
          SizedBox(height: 16),
          Expanded(child: SkeletonBox(height: double.infinity, borderRadius: 8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return _buildSkeletonContent(context);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: primaryIndigo),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final r = _result;
    final fmtCurr = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    final totalSalesStr = fmtCurr.format(r.totalSales);
    final totalExpensesStr = fmtCurr.format(r.totalExpenses);
    final totalProfitStr = r.totalProfit >= 0
        ? '+${fmtCurr.format(r.totalProfit)}'
        : '-${fmtCurr.format(r.totalProfit.abs())}';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onToolbarChanged == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: buildMonthlyPeriodToolbar(
                  rangeText: periodRangeLabel,
                  canGoPrevious: canNavigatePrevious,
                  canGoNext: canNavigateNext,
                  onPrevious: navigatePrevious,
                  onNext: navigateNext,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;
              final count = contentWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: count,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.85,
                children: [
                  _metricTile(l10n.sales, totalSalesStr),
                  _metricTile(l10n.expenses, totalExpensesStr),
                  _metricTile(l10n.profit, totalProfitStr, isGreen: r.totalProfit >= 0),
                  _metricTile(l10n.summaryTotalOrders, '${r.totalOrders}'),
                ],
              );
            },
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height > 600 ? 24 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final media = MediaQuery.sizeOf(context);
              final contentWidth = constraints.maxWidth;
              final isPortrait = contentWidth < 600;
              final spacing = isPortrait ? 28.0 : 20.0;
              final heightScale = (media.height / 700).clamp(0.85, 1.15);
              final topRowHeight = (isPortrait ? 360.0 : 320.0) * heightScale;
              final bottomRowHeight = (isPortrait ? 380.0 : 340.0) * heightScale;
              // Taller card so Monthly Profit horizontal bars + rows have more vertical room.
              final profitChartHeight = bottomRowHeight * 1.28;
              if (isPortrait) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: topRowHeight, child: _wrapChartTap(context, l10n.monthlySales, _gamesChartCard)),
                    SizedBox(height: spacing),
                    SizedBox(height: profitChartHeight, child: _wrapChartTap(context, l10n.monthlyRevenue, _commissionChartCard)),
                    SizedBox(height: spacing),
                    SizedBox(height: bottomRowHeight, child: _wrapChartTap(context, l10n.junketExpenses, _expensesChartCard)),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: topRowHeight,
                    child: _wrapChartTap(context, l10n.monthlySales, _gamesChartCard),
                  ),
                  SizedBox(height: spacing),
                  SizedBox(
                    height: profitChartHeight,
                    child: _wrapChartTap(context, l10n.monthlyRevenue, _commissionChartCard),
                  ),
                  SizedBox(height: spacing),
                  SizedBox(
                    height: bottomRowHeight,
                    child: _wrapChartTap(context, l10n.junketExpenses, _expensesChartCard),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty) ...[
            Text(label.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0)),
            const SizedBox(height: 4),
          ],
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isGreen ? emeraldAccent : Colors.white)),
        ],
      ),
    );
  }

  void _showExpandedChart(
    BuildContext context,
    String title,
    Widget Function(BuildContext, {bool isExpanded, VoidCallback? onClose}) buildChart,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (BuildContext fullContext) {
          return Scaffold(
            backgroundColor: surfaceColor,
            body: SafeArea(
              child: buildChart(
                fullContext,
                isExpanded: true,
                onClose: () => Navigator.of(fullContext).pop(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wrapChartTap(
    BuildContext context,
    String title,
    Widget Function(BuildContext, {bool isExpanded, VoidCallback? onClose}) buildChart,
  ) {
    return GestureDetector(
      onTap: () => _showExpandedChart(context, title, buildChart),
      child: buildChart(context),
    );
  }

  Widget _gamesChartCard(BuildContext context, {bool isExpanded = false, VoidCallback? onClose}) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final gapBetweenDays = isCompact ? 4.0 : 6.0;
    final minWidthPerDay = isCompact ? 20.0 : 24.0;
    final titleSize = isExpanded ? 18.0 : (isCompact ? 13.0 : (media.width < 400 ? 14.0 : 16.0));
    final padding = isCompact ? 12.0 : 16.0;

    final days = _result.days;
    final thisMonthMaxSales = days.isEmpty ? 0 : days.map((e) => e.buyIn).reduce((a, b) => a > b ? a : b);
    final lastMonthMaxSales = days.isEmpty ? 0 : days.map((e) => e.lastWeekSales).reduce((a, b) => a > b ? a : b);
    final maxSales = thisMonthMaxSales > lastMonthMaxSales ? thisMonthMaxSales : lastMonthMaxSales;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view, size: isCompact ? 16 : 20, color: accentPurple),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(child: Text(AppLocalizations.of(context).monthlySales, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.white))),
              if (isExpanded && onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  iconSize: isCompact ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey[400],
                )
              else
                Icon(Icons.open_in_full, size: isCompact ? 14 : 18, color: Colors.grey[500]),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(primaryIndigo),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).thisMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              _legendDot(Colors.grey.shade500),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).lastMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemCount = days.length;
                final totalGap = itemCount <= 1 ? 0.0 : gapBetweenDays * (itemCount - 1);
                final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
                final widthPerDay = itemCount == 0 ? minWidthPerDay : ((availableWidth - totalGap) / itemCount).clamp(minWidthPerDay, double.infinity);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < days.length; i++) ...[
                      if (i > 0) SizedBox(width: gapBetweenDays),
                      SizedBox(
                        width: widthPerDay,
                        child: _VerticalMonthlySalesBar(
                          date: days[i].date,
                          thisMonthSales: days[i].buyIn,
                          lastMonthSales: days[i].lastWeekSales,
                          maxSales: maxSales,
                          animate: _chartAnimate,
                          isExpanded: isExpanded,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _winLossTrendCard(BuildContext context, {bool isExpanded = false, VoidCallback? onClose}) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final titleSize = isExpanded ? 18.0 : (isCompact ? 12.0 : (media.width < 400 ? 13.0 : 14.0));
    final padding = isCompact ? 12.0 : 16.0;
    final labelFontSize = isExpanded ? 14.0 : (isCompact ? 8.0 : 10.0);
    final valueFontSize = isExpanded ? 18.0 : (isCompact ? 8.0 : 9.0);

    final days = _result.days;
    final maxPos = days.isEmpty ? 1.0 : days.map((e) => e.winLoss).where((v) => v > 0).fold<double>(0, (a, b) => b > a ? b.toDouble() : a);
    final maxNeg = days.isEmpty ? 1.0 : days.map((e) => e.winLoss).where((v) => v < 0).fold<double>(0, (a, b) => b.abs() > a ? b.abs().toDouble() : a);
    final scalePos = maxPos <= 0 ? 1.0 : maxPos * 1.1;
    final scaleNeg = maxNeg <= 0 ? 1.0 : maxNeg * 1.1;
    const centerLabelHeight = 40.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: isCompact ? 16 : 18, color: emeraldAccent),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(child: Text(AppLocalizations.of(context).monthlyNet, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.white))),
              if (isExpanded && onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  iconSize: isCompact ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey[400],
                )
              else
                Icon(Icons.open_in_full, size: isCompact ? 14 : 18, color: Colors.grey[500]),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Expanded(
            child: days.isEmpty
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final h = constraints.maxHeight;
                      final halfExtra = (h - centerLabelHeight) / 2;
                      const maxTopBottomHeight = 80.0;
                      final labelGap = 4.0;
                      final labelHeight = valueFontSize * 1.35;
                      final topBottomHeight = min(maxTopBottomHeight, halfExtra - labelGap);
                      final barMax = max(4.0, topBottomHeight - labelHeight - labelGap - 4);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (int i = 0; i < days.length; i++) ...[
                                if (i > 0) SizedBox(width: isCompact ? 4 : 6),
                                Expanded(
                                  child: SizedBox(
                                    height: topBottomHeight,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (days[i].winLoss > 0) ...[
                                          Text(
                                            _fmtWL(days[i].winLoss),
                                            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w600, color: emeraldAccent),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: labelGap),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 500),
                                            curve: Curves.easeOutCubic,
                                            height: _chartAnimate ? (days[i].winLoss / scalePos * barMax).clamp(4.0, barMax) : 0,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: emeraldAccent.withValues(alpha: 0.6),
                                              borderRadius: const BorderRadius.vertical(bottom: Radius.zero),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              for (int i = 0; i < days.length; i++) ...[
                                if (i > 0) SizedBox(width: isCompact ? 4 : 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: days[i].winLoss > 0
                                          ? emeraldAccent.withValues(alpha: 0.25)
                                          : (days[i].winLoss < 0 ? roseAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06)),
                                      borderRadius: const BorderRadius.vertical(top: Radius.zero, bottom: Radius.zero),
                                    ),
                                    child: Text(
                                      days[i].date,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: labelFontSize, color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < days.length; i++) ...[
                                if (i > 0) SizedBox(width: isCompact ? 4 : 6),
                                Expanded(
                                  child: SizedBox(
                                    height: topBottomHeight,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (days[i].winLoss < 0) ...[
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 500),
                                            curve: Curves.easeOutCubic,
                                            height: _chartAnimate ? (days[i].winLoss.abs() / scaleNeg * barMax).clamp(4.0, barMax) : 0,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: roseAccent.withValues(alpha: 0.6),
                                              borderRadius: const BorderRadius.vertical(top: Radius.zero),
                                            ),
                                          ),
                                          SizedBox(height: labelGap),
                                          Text(
                                            _fmtWL(days[i].winLoss),
                                            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w600, color: roseAccent),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else if (days[i].winLoss == 0)
                                          Text(_fmtWL(0), style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _commissionChartCard(BuildContext context, {bool isExpanded = false, VoidCallback? onClose}) {
    if (isExpanded) {
      return _MonthlyProfitFullscreenBody(
        branchId: widget.branchId,
        chartAnimate: _chartAnimate,
        onClose: onClose,
      );
    }
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final padding = isCompact ? 12.0 : 16.0;
    final titleSize = isCompact ? 12.0 : (media.width < 400 ? 13.0 : 14.0);
    final maxBarHeight = isCompact ? 16.0 : 20.0;

    final days = _result.days;
    final maxThisMonthProfitAbs = days.isEmpty
        ? 1.0
        : days.map((e) => e.winLoss.abs()).reduce((a, b) => a > b ? a : b).toDouble();
    final maxLastMonthProfitAbs = days.isEmpty
        ? 1.0
        : days.map((e) => e.lastWeekProfit.abs()).reduce((a, b) => a > b ? a : b).toDouble();
    final maxProfitAbs = maxThisMonthProfitAbs > maxLastMonthProfitAbs ? maxThisMonthProfitAbs : maxLastMonthProfitAbs;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, size: isCompact ? 16 : 18, color: amberAccent),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(child: Text(AppLocalizations.of(context).monthlyProfit, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.white))),
              Icon(Icons.open_in_full, size: isCompact ? 14 : 18, color: Colors.grey[500]),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(amberAccent),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).thisMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              _legendDot(Colors.grey.shade500),
              SizedBox(width: isCompact ? 4 : 6),
              Text(
                AppLocalizations.of(context).lastMonth,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rowGap = isCompact ? 8.0 : 10.0;
                final count = days.isEmpty ? 1 : days.length;
                final totalGaps = rowGap * (count - 1);
                // Keep minimum row small so total rows never exceed [constraints.maxHeight] (avoids outer Column overflow).
                final rowHeight = ((constraints.maxHeight - totalGaps) / count).clamp(4.0, 64.0);
                final innerBarGap = _HorizontalMonthlyProfitBar.kBetweenBarsGap;
                final barHeight = ((rowHeight - innerBarGap) / 2).clamp(3.0, maxBarHeight);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (int i = 0; i < days.length; i++) ...[
                      if (i > 0) SizedBox(height: rowGap),
                      SizedBox(
                        height: rowHeight,
                        child: _HorizontalMonthlyProfitBar(
                          date: days[i].date,
                          thisMonthProfit: days[i].winLoss,
                          lastMonthProfit: days[i].lastWeekProfit,
                          maxProfitAbs: maxProfitAbs,
                          barHeight: barHeight,
                          animate: _chartAnimate,
                          isExpanded: false,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => _profitLegendDot(color);

  static double _logExpense(int value) {
    return value <= 0 ? 0.0 : log(value.toDouble() + 1);
  }

  Widget _expensesChartCard(BuildContext context, {bool isExpanded = false, VoidCallback? onClose}) {
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 360;
    final padding = isCompact ? 12.0 : 16.0;
    final titleSize = isExpanded ? 18.0 : (isCompact ? 12.0 : (media.width < 400 ? 13.0 : 14.0));
    final labelFontSize = isExpanded ? 14.0 : (isCompact ? 8.0 : 10.0);
    final valueFontSize = isExpanded ? 18.0 : (isCompact ? 8.0 : 9.0);

    final days = _result.days;
    // Use log scale so small values (e.g. 3K) are visible vs 0 when max is huge (e.g. 3.03M)
    final maxLogY = days.isEmpty
        ? 1.0
        : days.map((e) => _logExpense(e.expenses)).reduce((a, b) => a > b ? a : b) * 1.15;
    final minLogY = 0.0;
    final spots = _chartAnimate
        ? days.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _logExpense(e.value.expenses))).toList()
        : List.generate(days.length, (i) => FlSpot(i.toDouble(), minLogY));
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: isCompact ? 16 : 18, color: roseAccent),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(child: Text(AppLocalizations.of(context).junketExpenses, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.white))),
              if (isExpanded && onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  iconSize: isCompact ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: Colors.grey[400],
                )
              else
                Icon(Icons.open_in_full, size: isCompact ? 14 : 18, color: Colors.grey[500]),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Expanded(
            child: ClipRect(
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (days.isEmpty ? 0 : days.length - 1).toDouble(),
                  minY: minLogY,
                  maxY: maxLogY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: roseAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: roseAccent.withValues(alpha: 0.1)),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Row(
            children: [
              for (int i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(days[i].date, style: TextStyle(fontSize: labelFontSize, color: Colors.grey[400])),
                      const SizedBox(height: 2),
                      Text(
                        _fmt(days[i].expenses),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w600, color: roseAccent),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
