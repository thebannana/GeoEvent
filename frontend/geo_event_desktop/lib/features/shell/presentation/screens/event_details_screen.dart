import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/constants/event_status.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/admin_profile/data/admin_events_repository.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/admin_event.dart';
import '../../../../shared/admin_profile/models/paged_response.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';
import '../../../../shared/admin_profile/providers/admin_events_providers.dart';
import '../../../../shared/map/models/mapbox_place.dart';
import '../../../../shared/map/providers/mapbox_providers.dart';
import 'user_profile_screen.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.usersRepository,
    this.onOpenUserProfile,
  });

  final int eventId;
  final AdminUsersRepository usersRepository;
  final void Function(BuildContext context, int userId)? onOpenUserProfile;

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  AdminEvent? _event;
  EventReservationSummary? _reservationSummary;
  List<AdminComment> _comments = const [];
  AdminUserProfileDetails? _organizerProfile;
  MapboxPlace? _resolvedPlace;

  final Set<int> _expandedReplyThreads = <int>{};
  final Set<int> _loadingRepliesFor = <int>{};
  final Set<int> _loadedRepliesFor = <int>{};
  final Set<int> _busyCommentIds = <int>{};

  late final PageController _pageController;
  int _currentImageIndex = 0;

  AdminEventsRepository get _eventsRepository =>
      ref.read(adminEventsRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _eventsRepository.getEventById(widget.eventId),
        _eventsRepository.getEventReservationSummary(widget.eventId),
        _eventsRepository.getEventComments(
          eventId: widget.eventId,
          page: 1,
          pageSize: 50,
        ),
      ]);

      final event = results[0] as AdminEvent;
      final reservationSummary = results[1] as EventReservationSummary;
      final commentsPage = results[2] as PagedResponse<AdminComment>;

      AdminUserProfileDetails? organizerProfile;
      final organizerId = event.organizerId;
      if (organizerId != null && organizerId > 0) {
        try {
          organizerProfile =
              await widget.usersRepository.getUserProfileDetails(organizerId);
        } catch (e, st) {
          AppLogger.error(
            'Failed to load organizer profile',
            tag: 'EventDetails',
            error: e,
            stackTrace: st,
          );
          organizerProfile = null;
        }
      }

      MapboxPlace? resolvedPlace;
      if (AppEnvironment.hasMapbox &&
          (event.latitude != 0 || event.longitude != 0)) {
        try {
          final reverseApi = ref.read(mapboxReverseGeocodingApiProvider);
          resolvedPlace = await reverseApi.reverseGeocode(
            latitude: event.latitude,
            longitude: event.longitude,
          );
        } catch (e, st) {
          AppLogger.error(
            'Failed to reverse geocode event location',
            tag: 'EventDetails',
            error: e,
            stackTrace: st,
          );
          resolvedPlace = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _event = event;
        _reservationSummary = reservationSummary;
        _comments = commentsPage.items;
        _organizerProfile = organizerProfile;
        _resolvedPlace = resolvedPlace;
        _currentImageIndex = 0;
      });
    } catch (e, st) {
      AppLogger.error(
        'Failed to load event details',
        tag: 'EventDetails',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load event details.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReplies(AdminComment comment) async {
    if (_loadingRepliesFor.contains(comment.commentId) ||
        _loadedRepliesFor.contains(comment.commentId)) {
      return;
    }

    setState(() {
      _loadingRepliesFor.add(comment.commentId);
    });

    try {
      final page = await _eventsRepository.getCommentReplies(
        commentId: comment.commentId,
        page: 1,
        pageSize: 50,
      );

      if (!mounted) return;

      setState(() {
        _comments = _replaceCommentInTree(
          _comments,
          comment.commentId,
          (target) => target.copyWith(replies: page.items),
        );
        _loadedRepliesFor.add(comment.commentId);
      });
    } catch (e, st) {
      AppLogger.error(
        'Failed to load comment replies',
        tag: 'EventDetails',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _showSnack('Failed to load replies.');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingRepliesFor.remove(comment.commentId);
      });
    }
  }

  Future<void> _toggleReplies(AdminComment comment) async {
    final isExpanded = _expandedReplyThreads.contains(comment.commentId);

    if (isExpanded) {
      setState(() {
        _expandedReplyThreads.remove(comment.commentId);
      });
      return;
    }

    setState(() {
      _expandedReplyThreads.add(comment.commentId);
    });

    if (!_loadedRepliesFor.contains(comment.commentId) &&
        comment.replyCount > 0) {
      await _loadReplies(comment);
    }
  }

  void _showSnack(
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isError
        ? colorScheme.error
        : colorScheme.inverseSurface;

    final foregroundColor = isError
        ? colorScheme.onError
        : colorScheme.onInverseSurface;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          closeIconColor: foregroundColor,
          action: SnackBarAction(
            label: 'Close',
            textColor: foregroundColor,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
  }

  Future<bool> _showDeleteCommentDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Delete comment',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this comment?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                  child: Text(
                    'Cancel',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    'Delete',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<String?> _showEditCommentDialog(AdminComment comment) async {
    final controller = TextEditingController(text: comment.content);
    final formKey = GlobalKey<FormState>();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Edit comment',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Enter updated comment',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.2,
                  ),
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Comment cannot be empty.';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
              ),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: Text(
                'Save',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _editComment(AdminComment comment) async {
    if (_busyCommentIds.contains(comment.commentId)) return;

    final updatedText = await _showEditCommentDialog(comment);

    if (updatedText == null || updatedText == comment.content.trim()) return;

    setState(() {
      _busyCommentIds.add(comment.commentId);
    });

    try {
      final updated = await _eventsRepository.updateComment(
        commentId: comment.commentId,
        content: updatedText,
      );

      if (!mounted) return;

      setState(() {
        _comments = _replaceCommentInTree(
          _comments,
          comment.commentId,
          (_) => updated,
        );
      });

      _showSnack('Comment updated.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to update comment',
        tag: 'EventDetails',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _showSnack('Failed to update comment.', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _busyCommentIds.remove(comment.commentId);
      });
    }
  }

  Future<void> _deleteComment(AdminComment comment) async {
    if (_busyCommentIds.contains(comment.commentId)) return;

    final confirmed = await _showDeleteCommentDialog();
    if (!confirmed) return;

    setState(() {
      _busyCommentIds.add(comment.commentId);
    });

    try {
      await _eventsRepository.deleteComment(commentId: comment.commentId);

      if (!mounted) return;

      setState(() {
        _comments = _markCommentDeletedInTree(_comments, comment.commentId);
      });

      _showSnack('Comment deleted.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete comment',
        tag: 'EventDetails',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _showSnack('Failed to delete comment.', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _busyCommentIds.remove(comment.commentId);
      });
    }
  }

  Future<void> _openUserProfile() async {
    final organizerId = _event?.organizerId;
    if (organizerId == null || organizerId <= 0) return;

    if (widget.onOpenUserProfile != null) {
      widget.onOpenUserProfile!(context, organizerId);
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: organizerId,
          repository: widget.usersRepository,
        ),
      ),
    );
  }

  void _goToPreviousImage() {
    final images = _eventImageUrls;
    if (images.length <= 1) return;

    final target = _currentImageIndex == 0
        ? images.length - 1
        : _currentImageIndex - 1;

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _goToNextImage() {
    final images = _eventImageUrls;
    if (images.length <= 1) return;

    final target = _currentImageIndex == images.length - 1
        ? 0
        : _currentImageIndex + 1;

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  List<String> get _eventImageUrls {
    final event = _event;
    if (event == null) return const [];

    final imageUrls = event.images
        .map((e) => e.imageUrl.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final fallbackUrls = event.imageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return imageUrls.isNotEmpty ? imageUrls : fallbackUrls;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: () => _load(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0x26000000)
                            : const Color(0x14000000),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildBody(
                    colors: colors,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (_isLoading) {
      return SizedBox(
        height: 420,
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event;
    if (event == null) {
      return const SizedBox.shrink();
    }

    final organizer = _organizerProfile;
    final organizerName = organizer?.fullName.trim().isNotEmpty == true
        ? organizer!.fullName
        : event.displayPromoterName;
    final organizerUsername = organizer?.displayUsername ?? '';
    final organizerEmail = organizer?.displayEmail ?? '';
    final organizerAvatarLetter = organizerName.trim().isNotEmpty
        ? organizerName.characters.first.toUpperCase()
        : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Event Details',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Review event information, organizer details, attendance summary, address, and community activity.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        _buildImageCarousel(
          event,
          colors: colors,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _SectionCard(
                title: 'Overview',
                icon: Icons.event_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(
                          label: EventStatus.displayLabel(event.displayStatus),
                          background: EventStatus.displayColor(event.displayStatus).withValues(alpha: 0.12),
                          foreground: EventStatus.displayColor(event.displayStatus),
                        ),
                        _InfoChip(
                          label: event.category,
                          background: colors.inputFill,
                          foreground: colors.textPrimary,
                        ),
                        if (event.isFeatured)
                          _InfoChip(
                            label: 'Featured',
                            background: colorScheme.tertiary.withValues(alpha: 0.12),
                            foreground: colorScheme.tertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.displayTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.displayDescription,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'Date', value: event.dateLabel),
                    _InfoRow(
                      label: 'Price',
                      value: PriceFormatter.formatPriceWithBam(event.price),
                    ),
                    _InfoRow(label: 'Category', value: event.category),
                    _InfoRow(label: 'Locale', value: _fallback(event.locale)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 2,
              child: _OrganizerCard(
                title: 'Organizer',
                organizerName: organizerName,
                organizerUsername: organizerUsername,
                organizerEmail: organizerEmail,
                avatarLetter: organizerAvatarLetter,
                imageUrl: organizer?.imageUrl,
                onOpenProfile: _openUserProfile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionCard(
                title: 'Capacity',
                icon: Icons.confirmation_number_outlined,
                child: _buildCapacityContent(
                  colors: colors,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _SectionCard(
                title: 'Additional Information',
                icon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    _InfoRow(label: 'Tags', value: _fallback(event.tags)),
                    _InfoRow(
                      label: 'Accessibility',
                      value: _fallback(event.accessibilityInfo),
                    ),
                    _InfoRow(
                      label: 'Views',
                      value: event.viewCount.toString(),
                    ),
                    _InfoRow(
                      label: 'Likes',
                      value: event.likesCount.toString(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Address',
          icon: Icons.place_outlined,
          child: Column(
            children: [
              _InfoRow(
                label: 'Place',
                value: _resolvedPlace?.title ??
                    _resolvedPlace?.subtitle ??
                    event.locationLabel,
              ),
              _InfoRow(
                label: 'Full address',
                value: _resolvedPlace?.subtitle ?? event.locationLabel,
              ),
              _InfoRow(
                label: 'Coordinates',
                value:
                    '${event.latitude.toStringAsFixed(5)}, ${event.longitude.toStringAsFixed(5)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Comments',
          icon: Icons.mode_comment_outlined,
          child: _buildCommentsSection(
            colors: colors,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(
    AdminEvent event, {
    required AppThemeColors colors,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final images = _eventImageUrls;

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.borderSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 42,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              'No event images available',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              color: colors.inputFill,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 42,
                                color: colors.textSecondary,
                              ),
                            );
                          },
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.28),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    left: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: _goToPreviousImage,
                      ),
                    ),
                  ),
                if (images.length > 1)
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CarouselArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: _goToNextImage,
                      ),
                    ),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.34),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/${images.length}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              spacing: 8,
              children: List.generate(
                images.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: index == _currentImageIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentImageIndex
                          ? colorScheme.primary
                          : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCapacityContent({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final summary = _reservationSummary;
    final event = _event;

    final occupancyLabel = summary?.occupancyLabel ??
        (event == null ? '-' : '0/${event.capacity}');
    final progress = (summary?.progress ?? 0.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          occupancyLabel,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: colors.inputFill,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(
          label: 'Confirmed',
          value: (summary?.confirmedCount ?? 0).toString(),
        ),
        _InfoRow(
          label: 'Pending',
          value: (summary?.pendingCount ?? 0).toString(),
        ),
        _InfoRow(
          label: 'Available',
          value: summary == null
              ? ((event?.capacity ?? 0).toString())
              : summary.availableCount.toString(),
        ),
      ],
    );
  }

  Widget _buildCommentsSection({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (_comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderSoft),
        ),
        child: Text(
          'No comments yet.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: _comments
          .map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCommentCard(
                comment,
                colors: colors,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCommentCard(
    AdminComment comment, {
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    int depth = 0,
  }) {
    final isBusy = _busyCommentIds.contains(comment.commentId);
    final canExpandReplies = comment.replyCount > 0;
    final isExpanded = _expandedReplyThreads.contains(comment.commentId);
    final isLoadingReplies = _loadingRepliesFor.contains(comment.commentId);
    final avatarLetter = comment.authorLabel.trim().isNotEmpty
        ? comment.authorLabel.characters.first.toUpperCase()
        : 'U';

    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.card,
                  backgroundImage: (comment.avatarUrl?.trim().isNotEmpty ?? false)
                      ? NetworkImage(comment.avatarUrl!.trim())
                      : null,
                  child: (comment.avatarUrl?.trim().isNotEmpty ?? false)
                      ? null
                      : Text(
                          avatarLetter,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorLabel,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        comment.updatedAt?.formatEventDateTime() ??
                            comment.createdAt.formatEventDateTime(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!comment.isDeleted)
                  PopupMenuButton<String>(
                    enabled: !isBusy,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editComment(comment);
                      } else if (value == 'delete') {
                        _deleteComment(comment);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              comment.isDeleted ? 'This comment was deleted.' : comment.content,
              style: textTheme.bodyMedium?.copyWith(
                color: comment.isDeleted
                    ? colors.textSecondary
                    : colors.textPrimary,
                fontStyle:
                    comment.isDeleted ? FontStyle.italic : FontStyle.normal,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Likes: ${comment.likesCount}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (canExpandReplies)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: isLoadingReplies ? null : () => _toggleReplies(comment),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        isExpanded
                            ? 'Hide replies'
                            : 'Show replies (${comment.replyCount})',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (isBusy)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 14),
              if (isLoadingReplies)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (comment.replies.isEmpty)
                Text(
                  'No replies.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                ...comment.replies.map(
                  (reply) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildCommentCard(
                      reply,
                      colors: colors,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                      depth: depth + 1,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _fallback(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? 'Not provided' : normalized;
  }

  List<AdminComment> _replaceCommentInTree(
    List<AdminComment> comments,
    int commentId,
    AdminComment Function(AdminComment comment) transform,
  ) {
    return comments
        .map((comment) {
          if (comment.commentId == commentId) {
            return transform(comment);
          }

          if (comment.replies.isEmpty) return comment;

          return comment.copyWith(
            replies: _replaceCommentInTree(comment.replies, commentId, transform),
          );
        })
        .toList(growable: false);
  }

  List<AdminComment> _markCommentDeletedInTree(
    List<AdminComment> comments,
    int commentId,
  ) {
    return comments
        .map((comment) {
          if (comment.commentId == commentId) {
            return comment.copyWith(
              content: '',
              isDeleted: true,
              updatedAt: DateTime.now().toUtc(),
            );
          }

          if (comment.replies.isEmpty) return comment;

          return comment.copyWith(
            replies: _markCommentDeletedInTree(comment.replies, commentId),
          );
        })
        .toList(growable: false);
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({
    required this.title,
    required this.organizerName,
    required this.organizerUsername,
    required this.organizerEmail,
    required this.avatarLetter,
    required this.imageUrl,
    required this.onOpenProfile,
  });

  final String title;
  final String organizerName;
  final String organizerUsername;
  final String organizerEmail;
  final String avatarLetter;
  final String? imageUrl;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.inputFill,
                backgroundImage:
                    (imageUrl?.trim().isNotEmpty ?? false) ? NetworkImage(imageUrl!.trim()) : null,
                child: (imageUrl?.trim().isNotEmpty ?? false)
                    ? null
                    : Text(
                        avatarLetter,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizerName.trim().isEmpty ? 'Unknown user' : organizerName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (organizerUsername.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        organizerUsername,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (organizerEmail.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        organizerEmail,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Open the full organizer profile from here.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenProfile,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  const _CarouselArrowButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}