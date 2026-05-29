import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_controller.dart';

class ThemeModeTileGroup extends ConsumerWidget {
  const ThemeModeTileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final divider = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A303A)
        : const Color(0xFFE3EAF3);

    void updateTheme(ThemeMode? value) {
      if (value == null) return;
      ref.read(themeModeControllerProvider.notifier).setThemeMode(value);
    }

    return Column(
      children: [
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          groupValue: themeMode,
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.brightness_auto_rounded),
          title: const Text('System'),
          subtitle: const Text('Follow your device appearance.'),
          onChanged: updateTheme,
        ),
        Divider(height: 1, color: divider),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          groupValue: themeMode,
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.light_mode_rounded),
          title: const Text('Light'),
          subtitle: const Text('Always use the light theme.'),
          onChanged: updateTheme,
        ),
        Divider(height: 1, color: divider),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          groupValue: themeMode,
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.dark_mode_rounded),
          title: const Text('Dark'),
          subtitle: const Text('Always use the dark theme.'),
          onChanged: updateTheme,
        ),
      ],
    );
  }
}