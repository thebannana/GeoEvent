import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/public_profile/models/public_profile_bundle.dart';
import '../../../shared/public_profile/models/public_profile_event_filter.dart';
import '../../../shared/public_profile/providers/public_profile_providers.dart';

final publicProfileControllerProvider = AutoDisposeAsyncNotifierProviderFamily<
    PublicProfileController, PublicProfileBundle, int>(
  PublicProfileController.new,
);

class PublicProfileController
    extends AutoDisposeFamilyAsyncNotifier<PublicProfileBundle, int> {
  static const int _pageSize = 20;

  bool _isSubmittingRating = false;
  bool _isLoadingMoreEvents = false;
  bool _isLoadingMoreReviews = false;
  bool _isChangingEventFilter = false;

  bool get isSubmittingRating => _isSubmittingRating;
  bool get isLoadingMoreEvents => _isLoadingMoreEvents;
  bool get isLoadingMoreReviews => _isLoadingMoreReviews;
  bool get isChangingEventFilter => _isChangingEventFilter;

  @override
  Future<PublicProfileBundle> build(int userId) {
    return ref.read(publicProfileRepositoryProvider).getProfile(
          userId,
          eventsPage: 1,
          eventsPageSize: _pageSize,
          eventFilter: PublicProfileEventFilter.all,
          reviewsPage: 1,
          reviewsPageSize: _pageSize,
        );
  }

  Future<void> reload() async {
    final current = state.valueOrNull;
    final selectedFilter =
        current?.selectedEventFilter ?? PublicProfileEventFilter.all;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(publicProfileRepositoryProvider).getProfile(
            arg,
            eventsPage: 1,
            eventsPageSize: _pageSize,
            eventFilter: selectedFilter,
            reviewsPage: 1,
            reviewsPageSize: _pageSize,
          ),
    );
  }

  Future<void> changeEventFilter(PublicProfileEventFilter filter) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (_isChangingEventFilter) return;
    if (current.selectedEventFilter == filter) return;

    _isChangingEventFilter = true;

    state = AsyncData(
      current.copyWith(
        selectedEventFilter: filter,
        events: const [],
        eventsPage: 1,
        eventsHasNextPage: false,
      ),
    );

    try {
      final pageData =
          await ref.read(publicProfileRepositoryProvider).getUserEventsPage(
                userId: arg,
                page: 1,
                filter: filter,
                pageSize: _pageSize,
              );

      final latest = state.valueOrNull ?? current;

      state = AsyncData(
        latest.copyWith(
          selectedEventFilter: filter,
          events: pageData.items,
          eventsPage: pageData.page,
          eventsHasNextPage: pageData.hasNextPage,
        ),
      );
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    } finally {
      _isChangingEventFilter = false;
    }
  }

  Future<void> loadMoreEvents() async {
    final current = state.valueOrNull;
    if (current == null || _isLoadingMoreEvents || !current.eventsHasNextPage) {
      return;
    }

    _isLoadingMoreEvents = true;

    try {
      final nextPage = current.eventsPage + 1;

      final pageData =
          await ref.read(publicProfileRepositoryProvider).getUserEventsPage(
                userId: arg,
                page: nextPage,
                filter: current.selectedEventFilter,
                pageSize: _pageSize,
              );

      final mergedEvents = [...current.events, ...pageData.items];

      state = AsyncData(
        current.copyWith(
          events: mergedEvents,
          eventsPage: pageData.page,
          eventsHasNextPage: pageData.hasNextPage,
        ),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    } finally {
      _isLoadingMoreEvents = false;
    }
  }

  Future<void> loadMoreReviews() async {
    final current = state.valueOrNull;
    if (current == null || _isLoadingMoreReviews || !current.reviewsHasNextPage) {
      return;
    }

    _isLoadingMoreReviews = true;

    try {
      final nextPage = current.reviewsPage + 1;

      final pageData =
          await ref.read(publicProfileRepositoryProvider).getUserReviewsPage(
                userId: arg,
                page: nextPage,
                pageSize: _pageSize,
              );

      final mergedReviews = [...current.reviews, ...pageData.items];

      state = AsyncData(
        current.copyWith(
          reviews: mergedReviews,
          reviewsPage: pageData.page,
          reviewsHasNextPage: pageData.hasNextPage,
        ),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    } finally {
      _isLoadingMoreReviews = false;
    }
  }

  Future<void> submitReview({
    required int rating,
    String? comment,
  }) async {
    if (_isSubmittingRating) return;

    final current = state.valueOrNull;
    if (current == null) return;

    _isSubmittingRating = true;
    state = AsyncData(current);

    try {
      final repo = ref.read(publicProfileRepositoryProvider);

      await repo.rateUser(
        userId: arg,
        rating: rating,
        comment: comment,
      );

      final refreshed = await repo.getProfile(
        arg,
        eventsPage: 1,
        eventsPageSize: _pageSize,
        eventFilter: current.selectedEventFilter,
        reviewsPage: 1,
        reviewsPageSize: _pageSize,
      );

      state = AsyncData(refreshed);
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    } finally {
      _isSubmittingRating = false;
    }
  }

  Future<void> deleteMyReview() async {
    if (_isSubmittingRating) return;

    final current = state.valueOrNull;
    if (current == null) return;

    _isSubmittingRating = true;
    state = AsyncData(current);

    try {
      final repo = ref.read(publicProfileRepositoryProvider);

      await repo.deleteMyReview(userId: arg);

      final refreshed = await repo.getProfile(
        arg,
        eventsPage: 1,
        eventsPageSize: _pageSize,
        eventFilter: current.selectedEventFilter,
        reviewsPage: 1,
        reviewsPageSize: _pageSize,
      );

      state = AsyncData(refreshed);
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    } finally {
      _isSubmittingRating = false;
    }
  }
}