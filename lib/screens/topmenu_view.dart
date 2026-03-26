import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../models/types.dart';
import '../services/top_menu_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_box.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

/// Top-selling menu items (PyServer `/api/analytics/top-selling`), same idea as restoAdmin [MenuReport] top block.
class TopMenuView extends StatefulWidget {
  const TopMenuView({
    super.key,
    this.branchId = '0',
    this.startDate,
    this.endDate,
    this.compactCards = false,
  });

  /// Branch id for analytics; `0` = all branches.
  final String branchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool compactCards;

  @override
  State<TopMenuView> createState() => _TopMenuViewState();
}

class _TopMenuViewState extends State<TopMenuView> {
  bool _loading = true;
  List<MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TopMenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStartMs = oldWidget.startDate?.millisecondsSinceEpoch;
    final newStartMs = widget.startDate?.millisecondsSinceEpoch;
    final oldEndMs = oldWidget.endDate?.millisecondsSinceEpoch;
    final newEndMs = widget.endDate?.millisecondsSinceEpoch;
    if (oldWidget.branchId != widget.branchId || oldStartMs != newStartMs || oldEndMs != newEndMs) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await TopMenuService.instance.fetchTopMenu(
      branchId: widget.branchId,
      start: widget.startDate,
      end: widget.endDate,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading && _menuItems.isEmpty) {
      return _buildSkeletonContent(context);
    }
    if (_menuItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopMenu(context, l10n, 0),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No top-selling items for this period.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    final gridParams = _gridParamsForWidth(width, isLandscape, widget.compactCards);
    final horizontalPadding = _horizontalPaddingForWidth(width);
    final bottomInset = width < 1024 ? 80.0 + mq.padding.bottom : 24.0;
    final scrollContent = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 16, left: horizontalPadding, right: horizontalPadding),
            child: _buildTopMenu(context, l10n, _menuItems.length),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: 16, left: horizontalPadding, right: horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: gridParams.maxCrossAxisExtent,
              mainAxisSpacing: gridParams.spacing,
              crossAxisSpacing: gridParams.spacing,
              mainAxisExtent: gridParams.mainAxisExtent,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final maxSales = _menuItems.isEmpty ? 1 : _menuItems.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b);
                return _MenuDataCard(
                  rank: i + 1,
                  item: _menuItems[i],
                  maxTotalSales: maxSales.toDouble(),
                  l10n: l10n,
                );
              },
              childCount: _menuItems.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) return scrollContent;
        final fullHeight = MediaQuery.sizeOf(context).height;
        const kHeaderHeight = 80.0;
        const kBottomNavHeight = 80.0;
        final viewportHeight = width < 1024
            ? (fullHeight - kHeaderHeight - kBottomNavHeight - mq.padding.top - mq.padding.bottom)
            : fullHeight;
        return SizedBox(
          height: viewportHeight.clamp(200.0, fullHeight),
          child: scrollContent,
        );
      },
    );
  }

  Widget _buildTopMenu(BuildContext context, AppLocalizations l10n, int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeader = constraints.maxWidth < 560;
        if (compactHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: primaryIndigo, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.menuTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.menuTotalItems} ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Icon(Icons.restaurant_menu, color: primaryIndigo, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.menuTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${l10n.menuTotalItems} ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[400]),
            ),
            Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonContent(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    final gridParams = _gridParamsForWidth(width, isLandscape, widget.compactCards);
    final horizontalPadding = _horizontalPaddingForWidth(width);
    final skeletonScroll = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 28, height: 28, borderRadius: 6),
                    const SizedBox(width: 10),
                    SkeletonBox(width: 140, height: 24, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: gridParams.maxCrossAxisExtent,
              mainAxisSpacing: gridParams.spacing,
              crossAxisSpacing: gridParams.spacing,
              mainAxisExtent: gridParams.mainAxisExtent,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 28, height: 28, borderRadius: 8),
                        const SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 16, borderRadius: 4)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _skeletonRow(),
                    const SizedBox(height: 6),
                    _skeletonRow(),
                    const SizedBox(height: 6),
                    _skeletonRow(),
                  ],
                ),
              ),
              childCount: 10,
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) return skeletonScroll;
        return SizedBox(height: MediaQuery.sizeOf(context).height, child: skeletonScroll);
      },
    );
  }

  Widget _skeletonRow() {
    return Row(
      children: [
        SkeletonBox(width: 50, height: 10, borderRadius: 4),
        const Spacer(),
        SkeletonBox(width: 60, height: 14, borderRadius: 4),
      ],
    );
  }
}

class _GridParams {
  const _GridParams({
    required this.maxCrossAxisExtent,
    required this.mainAxisExtent,
    required this.spacing,
  });
  final double maxCrossAxisExtent;
  final double mainAxisExtent;
  final double spacing;
}

const double _kMenuCardContentHeightPortrait = 220.0;
const double _kMenuCardContentHeightLandscape = 204.0;
const double _kMenuCardContentHeightPortraitCompact = 220.0;
const double _kMenuCardContentHeightLandscapeCompact = 192.0;

_GridParams _gridParamsForWidth(double width, bool isLandscape, bool compactCards) {
  final spacing = width < 500 ? 10.0 : (width >= 1000 ? 14.0 : 12.0);
  final maxCrossAxisExtent = width < 600 ? 280.0 : (width < 1000 ? 320.0 : 340.0);
  final baseHeight = compactCards
      ? (isLandscape ? _kMenuCardContentHeightLandscapeCompact : _kMenuCardContentHeightPortraitCompact)
      : (isLandscape ? _kMenuCardContentHeightLandscape : _kMenuCardContentHeightPortrait);
  final extraHeight = isLandscape
      ? (width < 700 ? 28.0 : 22.0)
      : (width < 420 ? 54.0 : (width < 700 ? 40.0 : 22.0));
  final mainAxisExtent = baseHeight + extraHeight;
  return _GridParams(maxCrossAxisExtent: maxCrossAxisExtent, mainAxisExtent: mainAxisExtent, spacing: spacing);
}

double _horizontalPaddingForWidth(double width) {
  if (width < 600) return 0;
  if (width < 900) return 20;
  return 24;
}

class _MenuDataCard extends StatelessWidget {
  const _MenuDataCard({
    required this.rank,
    required this.item,
    required this.maxTotalSales,
    required this.l10n,
  });

  final int rank;
  final MenuItem item;
  final double maxTotalSales;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final salesRatio = maxTotalSales <= 0 ? 0.0 : (item.totalSales / maxTotalSales).clamp(0.0, 1.0);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowCard = constraints.maxWidth < 250;
        final compactVertical = isNarrowCard || isLandscape;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            color: cardBg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryIndigo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryIndigo.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: isNarrowCard ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: compactVertical ? 12 : 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryIndigo.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.trending_up_rounded, color: primaryIndigo.withValues(alpha: 0.9), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.menuTotalSales,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _currencyFmt.format(item.totalSales),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compactVertical ? 4 : 8),
            Row(
              children: [
                Expanded(
                  child: _statPill(
                    icon: Icons.payments_rounded,
                    label: l10n.menuPrice,
                    value: _currencyFmt.format(item.price),
                    compact: isNarrowCard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statPill(
                    icon: Icons.receipt_long_rounded,
                    label: l10n.menuTotalOrders,
                    value: '${item.totalOrders}',
                    compact: isNarrowCard,
                  ),
                ),
              ],
            ),
            SizedBox(height: compactVertical ? 2 : 6),
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: salesRatio,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryIndigo.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(salesRatio * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
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

  Widget _statPill({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 14 : 16, color: primaryIndigo.withValues(alpha: 0.8)),
          SizedBox(width: compact ? 4 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: compact ? 8 : 9, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
