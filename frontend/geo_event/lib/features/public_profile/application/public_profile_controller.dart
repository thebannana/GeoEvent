import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/public_profile/models/public_profile_bundle.dart';
import '../../../shared/public_profile/providers/public_profile_providers.dart';

final publicProfileControllerProvider = AutoDisposeAsyncNotifierProviderFamily<
    PublicProfileController, PublicProfileBundle, int>(
  PublicProfileController.new,
);

class PublicProfileController
    extends AutoDisposeFamilyAsyncNotifier<PublicProfileBundle, int> {
  bool _isSubmittingRating = false;

  bool get isSubmittingRating => _isSubmittingRating;

  @override
  Future<PublicProfileBundle> build(int userId) {
    return ref.read(publicProfileRepositoryProvider).getProfile(userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(publicProfileRepositoryProvider).getProfile(arg),
    );
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

      final refreshed = await repo.getProfile(arg);
      state = AsyncData(refreshed);
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    } finally {
      _isSubmittingRating = false;
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest);
      }
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

      final refreshed = await repo.getProfile(arg);
      state = AsyncData(refreshed);
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    } finally {
      _isSubmittingRating = false;
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest);
      }
    }
  }
}