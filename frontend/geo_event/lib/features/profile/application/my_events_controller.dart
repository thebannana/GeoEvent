import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../../shared/events/data/my_events_api.dart';
import '../../../shared/events/data/my_events_repository.dart';
import '../../../shared/events/models/my_event_response_dto.dart';

final myEventsApiProvider = Provider<MyEventsApi>((ref) {
  return MyEventsApi(ref.watch(authorizedDioProvider));
});

final myEventsRepositoryProvider = Provider<MyEventsRepository>((ref) {
  return MyEventsRepository(ref.watch(myEventsApiProvider));
});

final myEventsProvider =
    AsyncNotifierProvider<MyEventsController, List<MyEventResponseDto>>(
  MyEventsController.new,
);

class MyEventsController extends AsyncNotifier<List<MyEventResponseDto>> {
  @override
  Future<List<MyEventResponseDto>> build() async {
    ref.watch(sessionUserIdProvider);

    final profile = await ref.watch(profileControllerProvider.future);
    final repo = ref.read(myEventsRepositoryProvider);
    return repo.getMyEvents(profile.userId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileControllerProvider.future);
      final repo = ref.read(myEventsRepositoryProvider);
      return repo.getMyEvents(profile.userId);
    });
  }

  Future<bool> deleteEvent(int eventId) async {
    final current = state.valueOrNull ?? const <MyEventResponseDto>[];

    try {
      await ref.read(myEventsRepositoryProvider).deleteEvent(eventId);

      state = AsyncData(
        current.where((e) => e.eventId != eventId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}