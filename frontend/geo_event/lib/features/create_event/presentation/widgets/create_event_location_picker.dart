import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_env.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import '../../../../shared/location/providers/location_providers.dart';
import 'create_event_form.dart';

class CreateEventLocationPicker extends StatelessWidget {
  final CreateEventState state;
  final VoidCallback onTapPickLocation;
  final VoidCallback onClearLocation;

  const CreateEventLocationPicker({
    super.key,
    required this.state,
    required this.onTapPickLocation,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Location'),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: state.isOnline ? null : onTapPickLocation,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Location',
                suffixIcon: const Icon(Icons.location_on_outlined),
                enabled: !state.isOnline,
              ),
              child: Text(
                state.isOnline
                    ? 'Online event does not require a physical location'
                    : state.selectedLocation?.title ?? 'Search for a place',
                style: TextStyle(
                  fontSize: 14,
                  color: state.selectedLocation != null && !state.isOnline
                      ? theme.textTheme.bodySmall?.color
                      : null,
                ),
              ),
            ),
          ),
          if (state.selectedLocation != null && !state.isOnline) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.selectedLocation!.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((state.selectedLocation!.subtitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.selectedLocation!.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onClearLocation,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LocationSearchSheet extends ConsumerStatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  ConsumerState<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<LocationSearchSheet> {
  final controller = TextEditingController();
  Timer? debounce;

  bool loading = false;
  String? error;
  List<MapboxPlace> results = const [];

  @override
  void initState() {
    super.initState();
    if (AppEnv.mapboxToken.isEmpty) {
      error =
          'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=yourtoken';
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> performSearch(String query) async {
    if (AppEnv.mapboxToken.isEmpty) {
      setState(() {
        results = const [];
        loading = false;
        error =
            'MAPBOX_ACCESS_TOKEN is missing. Run the app with --dart-define=MAPBOX_ACCESS_TOKEN=yourtoken';
      });
      return;
    }

    if (query.trim().length < 2) {
      setState(() {
        results = const [];
        error = null;
        loading = false;
      });
      return;
    }

    final service = ref.read(mapboxPlacesServiceProvider);

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final found = await service.searchPlaces(query);
      if (!mounted) return;

      setState(() {
        results = found;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        results = const [];
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161A21) : const Color(0xFFF9FBFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose location',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (value) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 350), () {
                  performSearch(value);
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search place or address',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : results.isEmpty
                          ? const Center(
                              child: Text('Start typing to search for a place.'),
                            )
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = results[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.of(context).pop(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2A303A)
                                            : const Color(0xFFE3EAF3),
                                      ),
                                      color: isDark
                                          ? const Color(0xFF1B2028)
                                          : Colors.white,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if ((item.subtitle ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.subtitle!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}