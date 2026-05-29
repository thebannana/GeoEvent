import 'package:flutter/material.dart';

class ShellSheetContent extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;
  final Widget body;
  final bool isDark;
  final bool isFullScreen;

  const ShellSheetContent({
    super.key,
    required this.title,
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.body,
    required this.isDark,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = isFullScreen
        ? BorderRadius.zero
        : const BorderRadius.vertical(
            top: Radius.circular(30),
            bottom: Radius.circular(30),
          );

    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.fromLTRB(
        isFullScreen ? 0 : 10,
        0,
        isFullScreen ? 0 : 10,
        isFullScreen ? 0 : 118,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
          borderRadius: borderRadius,
          border: Border.all(
            color: isFullScreen
                ? Colors.transparent
                : isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
            width: 1,
          ),
          boxShadow: isFullScreen
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.22 : 0.08,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: onDragUpdate,
              onVerticalDragEnd: onDragEnd,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (!isFullScreen) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        isFullScreen ? 10 : 16,
                        10,
                        10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}