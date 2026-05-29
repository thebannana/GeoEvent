import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_event/features/auth/application/auth_controller.dart';
import 'package:geo_event/features/profile/application/profile_controller.dart';
import 'package:geo_event/shared/events/data/my_events_api.dart';
import 'package:geo_event/shared/events/data/my_events_repository.dart';
import 'package:geo_event/shared/events/models/my_event_response_dto.dart';

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
    return _fetchMyEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMyEvents);
  }

  Future<List<MyEventResponseDto>> _fetchMyEvents() async {
    final profile = await ref.read(profileControllerProvider.future);
    final repo = ref.read(myEventsRepositoryProvider);
    return repo.getMyEvents(profile.userId);
  }
}