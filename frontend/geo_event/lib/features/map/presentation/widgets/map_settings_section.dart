import 'package:flutter/material.dart';

import 'map_settings_toggle_card.dart';

class MapSettingsSectionItem {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const MapSettingsSectionItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

class MapSettingsSection extends StatelessWidget {
  final String title;
  final List<MapSettingsSectionItem> items;

  const MapSettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          MapSettingsToggleCard(
            label: item.label,
            subtitle: item.subtitle,
            value: item.value,
            onChanged: item.onChanged,
          ),
      ],
    );
  }
}