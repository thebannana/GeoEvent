import 'package:flutter/material.dart';

class GlassScaffold extends StatelessWidget {
  final Widget child;

  const GlassScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0B0D12),
                  Color(0xFF10141B),
                  Color(0xFF0D1016),
                ]
              : const [
                  Color(0xFFF6F8FB),
                  Color(0xFFF1F4F8),
                  Color(0xFFEEF2F7),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.015),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.015),
                        ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}