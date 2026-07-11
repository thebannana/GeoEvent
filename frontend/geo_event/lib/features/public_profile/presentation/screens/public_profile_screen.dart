import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/providers/chat_providers.dart';
import '../../../../shared/public_profile/models/public_profile_user.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../../reports/presentation/screens/report_screen.dart';
import '../../application/public_profile_controller.dart';
import '../widgets/public_profile_action_buttons.dart';
import '../widgets/public_profile_event_filters.dart';
import '../widgets/public_profile_event_list.dart';
import '../widgets/public_profile_header.dart';
import '../widgets/public_profile_rating_card.dart';
import '../widgets/public_profile_review_section.dart';
import '../widgets/public_profile_stats_row.dart';
import 'write_review_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final int userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> openDirectChat({
    required BuildContext context,
    required WidgetRef ref,
    required int otherUserId,
  }) async {
    try {
      final result = await ref.read(messagesRepositoryProvider).openDirectThread(
            otherUserId: otherUserId,
          );

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            args: ChatThreadArgs(
              threadId: (result['threadId'] as num).toInt(),
              type: ChatThreadType.direct,
              title: (result['title'] as String?)?.trim().isNotEmpty == true
                  ? (result['title'] as String).trim()
                  : 'Chat',
              otherUserId: (result['otherUserId'] as num?)?.toInt(),
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to open direct chat.',
        tag: 'PublicProfileScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ErrorMapper.toMessage(
                error,
                stackTrace: stackTrace,
                fallbackMessage: 'Could not open chat. Please try again.',
              ),
            ),
          ),
        );
    }
  }

  Future<void> _openReportUserScreen(PublicProfileUser user) async {
    final fullName = user.fullName.trim();
    final username = user.username.trim();
    final imageUrl = (user.imageUrl ?? '').trim();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetType: ReportTargetType.user,
          targetId: user.userId,
          targetTitle: fullName.isNotEmpty ? fullName : '@$username',
          targetSubtitle: username.isNotEmpty ? '@$username' : null,
          targetImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        ),
      ),
    );
  }

  void _openEvent(int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: eventId),
      ),
    );
  }

  Future<void> _setRating(int value) async {
    final controller =
        ref.read(publicProfileControllerProvider(widget.userId).notifier);

    try {
      await controller.submitReview(rating: value);
      _showMessage('You rated this profile $value/5.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to submit rating.',
        tag: 'PublicProfileScreen',
        error: error,
        stackTrace: stackTrace,
      );

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not submit rating. Please try again.',
        ),
      );
    }
  }

  Future<void> _openReviewPage(PublicProfileUser user) async {
    final controller =
        ref.read(publicProfileControllerProvider(widget.userId).notifier);

    final hadExistingReview = user.myRating != null ||
        ((user.myReviewComment ?? '').trim().isNotEmpty);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          initialRating: user.myRating,
          initialComment: user.myReviewComment,
          canDelete: hadExistingReview,
          onSave: (rating, comment) async {
            await controller.submitReview(
              rating: rating,
              comment: comment,
            );
          },
          onDelete: hadExistingReview
              ? () async {
                  await controller.deleteMyReview();
                }
              : null,
        ),
      ),
    );

    if (!mounted || result != true) return;

    _showMessage(
      hadExistingReview ? 'Review updated.' : 'Review saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicProfileControllerProvider(widget.userId));
    final controller =
        ref.read(publicProfileControllerProvider(widget.userId).notifier);
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.userId;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: AppAsyncView(
        value: state,
        loading: const AppLoadingIndicator(
          title: 'Loading profile',
          message: 'Fetching public profile details...',
        ),
        errorBuilder: (error, stackTrace) => AppErrorState(
          title: 'Could not load profile',
          message: ErrorMapper.toMessage(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Please try again.',
          ),
          onRetry: controller.reload,
        ),
        data: (data) {
          final isOwnProfile =
              currentUserId != null && currentUserId == data.user.userId;

          return RefreshIndicator(
            onRefresh: controller.reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      PublicProfileHeader(user: data.user),
                      const SizedBox(height: 18),
                      PublicProfileStatsRow(
                        user: data.user,
                        eventsCount: data.user.eventsCount,
                      ),
                      const SizedBox(height: 18),
                      if (!isOwnProfile) ...[
                        PublicProfileRatingCard(
                          averageRating: data.user.averageRating,
                          ratingsCount: data.user.ratingsCount,
                          myRating: data.user.myRating,
                          myReviewComment: data.user.myReviewComment,
                          isSubmitting: controller.isSubmittingRating,
                          onRatingSelected: _setRating,
                          onWriteReviewTap: () => _openReviewPage(data.user),
                        ),
                        const SizedBox(height: 18),
                        PublicProfileActionButtons(
                          user: data.user,
                          onMessageTap: () => openDirectChat(
                            context: context,
                            ref: ref,
                            otherUserId: data.user.userId,
                          ),
                          onReportTap: () => _openReportUserScreen(data.user),
                        ),
                        const SizedBox(height: 18),
                      ],
                      PublicProfileEventFilters(
                        selected: data.selectedEventFilter,
                        onChanged: controller.changeEventFilter,
                        isBusy: controller.isChangingEventFilter,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                if (data.events.isEmpty && controller.isChangingEventFilter)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (data.events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No public events found',
                      message:
                          'There are no visible events for the selected filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    sliver: PublicProfileEventList(
                      events: data.events,
                      onEventTap: _openEvent,
                      hasNextPage: data.eventsHasNextPage,
                      isLoadingMore: controller.isLoadingMoreEvents,
                      onLoadMore: controller.loadMoreEvents,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      PublicProfileReviewsSection(
                        reviews: data.reviews,
                        hasNextPage: data.reviewsHasNextPage,
                        isLoadingMore: controller.isLoadingMoreReviews,
                        onLoadMore: controller.loadMoreReviews,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}