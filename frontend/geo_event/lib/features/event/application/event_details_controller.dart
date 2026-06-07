import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../shared/likes/providers/liked_events_providers.dart';

class EventDetailsState {
  final EventItem? event;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const EventDetailsState({
    this.event,
    this.isLoading = true,
    this.isRefreshing = false,
    this.error,
  });

  bool get hasData => event != null;
  bool get hasError => error != null && error!.trim().isNotEmpty;

  EventDetailsState copyWith({
    EventItem? event,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return EventDetailsState(
      event: event ?? this.event,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

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
    state = state.copyWith(
      isLoading: true,
      isRefreshing: false,
      clearError: true,
    );

    try {
      final item =
          await ref.read(eventsRepositoryProvider).getEventById(eventId);

      state = EventDetailsState(
        event: item,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      state = EventDetailsState(
        event: null,
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(
      isRefreshing: true,
      clearError: true,
    );

    try {
      final item =
          await ref.read(eventsRepositoryProvider).getEventById(eventId);

      state = EventDetailsState(
        event: item,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  void setEvent(EventItem item) {
    state = state.copyWith(event: item);
  }

Future<void> likeEvent() async {
  final current = state.event;
  if (current == null || current.isLiked) return;

  final optimistic = current.copyWith(
    isLiked: true,
    likesCount: current.likesCount + 1,
  );

  state = state.copyWith(event: optimistic, clearError: true);

  try {
    await ref.read(likedEventsProvider.notifier).likeEvent(current.eventId);

    final refreshed =
        await ref.read(eventsRepositoryProvider).getEventById(current.eventId);

    state = state.copyWith(
      event: refreshed,
      clearError: true,
    );
  } catch (e) {
    state = state.copyWith(
      event: current,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<void> unlikeEvent() async {
  final current = state.event;
  if (current == null || !current.isLiked) return;

  final optimistic = current.copyWith(
    isLiked: false,
    likesCount: current.likesCount > 0 ? current.likesCount - 1 : 0,
  );

  state = state.copyWith(event: optimistic, clearError: true);

  try {
    await ref.read(likedEventsProvider.notifier).unlikeEvent(current.eventId);

    final refreshed =
        await ref.read(eventsRepositoryProvider).getEventById(current.eventId);

    state = state.copyWith(
      event: refreshed,
      clearError: true,
    );
  } catch (e) {
    state = state.copyWith(
      event: current,
      error: e.toString(),
    );
    rethrow;
  }
}
}