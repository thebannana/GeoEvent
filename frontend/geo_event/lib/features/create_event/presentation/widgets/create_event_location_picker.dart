import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_event/core/config/app_environment.dart';

import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/models/create_event_state.dart';
import '../../../../shared/location/providers/location_providers.dart';
import 'create_event_form.dart';
import 'create_event_location_search_tile.dart';

class CreateEventLocationPicker extends StatelessWidget {
  final CreateEventState state;
  final VoidCallback? onTapPickLocation;
  final VoidCallback? onClearLocation;

  const CreateEventLocationPicker({
    super.key,
    required this.state,
    this.onTapPickLocation,
    this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = state.submitting;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Location'),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : onTapPickLocation,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Location',
                suffixIcon: const Icon(Icons.location_on_outlined),
                enabled: !disabled,
              ),
              child: Text(
                state.selectedLocation?.title ?? 'Search for a place',
                style: TextStyle(
                  fontSize: 14,
                  color: state.selectedLocation != null
                      ? theme.textTheme.bodyMedium?.color
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          if (state.selectedLocation != null) ...[
            const SizedBox(height: 10),
            AppSurfaceCard(
              padding: const EdgeInsets.all(14),
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
                      onPressed: state.submitting ? null : onClearLocation,
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
  ConsumerState<LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
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
    if (AppEnvironment.mapboxAccessToken.isEmpty) {
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
    if (AppEnvironment.mapboxAccessToken.isEmpty) {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AppBottomSheetContainer(
      maxHeightFactor: 0.88,
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Choose location',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.60,
            child: loading
                ? const Center(
                    child: AppSpinner(size: 28, strokeWidth: 2.8),
                  )
                : error != null
                    ? AppErrorState(
                        title: 'Search failed',
                        message: error!,
                      )
                    : results.isEmpty
                        ? const AppEmptyState(
                            title: 'Start typing',
                            message: 'Search for a place or address.',
                            icon: Icons.location_searching_rounded,
                            padding: EdgeInsets.all(24),
                          )
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = results[index];
                              return CreateEventLocationSearchResultTile(
                                item: item,
                                onTap: () => Navigator.of(context).pop(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}