import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../../core/network/api_client.dart';
import '../data/preferences_api.dart';
import '../data/preferences_repository.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';
import '../data/ticket_scanner_api.dart';
import '../data/ticket_scanner_repository.dart';
import '../models/preferences_query.dart';
import '../models/user_preference.dart';

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

final ticketScannerApiProvider = Provider<TicketScannerApi>((ref) {
  return TicketScannerApi(ref.watch(authorizedDioProvider));
});

final ticketScannerRepositoryProvider =
    Provider<TicketScannerRepository>((ref) {
  return TicketScannerRepository(ref.watch(ticketScannerApiProvider));
});

final myPreferencesProvider = FutureProvider<List<UserPreference>>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (!authState.isAuthenticated) {
    return const <UserPreference>[];
  }

  final result = await ref.read(preferencesRepositoryProvider).getPreferences(
        query: const PreferencesQuery(
          page: 1,
          pageSize: 50,
        ),
      );

  return result.items;
});

final preferredSegmentIdsProvider = Provider<Set<int>>((ref) {
  final preferences =
      ref.watch(myPreferencesProvider).valueOrNull ?? const <UserPreference>[];

  return preferences
      .where((item) => item.segmentId != null && item.score > 0)
      .map((item) => item.segmentId!)
      .toSet();
});

final preferredGenreIdsProvider = Provider<Set<int>>((ref) {
  final preferences =
      ref.watch(myPreferencesProvider).valueOrNull ?? const <UserPreference>[];

  return preferences
      .where((item) => item.genreId != null && item.score > 0)
      .map((item) => item.genreId!)
      .toSet();
});

final preferredSubGenreIdsProvider = Provider<Set<int>>((ref) {
  final preferences =
      ref.watch(myPreferencesProvider).valueOrNull ?? const <UserPreference>[];

  return preferences
      .where((item) => item.subGenreId != null && item.score > 0)
      .map((item) => item.subGenreId!)
      .toSet();
});