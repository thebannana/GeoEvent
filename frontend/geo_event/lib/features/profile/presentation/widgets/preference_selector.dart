import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PreferenceSelectorItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool enabled;
  final String? disabledReason;

  const PreferenceSelectorItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.enabled = true,
    this.disabledReason,
  });
}

class PreferenceSelector<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T? groupValue;
  final List<PreferenceSelectorItem<T>> items;
  final ValueChanged<T> onSelected;

  const PreferenceSelector({
    super.key,
    required this.title,
    this.subtitle,
    required this.groupValue,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    final theme = Theme.of(context);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final selected = item.value == groupValue;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<T>(
                  value: item.value,
                  groupValue: groupValue,
                  contentPadding: EdgeInsets.zero,
                  secondary: item.icon != null
                      ? Icon(
                          item.icon,
                          color: item.enabled
                              ? null
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.45),
                        )
                      : null,
                  title: Text(
                    item.label,
                    style: item.enabled
                        ? null
                        : TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.55),
                          ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: item.enabled
                              ? null
                              : TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.55),
                                ),
                        )
                      : null,
                  selected: selected,
                  onChanged: item.enabled
                      ? (value) {
                          if (value != null) onSelected(value);
                        }
                      : null,
                ),
                if (!item.enabled && item.disabledReason != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 56, right: 8, bottom: 8),
                    child: Text(
                      item.disabledReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (index != items.length - 1)
                  Divider(height: 1, color: divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}