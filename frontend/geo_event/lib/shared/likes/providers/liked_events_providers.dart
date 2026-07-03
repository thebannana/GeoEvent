import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../data/liked_events_api.dart';
import '../models/liked_event.dart';

final likedEventsProvider =
    AsyncNotifierProvider<LikedEventsController, List<LikedEvent>>(
  LikedEventsController.new,
);

class LikedEventsController extends AsyncNotifier<List<LikedEvent>> {
  @override
  Future<List<LikedEvent>> build() async {
    ref.watch(sessionUserIdProvider);
    return _load();
  }

  Future<List<LikedEvent>> _load() async {
    final items = await ref.read(likedEventsApiProvider).getLikedEvents();
    final sorted = [...items]..sort((a, b) => b.likedAt.compareTo(a.likedAt));
    return List.unmodifiable(sorted);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> likeEvent(int eventId) async {
    final current = state.valueOrNull ?? const <LikedEvent>[];
    final alreadyLiked = current.any((e) => e.eventId == eventId);
    if (alreadyLiked) return;

    await ref.read(likedEventsApiProvider).likeEvent(eventId);
    await refresh();
  }

  Future<void> unlikeEvent(int eventId) async {
    final snapshot = state.valueOrNull ?? const <LikedEvent>[];

    state = AsyncData(
      List.unmodifiable(snapshot.where((e) => e.eventId != eventId).toList()),
    );

    try {
      await ref.read(likedEventsApiProvider).unlikeEvent(eventId);
    } catch (_) {
      state = AsyncData(List.unmodifiable(snapshot));
      rethrow;
    }
  }
}