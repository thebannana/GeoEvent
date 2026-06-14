import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import 'preference_selector.dart';

class ThemeModeTileGroup extends ConsumerWidget {
  const ThemeModeTileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return PreferenceSelector<ThemeMode>(
      title: 'Appearance',
      subtitle: 'Choose how the app should look.',
      groupValue: themeMode,
      onSelected: (value) {
        ref.read(themeModeControllerProvider.notifier).setThemeMode(value);
      },
      items: const [
        PreferenceSelectorItem(
          value: ThemeMode.system,
          label: 'System',
          subtitle: 'Follow your device appearance.',
          icon: Icons.brightness_auto_rounded,
        ),
        PreferenceSelectorItem(
          value: ThemeMode.light,
          label: 'Light',
          subtitle: 'Always use the light theme.',
          icon: Icons.light_mode_rounded,
        ),
        PreferenceSelectorItem(
          value: ThemeMode.dark,
          label: 'Dark',
          subtitle: 'Always use the dark theme.',
          icon: Icons.dark_mode_rounded,
        ),
      ],
    );
  }
}