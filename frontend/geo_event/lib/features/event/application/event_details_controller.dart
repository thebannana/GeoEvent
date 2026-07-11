import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../shared/events/models/event_details_state.dart';

final eventDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventDetailsController, EventDetailsState, int>((ref, eventId) {
  return EventDetailsController(ref, eventId);
});

class EventDetailsController extends StateNotifier<EventDetailsState> {
  final Ref ref;
  final int eventId;

  EventDetailsController(this.ref, this.eventId)
      : super(const EventDetailsState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      isRefreshing: false,
      clearError: true,
    );

    try {
      final item = await ref.read(eventsRepositoryProvider).getEventById(eventId);

      if (!mounted) return;
      state = state.copyWith(
        event: item,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: _messageFromError(e),
      );
    }
  }

  Future<void> refresh() async {
    if (!mounted || state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      clearError: true,
    );

    try {
      final item = await ref.read(eventsRepositoryProvider).getEventById(eventId);

      if (!mounted) return;
      state = state.copyWith(
        event: item,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        error: _messageFromError(e),
      );
    }
  }

  void setEvent(EventItem item) {
    if (!mounted) return;
    state = state.copyWith(event: item);
  }

  Future<void> likeEvent() async {
    final current = state.event;
    if (current == null || current.isLiked || state.isTogglingLike) return;

    state = state.copyWith(
      isTogglingLike: true,
      event: current.copyWith(
        isLiked: true,
        likesCount: current.likesCount + 1,
      ),
      clearError: true,
    );

    try {
      await ref.read(likedEventsProvider.notifier).likeEvent(current.eventId);

      if (!mounted) return;
      state = state.copyWith(isTogglingLike: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isTogglingLike: false,
        event: current,
        error: _messageFromError(e),
      );
    }
  }

  Future<void> unlikeEvent() async {
    final current = state.event;
    if (current == null || !current.isLiked || state.isTogglingLike) return;

    state = state.copyWith(
      isTogglingLike: true,
      event: current.copyWith(
        isLiked: false,
        likesCount: current.likesCount > 0 ? current.likesCount - 1 : 0,
      ),
      clearError: true,
    );

    try {
      await ref.read(likedEventsProvider.notifier).unlikeEvent(current.eventId);

      if (!mounted) return;
      state = state.copyWith(isTogglingLike: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isTogglingLike: false,
        event: current,
        error: _messageFromError(e),
      );
    }
  }

  String _messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return error.message ?? 'Something went wrong.';
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }
}