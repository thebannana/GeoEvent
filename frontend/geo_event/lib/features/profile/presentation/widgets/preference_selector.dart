import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';

class PreferenceSelectorItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const PreferenceSelectorItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final selected = item.value == groupValue;

            return Column(
              children: [
                RadioListTile<T>(
                  value: item.value,
                  groupValue: groupValue,
                  contentPadding: EdgeInsets.zero,
                  secondary: item.icon != null ? Icon(item.icon) : null,
                  title: Text(item.label),
                  subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                  selected: selected,
                  onChanged: (value) {
                    if (value != null) onSelected(value);
                  },
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