import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/liked_events_api.dart';
import '../models/liked_event.dart';

final likedEventsProvider =
    StateNotifierProvider<LikedEventsNotifier, AsyncValue<List<LikedEventDto>>>(
  (ref) => LikedEventsNotifier(ref),
);

class LikedEventsNotifier extends StateNotifier<AsyncValue<List<LikedEventDto>>> {
  final Ref ref;

  LikedEventsNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(
      () => ref.read(likedEventsApiProvider).getLikedEvents(),
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(likedEventsApiProvider).getLikedEvents(),
    );
  }

  Future<void> likeEvent(int eventId) async {
  final previous = state;
  final current = state.valueOrNull ?? const <LikedEventDto>[];

  final alreadyLiked = current.any((e) => e.eventId == eventId);
  if (alreadyLiked) return;

  final optimistic = LikedEventDto(
    eventId: eventId,
    title: '',
    imageUrl: null,
    likedAt: DateTime.now(),
    isLiked: true,
  );

  state = AsyncValue.data([optimistic, ...current]);

  try {
    await ref.read(likedEventsApiProvider).likeEvent(eventId);
    await refresh();
  } catch (_) {
    state = previous;
    rethrow;
  }
}

  Future<void> unlikeEvent(int eventId) async {
    final previous = state;

    state.whenData((items) {
      state = AsyncValue.data(
        items.where((e) => e.eventId != eventId).toList(),
      );
    });

    try {
      await ref.read(likedEventsApiProvider).unlikeEvent(eventId);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}