import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/inputs/app_icon_circle_button.dart';

class ShellCompassButton extends StatelessWidget {
  static const String _tooltip = 'Recenter map';

  final double bearing;
  final VoidCallback onTap;

  const ShellCompassButton({
    super.key,
    required this.bearing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppIconCircleButton(
      onPressed: onTap,
      tooltip: _tooltip,
      child: Transform.rotate(
        angle: -bearing * (math.pi / 180),
        child: Icon(
          Icons.explore_outlined,
          size: 22,
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}