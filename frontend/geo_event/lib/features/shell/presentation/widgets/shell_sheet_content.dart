import 'package:flutter/material.dart';

class ShellSheetContent extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;
  final Widget body;
  final bool isFullScreen;

  const ShellSheetContent({
    super.key,
    required this.title,
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.body,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: isFullScreen
                ? Colors.transparent
                : colorScheme.outline.withValues(alpha: 0.75),
          ),
          boxShadow: isFullScreen
              ? const []
              : [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: onDragUpdate,
                onVerticalDragEnd: onDragEnd,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isFullScreen) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.16,
                              ),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}