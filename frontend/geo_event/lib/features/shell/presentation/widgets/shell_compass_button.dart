import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShellCompassButton extends StatelessWidget {
  final double bearing;
  final VoidCallback onTap;

  const ShellCompassButton({
    super.key,
    required this.bearing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF171B22) : const Color(0xFFFDFEFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE3EAF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: -bearing * (math.pi / 180),
              child: Icon(
                Icons.explore_outlined,
                size: 22,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}