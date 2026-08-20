import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/events/providers/event_providers.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../shared/events/models/event_details_state.dart';

final eventDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<EventDetailsController, EventDetailsState, int>((ref, eventId) {
  return EventDetailsController(ref, eventId);
});

class EventDetailsController extends StateNotifier<EventDetailsState> {
  EventDetailsController(this.ref, this.eventId)
      : super(const EventDetailsState()) {
    load();
  }

  final Ref ref;
  final int eventId;

  Future<void> load() async {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isRefreshing: false,
      clearError: true,
    );

    try {
      final item = await ref
          .read(eventsRepositoryProvider)
          .getEventById(eventId);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        event: item,
        isLoading: false,
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: _messageFromError(
          error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (!mounted || state.isRefreshing) {
      return;
    }

    state = state.copyWith(
      isRefreshing: true,
      clearError: true,
    );

    try {
      final item = await ref
          .read(eventsRepositoryProvider)
          .getEventById(eventId);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        event: item,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isRefreshing: false,
        error: _messageFromError(
          error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void setEvent(EventItem item) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(event: item);
  }

  Future<void> likeEvent() async {
    final current = state.event;

    if (current == null || current.isLiked || state.isTogglingLike) {
      return;
    }

    state = state.copyWith(
      isTogglingLike: true,
      event: current.copyWith(
        isLiked: true,
        likesCount: current.likesCount + 1,
      ),
      clearError: true,
    );

    try {
      await ref
          .read(likedEventsProvider.notifier)
          .likeEvent(current.eventId);

      if (!mounted) {
        return;
      }

      state = state.copyWith(isTogglingLike: false);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isTogglingLike: false,
        event: current,
        error: _messageFromError(
          error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> unlikeEvent() async {
    final current = state.event;

    if (current == null || !current.isLiked || state.isTogglingLike) {
      return;
    }

    state = state.copyWith(
      isTogglingLike: true,
      event: current.copyWith(
        isLiked: false,
        likesCount:
            current.likesCount > 0 ? current.likesCount - 1 : 0,
      ),
      clearError: true,
    );

    try {
      await ref
          .read(likedEventsProvider.notifier)
          .unlikeEvent(current.eventId);

      if (!mounted) {
        return;
      }

      state = state.copyWith(isTogglingLike: false);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isTogglingLike: false,
        event: current,
        error: _messageFromError(
          error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  String _messageFromError(
    Object error, {
    StackTrace? stackTrace,
  }) {
    return ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: 'Unable to load event details.',
    );
  }
}