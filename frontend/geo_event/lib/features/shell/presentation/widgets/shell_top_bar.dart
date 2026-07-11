import 'package:flutter/material.dart';

import '../../../../core/widgets/inputs/app_icon_circle_button.dart';

class ShellTopBar extends StatelessWidget {
  static const String _menuTooltip = 'Menu';
  static const String _directionsTooltip = 'Directions';
  static const String _searchTooltip = 'Search';
  static const String _filterTooltip = 'Filter';

  final bool showAll;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback? onDirections;
  final bool showDirectionsButton;

  const ShellTopBar({
    super.key,
    required this.showAll,
    required this.onMenu,
    required this.onSearch,
    required this.onFilter,
    required this.onDirections,
    required this.showDirectionsButton,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildActions() {
      return Row(
        children: [
          if (showDirectionsButton) ...[
            AppIconCircleButton(
              icon: Icons.navigation_rounded,
              tooltip: _directionsTooltip,
              onPressed: onDirections,
            ),
            const SizedBox(width: 10),
          ],
          AppIconCircleButton(
            icon: Icons.search_rounded,
            tooltip: _searchTooltip,
            onPressed: onSearch,
          ),
          const SizedBox(width: 10),
          AppIconCircleButton(
            icon: Icons.tune_rounded,
            tooltip: _filterTooltip,
            onPressed: onFilter,
          ),
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showAll)
              AppIconCircleButton(
                icon: Icons.menu_rounded,
                tooltip: _menuTooltip,
                onPressed: onMenu,
              )
            else
              const SizedBox(width: 46),
            if (showAll) buildActions() else const SizedBox(width: 102),
          ],
        ),
      ),
    );
  }
}