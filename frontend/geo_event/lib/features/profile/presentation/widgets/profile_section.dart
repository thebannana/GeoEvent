import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...List.generate(children.length, (index) {
            return Column(
              children: [
                children[index],
                if (index != children.length - 1)
                  const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}