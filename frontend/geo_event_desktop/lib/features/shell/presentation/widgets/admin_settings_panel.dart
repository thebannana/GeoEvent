import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/theme_mode_controller.dart';

class AdminSettingsPanel extends ConsumerWidget {
  const AdminSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final controller = ref.read(themeModeControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = themeMode == ThemeMode.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x16000000)
                      : const Color(0x12000000),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AppearanceSection(
                        themeMode: themeMode,
                        controller: controller,
                      ),
                      const SizedBox(height: 24),
                      _ThemeOverviewCard(
                        themeMode: themeMode,
                        isDark: isDark,
                        textTheme: textTheme,
                        colors: colors,
                        colorScheme: colorScheme,
                        controller: controller,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _AppearanceSection(
                          themeMode: themeMode,
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _ThemeOverviewCard(
                          themeMode: themeMode,
                          isDark: isDark,
                          textTheme: textTheme,
                          colors: colors,
                          colorScheme: colorScheme,
                          controller: controller,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({
    required this.themeMode,
    required this.controller,
  });

  final ThemeMode themeMode;
  final ThemeModeController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Appearance'),
        const SizedBox(height: 8),
        Text(
          'Choose how the desktop application looks. Your preference is saved locally on this device and applied immediately across the admin interface.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.5,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _ThemeOptionTile(
          title: 'Light mode',
          subtitle: 'Bright interface with white surfaces and clear contrast.',
          icon: Icons.light_mode_rounded,
          selected: themeMode == ThemeMode.light,
          onTap: () => controller.setThemeMode(ThemeMode.light),
        ),
        const SizedBox(height: 12),
        _ThemeOptionTile(
          title: 'Dark mode',
          subtitle: 'Dimmed interface for low-light environments and extended use.',
          icon: Icons.dark_mode_rounded,
          selected: themeMode == ThemeMode.dark,
          onTap: () => controller.setThemeMode(ThemeMode.dark),
        ),
        const SizedBox(height: 12),
        _ThemeOptionTile(
          title: 'System mode',
          subtitle: 'Follow the operating system preference automatically.',
          icon: Icons.computer_rounded,
          selected: themeMode == ThemeMode.system,
          onTap: () => controller.setThemeMode(ThemeMode.system),
        ),
      ],
    );
  }
}

class _ThemeOverviewCard extends StatelessWidget {
  const _ThemeOverviewCard({
    required this.themeMode,
    required this.isDark,
    required this.textTheme,
    required this.colors,
    required this.colorScheme,
    required this.controller,
  });

  final ThemeMode themeMode;
  final bool isDark;
  final TextTheme textTheme;
  final AppThemeColors colors;
  final ColorScheme colorScheme;
  final ThemeModeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Theme overview'),
          const SizedBox(height: 8),
          Text(
            'A quick summary of the currently selected visual mode.',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : themeMode == ThemeMode.system
                                ? Icons.computer_rounded
                                : Icons.light_mode_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.labelFor(themeMode),
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            themeMode == ThemeMode.system
                                ? 'Using operating system preference.'
                                : isDark
                                    ? 'Dark styling is currently active.'
                                    : 'Light styling is currently active.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewSwatch(
                        label: 'Surface',
                        color: isDark
                            ? const Color(0xFF18222C)
                            : const Color(0xFFF7F9FC),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewSwatch(
                        label: 'Card',
                        color: isDark
                            ? const Color(0xFF223240)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewSwatch(
                        label: 'Accent',
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoRow(
            label: 'Current mode',
            value: controller.labelFor(themeMode),
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            label: 'Default mode',
            value: 'Light',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            label: 'Persistence',
            value: 'Saved on this device',
          ),
        ],
      ),
    );
  }
}

class _PreviewSwatch extends StatelessWidget {
  const _PreviewSwatch({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.35)
                : colors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.16)
                    : colors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13.5,
                      height: 1.4,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? colorScheme.primary
                  : colors.textSecondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      text,
      style: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}