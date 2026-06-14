import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../location/providers/location_providers.dart';
import '../data/preferences_api.dart';
import '../data/preferences_repository.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';
import '../data/ticket_scanner_api.dart';
import '../data/ticket_scanner_repository.dart';
import '../models/activity_log.dart';
import '../models/mapbox_city_search.dart';
import '../models/user_preference.dart';
import '../models/user_profile.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(authorizedDioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(profileApiProvider));
});

final preferencesApiProvider = Provider<PreferencesApi>((ref) {
  return PreferencesApi(ref.watch(authorizedDioProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(ref.watch(preferencesApiProvider));
});

final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(sessionUserIdProvider);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

final myPreferencesProvider = FutureProvider<List<UserPreference>>((ref) async {
  ref.watch(sessionUserIdProvider);
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.getPreferences();
});

final preferredSegmentIdsProvider = Provider<Set<int>>((ref) {
  final prefs = ref.watch(myPreferencesProvider).valueOrNull ?? const <UserPreference>[];

  return prefs
      .where((p) => p.segmentId != null && p.score > 0)
      .map((p) => p.segmentId!)
      .toSet();
});

final preferredGenreIdsProvider = Provider<Set<int>>((ref) {
  final prefs = ref.watch(myPreferencesProvider).valueOrNull ?? const <UserPreference>[];

  return prefs
      .where((p) => p.genreId != null && p.score > 0)
      .map((p) => p.genreId!)
      .toSet();
});

final preferredSubGenreIdsProvider = Provider<Set<int>>((ref) {
  return const <int>{};
});

final mapboxCitySearchProvider =
    FutureProvider.autoDispose.family<List<MapboxCitySearchResult>, String>((
  ref,
  query,
) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return const [];

  return ref.read(mapboxPlacesServiceProvider).searchCities(trimmed);
});

final ticketScannerApiProvider = Provider<TicketScannerApi>((ref) {
  return TicketScannerApi(ref.watch(authorizedDioProvider));
});

final ticketScannerRepositoryProvider = Provider<TicketScannerRepository>((ref) {
  return TicketScannerRepository(ref.watch(ticketScannerApiProvider));
});

final myActivityLogsProvider =
    FutureProvider.autoDispose.family<List<ActivityLog>, ({int page, int pageSize})>(
  (ref, params) async {
    ref.watch(sessionUserIdProvider);
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getActivityLogs(
      page: params.page,
      pageSize: params.pageSize,
    );
  },
);
