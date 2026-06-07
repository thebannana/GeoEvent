import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/providers/chat_providers.dart';
import '../../../../shared/public_profile/models/public_profile_event.dart';
import '../../../../shared/public_profile/models/public_profile_user.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../../reports/presentation/screens/report_screen.dart';
import '../../application/public_profile_controller.dart';
import '../widgets/public_profile_action_buttons.dart';
import '../widgets/public_profile_empty_state.dart';
import '../widgets/public_profile_event_filters.dart';
import '../widgets/public_profile_event_list.dart';
import '../widgets/public_profile_header.dart';
import '../widgets/public_profile_rating_card.dart';
import '../widgets/public_profile_review_section.dart';
import '../widgets/public_profile_stats_row.dart';

enum PublicProfileEventFilter { all, upcoming, past, free, paid }

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
  PublicProfileEventFilter _selectedFilter = PublicProfileEventFilter.all;

  List<PublicProfileEvent> _applyFilter(List<PublicProfileEvent> events) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case PublicProfileEventFilter.all:
        return events;
      case PublicProfileEventFilter.upcoming:
        return events
            .where(
              (e) => e.startDateTime != null && e.startDateTime!.isAfter(now),
            )
            .toList();
      case PublicProfileEventFilter.past:
        return events
            .where(
              (e) => e.startDateTime != null && e.startDateTime!.isBefore(now),
            )
            .toList();
      case PublicProfileEventFilter.free:
        return events.where((e) => e.price <= 0).toList();
      case PublicProfileEventFilter.paid:
        return events.where((e) => e.price > 0).toList();
    }
  }

Future<void> openDirectChat({
    required BuildContext context,
    required WidgetRef ref,
    required int otherUserId,
  }) async {
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
            title: result['title'] as String? ?? 'Chat',
            otherUserId: (result['otherUserId'] as num?)?.toInt(),
          ),
        ),
      ),
    );
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You rated this profile $value/5.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit rating. Please try again.'),
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
        builder: (_) => _WriteReviewScreen(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hadExistingReview ? 'Review updated.' : 'Review saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicProfileControllerProvider(widget.userId));
    final controller =
        ref.read(publicProfileControllerProvider(widget.userId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load profile.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(publicProfileControllerProvider(widget.userId)
                            .notifier)
                        .reload();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final filteredEvents = _applyFilter(data.events);

          return RefreshIndicator(
            onRefresh: () => ref
                .read(publicProfileControllerProvider(widget.userId).notifier)
                .reload(),
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
                        eventsCount: data.events.length,
                      ),
                      const SizedBox(height: 18),
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
                      PublicProfileEventFilters(
                        selected: _selectedFilter,
                        onChanged: (value) {
                          setState(() => _selectedFilter = value);
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                if (filteredEvents.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: PublicProfileEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    sliver: PublicProfileEventList(
                      events: filteredEvents,
                      onEventTap: _openEvent,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      PublicProfileReviewsSection(
                        reviews: data.reviews,
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

class _WriteReviewScreen extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;
  final bool canDelete;
  final Future<void> Function(int rating, String? comment) onSave;
  final Future<void> Function()? onDelete;

  const _WriteReviewScreen({
    required this.initialRating,
    required this.initialComment,
    required this.canDelete,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<_WriteReviewScreen> {
  int? _rating;
  late final TextEditingController _commentController;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController =
        TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == null || _isBusy) return;

    setState(() => _isBusy = true);

    try {
      await widget.onSave(_rating!, _commentController.text);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.onDelete == null || _isBusy) return;

    setState(() => _isBusy = true);

    try {
      await widget.onDelete!.call();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leave a review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  final active = (_rating ?? 0) >= star;

                  return IconButton(
                    onPressed: _isBusy
                        ? null
                        : () {
                            setState(() => _rating = star);
                          },
                    icon: Icon(
                      active
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: active ? const Color(0xFFFFC857) : Colors.grey,
                      size: 30,
                    ),
                  );
                }),
              ),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Write your review (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isBusy ? null : _save,
                  child: _isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save review'),
                ),
              ),
              if (widget.canDelete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _delete,
                    child: const Text('Delete review'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}