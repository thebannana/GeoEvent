import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_circle_button.dart';

class ShellTopBar extends StatelessWidget {
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
                tooltip: 'Menu',
                onPressed: onMenu,
              )
            else
              const SizedBox(width: 46),
            if (showAll)
              Row(
                children: [
                  if (showDirectionsButton) ...[
                    AppIconCircleButton(
                      icon: Icons.navigation_rounded,
                      tooltip: 'Directions',
                      onPressed: onDirections,
                    ),
                    const SizedBox(width: 10),
                  ],
                  AppIconCircleButton(
                    icon: Icons.search_rounded,
                    tooltip: 'Search',
                    onPressed: onSearch,
                  ),
                  const SizedBox(width: 10),
                  AppIconCircleButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Filter',
                    onPressed: onFilter,
                  ),
                ],
              )
            else
              const SizedBox(width: 102),
          ],
        ),
      ),
    );
  }
}