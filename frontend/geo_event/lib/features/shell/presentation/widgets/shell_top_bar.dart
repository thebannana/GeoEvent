import 'package:flutter/material.dart';

class ShellTopBar extends StatelessWidget {
  final bool showAll;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  const ShellTopBar({
    super.key,
    required this.showAll,
    required this.onMenu,
    required this.onSearch,
    required this.onFilter,
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
              _CircleActionButton(
                icon: Icons.menu_rounded,
                onPressed: onMenu,
              )
            else
              const SizedBox(width: 46),
            if (showAll)
              Row(
                children: [
                  _CircleActionButton(
                    icon: Icons.search_rounded,
                    onPressed: onSearch,
                  ),
                  const SizedBox(width: 10),
                  _CircleActionButton(
                    icon: Icons.tune_rounded,
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

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF171B22) : const Color(0xFFFDFEFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 46,
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
          child: Icon(
            icon,
            size: 22,
            color: isDark ? Colors.white : const Color(0xFF10131A),
          ),
        ),
      ),
    );
  }
}