import 'package:flutter/material.dart';

import '../../theme/app_theme_colors.dart';
import '../../theme/app_theme_metrics.dart';

class AppBottomSheetContainer extends StatelessWidget {
  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.all(AppThemeMetrics.spaceLg),
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 96),
    this.maxHeightFactor = 0.82,
    this.showHandle = true,
    this.scrollable = true,
  });

  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double maxHeightFactor;
  final bool showHandle;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final scheme = theme.colorScheme;

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: margin.resolve(Directionality.of(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
          ),
          child: Material(
            color: colors.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeMetrics.radiusXl + 2),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
                ?header,
                Flexible(child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}