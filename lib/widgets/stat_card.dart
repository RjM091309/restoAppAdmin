import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatCardColor { primary, purple, emerald, rose, amber, teal, brown }

class StatCard extends StatelessWidget {
  /// Optional line above the main row (e.g. branch name on realtime branch tiles).
  final String? topLabel;
  final String label;
  final String value;
  /// If set, this widget is shown instead of [value] text (e.g. for animated counter).
  final Widget? valueWidget;
  final String? subValue;
  /// Replaces [subValue] when set (e.g. aligned profit / expenses row).
  final Widget? footer;
  final IconData icon;
  final StatCardColor color;
  final String? trendValue;
  final bool? trendIsUp;
  /// Shown on the right side of the card (e.g. chevron) to fill empty space.
  final Widget? trailing;
  /// Puts [value] on the same row as [label], directly beside it (not end-aligned).
  final bool valueInlineWithLabel;

  const StatCard({
    super.key,
    this.topLabel,
    required this.label,
    required this.value,
    this.valueWidget,
    this.subValue,
    this.footer,
    required this.icon,
    this.color = StatCardColor.primary,
    this.trendValue,
    this.trendIsUp,
    this.trailing,
    this.valueInlineWithLabel = false,
  });

  Color get _colorValue {
    switch (color) {
      case StatCardColor.primary: return primaryIndigo;
      case StatCardColor.purple: return accentPurple;
      case StatCardColor.emerald: return emeraldAccent;
      case StatCardColor.rose: return roseAccent;
      case StatCardColor.amber: return amberAccent;
      case StatCardColor.teal: return tealAccent;
      case StatCardColor.brown: return brownAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 90 || constraints.maxWidth < 132;
        // Tablet/mid size: mas malaki padding para hindi mukhang lubog ang text
        final isTabletSize = constraints.maxWidth >= 160 && constraints.maxWidth <= 320;
        // Branch tiles with footer need extra breathing room on narrow widths.
        final padding = isCompact ? 10.0 : (isTabletSize ? 16.0 : 14.0);
        final spacing = isCompact ? 5.0 : 8.0;
        final valueFontSize = isCompact ? 14.0 : 18.0;
        final labelFontSize = isCompact ? 13.0 : 17.0;
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _colorValue.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _colorValue.withValues(alpha: 0.2),
                _colorValue.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (topLabel != null && topLabel!.isNotEmpty) ...[
                      Text(
                        topLabel!,
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompact ? 4 : 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: isCompact ? 14 : 16, color: _colorValue),
                        ),
                        SizedBox(width: isCompact ? 6 : 10),
                        if (valueInlineWithLabel)
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: valueWidget != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          label.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: labelFontSize,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: footer != null && isCompact ? 0.4 : 1.0,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        SizedBox(width: isCompact ? 6 : 8),
                                        valueWidget!,
                                      ],
                                    )
                                  : Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: label.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: labelFontSize,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: footer != null && isCompact ? 0.4 : 1.0,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          TextSpan(
                                            text: isCompact ? '  ' : '   ',
                                          ),
                                          TextSpan(
                                            text: value,
                                            style: TextStyle(
                                              fontSize: valueFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                            ),
                          )
                        else ...[
                          Expanded(
                            child: Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: footer != null && isCompact ? 0.4 : 1.0,
                                color: Colors.grey[400],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (trendValue != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: (trendIsUp ?? true) ? emeraldAccent.withValues(alpha: 0.2) : roseAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(trendIsUp ?? true) ? '+' : '-'}$trendValue',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: (trendIsUp ?? true) ? emeraldAccent : roseAccent,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ],
                    ),
                    if (!valueInlineWithLabel) ...[
                      SizedBox(height: spacing),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 34, right: 8),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              child: valueWidget ??
                                  Text(
                                    value,
                                    maxLines: 1,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (footer != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: valueInlineWithLabel ? spacing : (isCompact ? 6 : 8),
                        ),
                        child: footer!,
                      )
                    else if (subValue != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subValue!,
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        );
      },
    );
  }
}
