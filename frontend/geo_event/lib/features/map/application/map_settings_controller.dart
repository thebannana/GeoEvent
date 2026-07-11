import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapSettingsState {
  final bool map3D;
  final bool dayNightCycle;
  final bool mapPins;
  final bool eventPins;

  const MapSettingsState({
    required this.map3D,
    required this.dayNightCycle,
    required this.mapPins,
    required this.eventPins,
  });

  const MapSettingsState.initial()
      : map3D = true,
        dayNightCycle = true,
        mapPins = true,
        eventPins = true;

  MapSettingsState copyWith({
    bool? map3D,
    bool? dayNightCycle,
    bool? mapPins,
    bool? eventPins,
  }) {
    return MapSettingsState(
      map3D: map3D ?? this.map3D,
      dayNightCycle: dayNightCycle ?? this.dayNightCycle,
      mapPins: mapPins ?? this.mapPins,
      eventPins: eventPins ?? this.eventPins,
    );
  }
}

class MapSettingsController extends Notifier<MapSettingsState> {
  @override
  MapSettingsState build() => const MapSettingsState.initial();

  void setMap3D(bool value) => state = state.copyWith(map3D: value);
  void setDayNightCycle(bool value) =>
      state = state.copyWith(dayNightCycle: value);
  void setMapPins(bool value) => state = state.copyWith(mapPins: value);
  void setEventPins(bool value) => state = state.copyWith(eventPins: value);

  void toggleMap3D() => state = state.copyWith(map3D: !state.map3D);
  void toggleDayNightCycle() =>
      state = state.copyWith(dayNightCycle: !state.dayNightCycle);
  void toggleMapPins() => state = state.copyWith(mapPins: !state.mapPins);
  void toggleEventPins() => state = state.copyWith(eventPins: !state.eventPins);

  void reset() => state = const MapSettingsState.initial();
}

final mapSettingsControllerProvider =
    NotifierProvider<MapSettingsController, MapSettingsState>(
  MapSettingsController.new,
);