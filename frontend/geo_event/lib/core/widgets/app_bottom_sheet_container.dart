import 'dart:ui';

import 'package:flutter/material.dart';

class AppBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double maxHeightFactor;
  final bool showHandle;

  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 96),
    this.maxHeightFactor = 0.82,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: margin.resolve(Directionality.of(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.52),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                  ?header,
                  Flexible(
                    child: Padding(
                      padding: padding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}