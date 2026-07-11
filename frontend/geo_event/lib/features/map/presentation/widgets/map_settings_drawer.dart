import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/inputs/app_icon_circle_button.dart';
import '../../application/map_settings_controller.dart';
import 'map_settings_section.dart';

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
  static const _animationDuration = Duration(milliseconds: 260);
  static const _minWidth = 280.0;
  static const _maxWidth = 360.0;
  static const _minHeight = 420.0;
  static const _maxHeight = 620.0;
  static const _logoHeight = 28.0;

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
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
    if (_closing) return;
    _closing = true;

    await _controller.reverse();

    if (mounted) {
      widget.onClose();
    }
  }

  Color _dividerColor(ThemeData theme) {
    return theme.colorScheme.outline.withValues(alpha: 0.24);
  }

  BoxDecoration _buildDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.35),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

Widget _buildLogoImage({
  required String assetPath,
  required String semanticLabel,
}) {
  return SizedBox(
    height: _logoHeight,
    child: Center(
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) {
          final theme = Theme.of(context);
          return Text(
            semanticLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(mapSettingsControllerProvider);
    final controller = ref.read(mapSettingsControllerProvider.notifier);
    final width = MediaQuery.of(context).size.width * 0.78;
    final dividerColor = _dividerColor(theme);

    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: width.clamp(_minWidth, _maxWidth),
                  constraints: const BoxConstraints(
                    minHeight: _minHeight,
                    maxHeight: _maxHeight,
                  ),
                  decoration: _buildDecoration(theme),
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
                                    'Map presentation settings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppIconCircleButton(
                              onPressed: _close,
                              tooltip: 'Close map settings',
                              icon: Icons.close_rounded,
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: dividerColor),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MapSettingsSection(
                                title: 'Scene',
                                items: [
                                  MapSettingsSectionItem(
                                    label: '3D buildings & scene',
                                    subtitle:
                                        'Uses the rendered scene depth instead of only camera tilt.',
                                    value: settings.map3D,
                                    onChanged: controller.setMap3D,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              MapSettingsSection(
                                title: 'Lighting',
                                items: [
                                  MapSettingsSectionItem(
                                    label: 'Auto day/night cycle',
                                    subtitle:
                                        'Adapts lighting by time for a more realistic seminar demo.',
                                    value: settings.dayNightCycle,
                                    onChanged: controller.setDayNightCycle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              MapSettingsSection(
                                title: 'Labels & pins',
                                items: [
                                  MapSettingsSectionItem(
                                    label: 'Map POIs',
                                    subtitle:
                                        'Show or hide built-in places such as shops, parks, and landmarks.',
                                    value: settings.mapPins,
                                    onChanged: controller.setMapPins,
                                  ),
                                  MapSettingsSectionItem(
                                    label: 'Event pins',
                                    subtitle:
                                        'Show or hide custom geoEvent markers on the map.',
                                    value: settings.eventPins,
                                    onChanged: controller.setEventPins,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: dividerColor),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildLogoImage(
                                assetPath: 'assets/images/geoevent.png',
                                semanticLabel: 'geoEvent logo',
                              ),
                              const SizedBox(height: 12),
                              _buildLogoImage(
                                assetPath: 'assets/images/mapbox.png',
                                semanticLabel: 'Mapbox logo',
                              ),
                            ],
                          ),
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