import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/mock_data.dart';
import '../generated/app_localizations.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_box.dart';

final _fmt = NumberFormat.compact(locale: 'en_PH');

String _formatPeso(int value) {
  final abs = value.abs();
  final s = _fmt.format(abs);
  return value < 0 ? '-P$s' : 'P$s';
}

class RankingView extends StatefulWidget {
  const RankingView({super.key});

  @override
  State<RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<RankingView> {
  List<ExpenseCategoryItem> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _loading = true);
    setState(() {
      _expenses = List.from(mockExpenseCategories);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget content;
    if (_loading && _expenses.isEmpty) {
      content = _buildSkeleton(context, l10n);
    } else if (_expenses.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l10n),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text('No expense data', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l10n),
          const SizedBox(height: 16),
          _buildColumnHeaders(l10n),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _expenses.length,
              itemBuilder: (context, i) => _buildExpenseRow(context, _expenses[i]),
            ),
          ),
        ],
      );
    }
    // When used inside TabBarView (e.g. BranchDetailView landscape), constraints can be unbounded; give finite height.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) return content;
        return SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: content,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 500;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isNarrow ? 8 : 12),
          decoration: BoxDecoration(
            color: roseAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: roseAccent.withValues(alpha: 0.2), blurRadius: 12)],
          ),
          child: Icon(Icons.receipt_long, color: roseAccent, size: isNarrow ? 24 : 28),
        ),
        SizedBox(width: isNarrow ? 10 : 12),
        Expanded(
          child: Text(
            l10n.expensesTitle,
            style: TextStyle(
              fontSize: isNarrow ? 16 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeaders(AppLocalizations l10n) {
    final isNarrow = MediaQuery.sizeOf(context).width < 500;
    final labelSize = isNarrow ? 10.0 : 12.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(width: isNarrow ? 44 : 52),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox.shrink(),
          ),
          SizedBox(
            width: isNarrow ? 72 : 88,
            child: Text(
              l10n.expenseCurrentMonth,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: isNarrow ? 8 : 12),
          SizedBox(
            width: isNarrow ? 64 : 80,
            child: Text(
              l10n.expensePreviousMonth,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: isNarrow ? 8 : 12),
          SizedBox(
            width: isNarrow ? 56 : 72,
            child: Text(
              l10n.expenseChange,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(BuildContext context, ExpenseCategoryItem item) {
    final isNarrow = MediaQuery.sizeOf(context).width < 500;
    final iconSize = isNarrow ? 40.0 : 48.0;
    final currentColor = item.currentMonth >= 0 ? emeraldAccent : roseAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: isNarrow ? 10 : 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (item.rank == 1) Icon(Icons.emoji_events, size: iconSize - 12, color: Colors.amber),
                  if (item.rank == 2) Icon(Icons.emoji_events, size: iconSize - 12, color: Colors.grey[400]),
                  if (item.rank == 3) Icon(Icons.emoji_events, size: iconSize - 12, color: Colors.amber[800]),
                  if (item.rank > 3)
                    Icon(Icons.military_tech, size: iconSize - 12, color: primaryIndigo.withValues(alpha: 0.7)),
                  if (item.rank > 3)
                    Positioned(
                      bottom: 4,
                      child: Text(
                        '${item.rank}',
                        style: TextStyle(
                          fontSize: isNarrow ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isNarrow ? 10 : 14),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: isNarrow ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryId,
                    style: TextStyle(
                      fontSize: isNarrow ? 10 : 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: isNarrow ? 72 : 88,
              child: Text(
                _formatPeso(item.currentMonth),
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: currentColor,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            SizedBox(
              width: isNarrow ? 64 : 80,
              child: Text(
                _formatPeso(item.previousMonth),
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            SizedBox(
              width: isNarrow ? 56 : 72,
              child: Text(
                _formatPeso(item.change),
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, l10n),
        const SizedBox(height: 24),
        ...List.generate(5, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 48, height: 48, borderRadius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 16, width: 140, borderRadius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(height: 12, width: 60, borderRadius: 4),
                      ],
                    ),
                  ),
                  SkeletonBox(height: 16, width: 70, borderRadius: 4),
                  SizedBox(width: 12),
                  SkeletonBox(height: 16, width: 70, borderRadius: 4),
                  SizedBox(width: 12),
                  SkeletonBox(height: 16, width: 60, borderRadius: 4),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
