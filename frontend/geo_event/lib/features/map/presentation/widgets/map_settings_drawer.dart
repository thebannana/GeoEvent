import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/map_settings_controller.dart';

class MapSettingsDrawer extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const MapSettingsDrawer({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<MapSettingsDrawer> createState() => _MapSettingsDrawerState();
}

class _MapSettingsDrawerState extends ConsumerState<MapSettingsDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(mapSettingsControllerProvider);
    final controller = ref.read(mapSettingsControllerProvider.notifier);
    final width = MediaQuery.of(context).size.width * 0.78;

    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: width.clamp(280.0, 360.0),
                  constraints: const BoxConstraints(
                    minHeight: 420,
                    maxHeight: 620,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161A21)
                        : const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A303A)
                          : const Color(0xFFE3EAF3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'geoEvent',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Map settings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF2A303A)
                            : const Color(0xFFE3EAF3),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DrawerSection(
                                title: 'Scene',
                                children: [
                                  _ToggleCard(
                                    label: '3D buildings & scene',
                                    subtitle:
                                        'Uses the map scene itself, not only camera tilt.',
                                    value: settings.map3D,
                                    onChanged: controller.setMap3D,
                                  ),
                                  _ToggleCard(
                                    label: 'Terrain elevation',
                                    subtitle:
                                        'Shows hills and elevation relief when supported.',
                                    value: settings.terrain,
                                    onChanged: controller.setTerrain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _DrawerSection(
                                title: 'Lighting',
                                children: [
                                  _ToggleCard(
                                    label: 'Auto day/night cycle',
                                    subtitle:
                                        'Keeps the same map style and updates lighting by time.',
                                    value: settings.dayNightCycle,
                                    onChanged: controller.setDayNightCycle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _DrawerSection(
                                title: 'Labels & pins',
                                children: [
                                  _ToggleCard(
                                    label: 'Map POIs',
                                    subtitle:
                                        'Show or hide built-in Mapbox places like parks and shops.',
                                    value: settings.mapPins,
                                    onChanged: controller.setMapPins,
                                  ),
                                  _ToggleCard(
                                    label: 'Event pins',
                                    subtitle:
                                        'Show or hide your custom geoEvent markers.',
                                    value: settings.eventPins,
                                    onChanged: controller.setEventPins,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF2A303A)
                            : const Color(0xFFE3EAF3),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Powered by Mapbox',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.children,
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
        ...children,
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}