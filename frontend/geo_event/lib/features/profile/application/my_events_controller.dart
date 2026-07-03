import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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
  MyEventsRepository get _repository => ref.read(myEventsRepositoryProvider);

  @override
  Future<List<MyEventResponseDto>> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<bool> deleteEvent(int eventId) async {
    final currentItems = state.valueOrNull ?? const <MyEventResponseDto>[];

    try {
      await _repository.deleteEvent(eventId);

      state = AsyncData(
        currentItems.where((event) => event.eventId != eventId).toList(),
      );

      return true;
    } catch (_) {
      state = AsyncData(currentItems);
      return false;
    }
  }

  Future<List<MyEventResponseDto>> _load() async {
    final profile = await ref.read(profileControllerProvider.future);
    return _repository.getMyEvents(profile.userId);
  }
}