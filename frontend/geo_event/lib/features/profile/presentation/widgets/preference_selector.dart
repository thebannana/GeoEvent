import 'package:flutter/material.dart';

class PreferenceSelectorItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  const PreferenceSelectorItem({
    required this.value,
    required this.label,
    this.subtitle,
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
    final divider = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A303A)
        : const Color(0xFFE3EAF3);

    return Column(
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
                title: Text(item.label),
                subtitle:
                    item.subtitle != null ? Text(item.subtitle!) : null,
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
    );
  }
}