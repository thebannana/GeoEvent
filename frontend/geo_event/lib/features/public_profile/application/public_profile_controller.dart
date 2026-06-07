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
    final repository = ref.read(publicProfileRepositoryProvider);
    return repository.getProfile(userId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(publicProfileRepositoryProvider);
      return repository.getProfile(arg);
    });
  }

  Future<void> submitReview({
    required int rating,
    String? comment,
  }) async {
    if (_isSubmittingRating) return;

    _isSubmittingRating = true;
    ref.notifyListeners();

    try {
      final repository = ref.read(publicProfileRepositoryProvider);
      await repository.rateUser(
        userId: arg,
        rating: rating,
        comment: comment,
      );

      final refreshed = await repository.getProfile(arg);
      state = AsyncData(refreshed);
    } finally {
      _isSubmittingRating = false;
      ref.notifyListeners();
    }
  }

  Future<void> deleteMyReview() async {
    if (_isSubmittingRating) return;

    _isSubmittingRating = true;
    ref.notifyListeners();

    try {
      final repository = ref.read(publicProfileRepositoryProvider);
      await repository.deleteMyReview(userId: arg);

      final refreshed = await repository.getProfile(arg);
      state = AsyncData(refreshed);
    } finally {
      _isSubmittingRating = false;
      ref.notifyListeners();
    }
  }
}