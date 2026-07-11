import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_icon_circle_button.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/bookmarks/application/bookmark_controller.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/providers/chat_providers.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../../shared/location/models/event_directions_request.dart';
import '../../../../shared/location/providers/directions_providers.dart';
import '../../../../shared/location/providers/location_providers.dart';
import '../../../../shared/payment/models/payment_summary.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../../../shared/tickets/models/ticket_models.dart';
import '../../../../shared/tickets/providers/ticket_providers.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../comments/presentation/widgets/inline_event_comments_section.dart';
import '../../../payment/presentation/screens/payment_screen.dart';
import '../../../public_profile/application/public_profile_controller.dart';
import '../../../public_profile/presentation/screens/public_profile_screen.dart';
import '../../../reports/presentation/screens/report_screen.dart';
import '../../application/event_details_controller.dart';
import '../widgets/event_capacity_card.dart';
import '../widgets/event_gallery.dart';
import '../widgets/event_header.dart';
import '../widgets/event_info_section.dart';
import '../widgets/event_share.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final VoidCallback? onCloseParentSearchSheet;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.onCloseParentSearchSheet,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

enum ReserveAvailabilityReason {
  available,
  loading,
  noTicketsConfigured,
  soldOut,
  salesNotStarted,
  salesEnded,
  inactive,
  unavailable,
}

class ReserveAvailabilityState {
  final ReserveAvailabilityReason reason;
  final EventTicketItem? ticket;
  final String message;
  final String buttonLabel;
  final bool canReserve;

  const ReserveAvailabilityState({
    required this.reason,
    required this.message,
    required this.buttonLabel,
    required this.canReserve,
    this.ticket,
  });

  factory ReserveAvailabilityState.loading() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.loading,
      message: 'Checking ticket availability...',
      buttonLabel: 'Checking...',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.noTicketsConfigured() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.noTicketsConfigured,
      message: 'No tickets have been configured for this event.',
      buttonLabel: 'Unavailable',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.soldOut() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.soldOut,
      message: 'This event is sold out.',
      buttonLabel: 'Sold out',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.salesNotStarted() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.salesNotStarted,
      message: 'Ticket sales have not started yet.',
      buttonLabel: 'Not on sale',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.salesEnded() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.salesEnded,
      message: 'Ticket sales have ended.',
      buttonLabel: 'Sales ended',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.inactive() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.inactive,
      message: 'Tickets are currently inactive.',
      buttonLabel: 'Unavailable',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.unavailable() {
    return const ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.unavailable,
      message: 'Tickets are currently unavailable.',
      buttonLabel: 'Unavailable',
      canReserve: false,
    );
  }

  factory ReserveAvailabilityState.available(EventTicketItem ticket) {
    final isFree = ticket.price <= 0;
    return ReserveAvailabilityState(
      reason: ReserveAvailabilityReason.available,
      message: isFree
          ? 'Free spot available.'
          : 'Ticket available for ${ticket.price.toStringAsFixed(2)} BAM.',
      buttonLabel: isFree ? 'Reserve free spot' : 'Reserve',
      canReserve: true,
      ticket: ticket,
    );
  }
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  bool _reserveLoading = false;
  bool _availabilityLoading = false;
  bool _reservationDataLoading = false;
  bool _bookmarkBusy = false;
  bool _likeBusy = false;

  List<EventAttendeeItem> _attendees = [];
  List<EventTicketItem> _tickets = const [];

  int _publicReservedCount = 0;
  int _publicCapacity = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(bookmarksProvider.notifier).loadInitial(),
        ref.read(likedEventsProvider.notifier).loadInitial(),
        _loadReservationData(),
        _loadTickets(),
      ]);
    });
  }

  Future<void> _loadReservationData() async {
    final ticketsRepository = ref.read(ticketsRepositoryProvider);

    if (mounted) {
      setState(() => _reservationDataLoading = true);
    }

    List<EventAttendeeItem> attendees = [];
    int reservedCount = 0;
    int totalCount = 0;

    try {
      final tickets = await ticketsRepository.getEventTickets(widget.eventId);
      reservedCount = tickets.fold<int>(0, (sum, t) => sum + t.soldQuantity);
      totalCount = tickets.fold<int>(0, (sum, t) => sum + t.totalQuantity);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load tickets summary.',
        tag: 'EventDetailsScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final attendeeResponse =
          await ticketsRepository.getEventAttendees(widget.eventId);
      attendees = attendeeResponse.items;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load attendees.',
        tag: 'EventDetailsScreen',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) return;

    setState(() {
      _attendees = attendees;
      _publicReservedCount = reservedCount;
      _publicCapacity = totalCount;
      _reservationDataLoading = false;
    });
  }

  Future<void> _loadTickets() async {
    if (mounted) {
      setState(() => _availabilityLoading = true);
    }

    try {
      final ticketsRepository = ref.read(ticketsRepositoryProvider);
      final tickets = await ticketsRepository.getEventTickets(widget.eventId);

      if (!mounted) return;
      setState(() {
        _tickets = tickets;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load tickets.',
        tag: 'EventDetailsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _tickets = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _availabilityLoading = false);
      }
    }
  }

  List<String> buildGallery(EventItem item) {
    final urls = <String>[
      if (item.coverImageUrl?.trim().isNotEmpty == true)
        item.coverImageUrl!.trim(),
      ...item.imageUrls.map((e) => e.trim()),
    ];

    final seen = <String>{};
    return urls.where((e) {
      if (e.isEmpty || seen.contains(e)) return false;
      seen.add(e);
      return true;
    }).toList();
  }

  String formatDateRange(EventItem item) {
    final start = item.startDateTime;
    final end = item.endDateTime;

    if (start.isSameDate(end)) {
      return '${start.formatDate(pattern: 'EEE')}, ${start.formatDate(pattern: 'dd.MM.yyyy.')}';
    }

    return '${start.formatDate(pattern: 'dd.MM.yyyy.')} - ${end.formatDate(pattern: 'dd.MM.yyyy.')}';
  }

  String formatTimeRange(EventItem item) {
    return '${item.startDateTime.formatTime()} - ${item.endDateTime.formatTime()}';
  }

  String countdownText(EventItem item) {
    final now = DateTime.now();
    final start = item.startDateTime.toLocal();

    if (!start.isAfter(now)) {
      return 'Event started or finished';
    }

    final diff = start.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return 'Starts in $days days, $hours hours';
    if (hours > 0) return 'Starts in $hours hours, $minutes minutes';
    if (minutes > 0) return 'Starts in $minutes minutes';
    return 'Starts soon';
  }

  String _fallbackLocation(EventItem item) {
    return '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}';
  }

  String _resolvedLocation(MapboxPlace? place, EventItem item) {
    if (place == null) return _fallbackLocation(item);

    final subtitle = place.subtitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) {
      return subtitle;
    }

    final title = place.title.trim();
    if (title.isNotEmpty) return title;

    return _fallbackLocation(item);
  }

  void openDirections(EventItem item, WidgetRef ref) {
    final activeNavigation = ref.read(activeNavigationProvider);

    if (activeNavigation?.eventId == item.eventId) {
      widget.onCloseParentSearchSheet?.call();
      Navigator.of(context).maybePop();
      return;
    }

    ref.read(pendingDirectionsProvider.notifier).state = EventDirectionsRequest(
      eventId: item.eventId,
      latitude: item.latitude,
      longitude: item.longitude,
      title: item.title,
    );

    widget.onCloseParentSearchSheet?.call();
    Navigator.of(context).maybePop();
  }

  Future<void> openDirectChat({
    required BuildContext context,
    required WidgetRef ref,
    required int otherUserId,
  }) async {
    final userIdError = Validators.selectionRequired<int>(
      otherUserId,
      fieldName: 'Recipient',
    );
    if (userIdError != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userIdError)),
      );
      return;
    }

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
              title: result['title'] as String? ?? 'Chat',
              otherUserId: (result['otherUserId'] as num?)?.toInt(),
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to open direct chat.',
        tag: 'EventDetailsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toMessage(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Could not open chat.',
            ),
          ),
        ),
      );
    }
  }

  void openOwnerProfile(EventItem item) {
    final organizerId = item.organizerId;
    if (organizerId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: organizerId),
      ),
    );
  }

  void _openUserProfile(int userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: userId),
      ),
    );
  }

  ReserveAvailabilityState _buildReserveState(List<EventTicketItem> tickets) {
    if (_availabilityLoading) {
      return ReserveAvailabilityState.loading();
    }

    if (tickets.isEmpty) {
      return ReserveAvailabilityState.noTicketsConfigured();
    }

    final now = DateTime.now();
    final sortedTickets = [...tickets]..sort((a, b) => a.price.compareTo(b.price));

    final directlyAvailable = sortedTickets
        .where((t) => t.isAvailable && t.availableQuantity > 0)
        .toList();

    if (directlyAvailable.isNotEmpty) {
      return ReserveAvailabilityState.available(directlyAvailable.first);
    }

    final hasStock = sortedTickets.any((t) => t.availableQuantity > 0);
    final anyActive = sortedTickets.any((t) => t.isActive);

    final hasUpcomingSales = sortedTickets.any((t) {
      final start = t.saleStartDate;
      return t.isActive &&
          t.availableQuantity > 0 &&
          start != null &&
          now.isBefore(start);
    });

    if (hasUpcomingSales) {
      return ReserveAvailabilityState.salesNotStarted();
    }

    final hasEndedSales = sortedTickets.any((t) {
      final end = t.saleEndDate;
      return t.isActive &&
          t.availableQuantity > 0 &&
          end != null &&
          now.isAfter(end);
    });

    if (hasEndedSales) {
      return ReserveAvailabilityState.salesEnded();
    }

    if (hasStock && !anyActive) {
      return ReserveAvailabilityState.inactive();
    }

    if (!hasStock) {
      return ReserveAvailabilityState.soldOut();
    }

    return ReserveAvailabilityState.unavailable();
  }

  Future<void> _openAttendeesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final attendees = _attendees;

        return AppBottomSheetContainer(
          maxHeightFactor: 0.94,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${attendees.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          child: _reservationDataLoading
              ? const AppLoadingIndicator(
                  title: 'Loading attendees',
                  message: 'Please wait while we fetch the attendee list.',
                  centered: false,
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                )
              : attendees.isEmpty
                  ? const AppEmptyState(
                      title: 'No attendees yet',
                      message: 'Attendees will appear here after reservations.',
                      icon: Icons.people_outline_rounded,
                      padding: EdgeInsets.all(24),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attendees.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final attendee = attendees[index];
                        final username = attendee.username.trim().isNotEmpty
                            ? attendee.username.trim()
                            : 'User ${attendee.userId}';
                        final avatarUrl = attendee.avatarUrl?.trim();

                        return AppSurfaceCard(
                          onTap: () {
                            Navigator.of(context).pop();
                            _openUserProfile(attendee.userId);
                          },
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    avatarUrl != null && avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                child: avatarUrl == null || avatarUrl.isEmpty
                                    ? Text(
                                        username.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      attendee.quantity > 1
                                          ? '${attendee.quantity} tickets'
                                          : '1 ticket',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }

  Future<void> openReportEventScreen(EventItem item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetType: ReportTargetType.event,
          targetId: item.eventId,
          targetTitle: item.title,
          targetSubtitle: [item.segmentName, item.genreName]
              .where((e) => e != null && e.trim().isNotEmpty)
              .join(' • '),
          targetImageUrl: item.coverImageUrl,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for the report.')),
      );
    }
  }

  Future<void> reserve(EventItem item) async {
    if (_reserveLoading) return;

    final currentUserId = ref.read(authStateProvider).user?.userId;
    final isOwnEvent =
        currentUserId != null &&
        item.organizerId != null &&
        currentUserId == item.organizerId;

    if (isOwnEvent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot reserve your own event.')),
      );
      return;
    }

    final reserveState = _buildReserveState(_tickets);
    if (!reserveState.canReserve || reserveState.ticket == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reserveState.message)),
      );
      return;
    }

    final organizerError = Validators.selectionRequired<int?>(
      item.organizerId,
      fieldName: 'Organizer',
    );
    if (organizerError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(organizerError)),
      );
      return;
    }

    setState(() => _reserveLoading = true);

    try {
      final ticketsRepository = ref.read(ticketsRepositoryProvider);

      final latestTickets = await ticketsRepository.getEventTickets(item.eventId);
      if (mounted) {
        setState(() {
          _tickets = latestTickets;
        });
      }

      final latestReserveState = _buildReserveState(latestTickets);
      if (!latestReserveState.canReserve || latestReserveState.ticket == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(latestReserveState.message)),
        );
        return;
      }

      final selectedTicket = latestReserveState.ticket!;

      if (!mounted) return;

      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            eventId: item.eventId,
            organizerId: item.organizerId,
            summary: PaymentSummary(
              eventId: item.eventId,
              eventTitle: item.title,
              eventImageUrl: item.coverImageUrl,
              eventTicketId: selectedTicket.ticketId,
              ticketType: selectedTicket.ticketType,
              quantity: 1,
              unitPrice: selectedTicket.price,
              serviceFee: 0,
              currency: 'BAM',
              ownerName: item.promoterName,
              categoryName:
                  item.segmentName ?? item.genreName ?? item.subGenreName,
              eventDescription: item.description,
            ),
          ),
        ),
      );

      if (!mounted) return;

      if (success == true) {
        await _loadReservationData();
        await _loadTickets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation confirmed successfully.')),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reservation flow failed.',
        tag: 'EventDetailsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toMessage(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Could not start reservation flow.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reserveLoading = false);
      }
    }
  }

  Future<void> openShareSheet(EventItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final location = _resolvedLocation(
          ref.watch(
            reverseGeocodedPlaceProvider(
              (latitude: item.latitude, longitude: item.longitude),
            ),
          ).maybeWhen(
                data: (place) => place,
                orElse: () => null,
              ),
          item,
        );

        return EventShareSheet(
          item: item,
          onCopyLink: () async {
            try {
              final link = buildEventShareLink(item);
              await Clipboard.setData(ClipboardData(text: link));
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event link copied.')),
              );
            } catch (error, stackTrace) {
              AppLogger.error(
                'Failed to copy event link.',
                tag: 'EventDetailsScreen',
                error: error,
                stackTrace: stackTrace,
              );

              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ErrorMapper.toMessage(
                      error,
                      stackTrace: stackTrace,
                      fallbackMessage: 'Could not copy event link.',
                    ),
                  ),
                ),
              );
            }
          },
          onSystemShare: () async {
            try {
              final text = buildEventShareText(item, location);
              await SharePlus.instance.share(
                ShareParams(
                  text: text,
                  subject: item.title,
                ),
              );
              if (!mounted) return;
              Navigator.of(context).pop();
            } catch (error, stackTrace) {
              AppLogger.error(
                'Failed to share event.',
                tag: 'EventDetailsScreen',
                error: error,
                stackTrace: stackTrace,
              );

              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ErrorMapper.toMessage(
                      error,
                      stackTrace: stackTrace,
                      fallbackMessage: 'Could not share event.',
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  String buildEventShareLink(EventItem item) {
    return 'https://your-domain.com/events/${item.eventId}';
  }

  String buildEventShareText(EventItem item, String resolvedLocation) {
    final date = formatDateRange(item);
    final time = formatTimeRange(item);

    return [
      item.title,
      if (item.segmentName?.trim().isNotEmpty == true) item.segmentName!.trim(),
      '$date • $time',
      resolvedLocation,
      buildEventShareLink(item),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final state = ref.watch(eventDetailsControllerProvider(widget.eventId));
    final controller =
        ref.read(eventDetailsControllerProvider(widget.eventId).notifier);
    final bookmarksState = ref.watch(bookmarksProvider);
    final bookmarksController = ref.read(bookmarksProvider.notifier);
    final likedState = ref.watch(likedEventsProvider);
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.userId;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const AppLoadingIndicator(
          title: 'Loading event',
          message: 'Please wait while we prepare the event details.',
        ),
      );
    }

    if (state.hasError || state.event == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(),
        body: AppErrorState(
          title: 'Failed to load event',
          message: state.error?.trim().isNotEmpty == true
              ? state.error!.trim()
              : 'Could not load event details.',
          retryLabel: 'Try again',
          onRetry: () => controller.refresh(),
        ),
      );
    }

    final item = state.event!;
    final isOwnEvent =
        currentUserId != null &&
        item.organizerId != null &&
        currentUserId == item.organizerId;
    final isLiked = likedState.items.any((e) => e.eventId == item.eventId);
    final isBookmarked =
        bookmarksState.items.any((b) => b.eventId == item.eventId);
    final gallery = buildGallery(item);

    final ownerProfileState = item.organizerId != null
        ? ref.watch(publicProfileControllerProvider(item.organizerId!))
        : null;

    final ownerDisplayName = ownerProfileState?.maybeWhen(
              data: (bundle) => bundle.user.fullName.trim().isNotEmpty
                  ? bundle.user.fullName.trim()
                  : null,
              orElse: () => null,
            ) ??
        item.promoterName?.trim();

    final ownerUsername = ownerProfileState?.maybeWhen(
      data: (bundle) => bundle.user.username.trim().isNotEmpty
          ? bundle.user.username.trim()
          : null,
      orElse: () => null,
    );

    final ownerAvatarUrl = ownerProfileState?.maybeWhen(
      data: (bundle) => bundle.user.imageUrl?.trim().isNotEmpty == true
          ? bundle.user.imageUrl!.trim()
          : null,
      orElse: () => null,
    );

    final locationPlace = ref.watch(
      reverseGeocodedPlaceProvider(
        (latitude: item.latitude, longitude: item.longitude),
      ),
    );

    final resolvedLocation = locationPlace.maybeWhen(
      data: (place) => _resolvedLocation(place, item),
      orElse: () => _fallbackLocation(item),
    );

    final capacity = _publicCapacity > 0 ? _publicCapacity : item.capacity;
    final reservedCount = _publicReservedCount;
    final attendeeCount = _attendees.length;

    final previewUsers = _attendees
        .take(5)
        .map(
          (e) => AttendeePreviewUser(
            userId: e.userId,
            label: e.username.trim().isNotEmpty
                ? e.username.trim()
                : 'User ${e.userId}',
            avatarUrl: e.avatarUrl,
          ),
        )
        .toList();

    final reserveState = _buildReserveState(_tickets);
    final effectiveReserveEnabled = !isOwnEvent && reserveState.canReserve;
    final effectiveReserveLabel =
        isOwnEvent ? 'Your event' : reserveState.buttonLabel;
    final muted = theme.textTheme.bodyMedium?.color ??
        scheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    controller.refresh(),
                    ref.read(bookmarksProvider.notifier).refresh(),
                    ref.read(likedEventsProvider.notifier).refresh(),
                    _loadReservationData(),
                    _loadTickets(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    EventHeader(
                      title: item.title,
                      category: item.segmentName ?? item.genreName,
                      subCategory: item.subGenreName,
                      ownerDisplayName: ownerDisplayName,
                      ownerUsername: ownerUsername,
                      ownerAvatarUrl: ownerAvatarUrl,
                      likes: state.event?.likesCount ?? 0,
                      views: item.viewCount,
                      price: item.price,
                      isLiked: isLiked,
                      isBookmarked: isBookmarked,
                      onBack: () => Navigator.of(context).maybePop(),
                      onLikeTap: () async {
                        if (_likeBusy || state.isTogglingLike) return;
                        setState(() => _likeBusy = true);

                        try {
                          if (isLiked) {
                            await controller.unlikeEvent();
                          } else {
                            await controller.likeEvent();
                          }
                        } catch (error, stackTrace) {
                          AppLogger.error(
                            'Failed to toggle event like.',
                            tag: 'EventDetailsScreen',
                            error: error,
                            stackTrace: stackTrace,
                          );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ErrorMapper.toMessage(
                                  error,
                                  stackTrace: stackTrace,
                                  fallbackMessage: 'Could not update like.',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _likeBusy = false);
                          }
                        }
                      },
                      onBookmarkTap: () async {
                        if (_bookmarkBusy) return;
                        setState(() => _bookmarkBusy = true);

                        try {
                          await bookmarksController.toggleBookmark(
                            eventId: item.eventId,
                          );
                        } catch (error, stackTrace) {
                          AppLogger.error(
                            'Failed to toggle bookmark.',
                            tag: 'EventDetailsScreen',
                            error: error,
                            stackTrace: stackTrace,
                          );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ErrorMapper.toMessage(
                                  error,
                                  stackTrace: stackTrace,
                                  fallbackMessage:
                                      'Could not update bookmark.',
                                ),
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _bookmarkBusy = false);
                          }
                        }
                      },
                      onReportTap:
                          isOwnEvent ? null : () => openReportEventScreen(item),
                      onShareTap: () => openShareSheet(item),
                      onOwnerTap: item.organizerId == null
                          ? null
                          : () => openOwnerProfile(item),
                    ),
                    const SizedBox(height: 18),
                    EventGallery(imageUrls: gallery),
                    const SizedBox(height: 18),
                    if (_reservationDataLoading)
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: const AppLoadingIndicator(
                          title: 'Loading attendance',
                          message: 'Loading attendees and capacity...',
                          padding: EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 12,
                          ),
                        ),
                      )
                    else
                      EventCapacityCard(
                        capacity: capacity,
                        reservedCount: reservedCount,
                        attendeeCount: attendeeCount,
                        previewUsers: previewUsers,
                        onViewAttendeesTap: _openAttendeesSheet,
                      ),
                    const SizedBox(height: 18),
                    EventInfoSection(
                      location: resolvedLocation,
                      dateText: formatDateRange(item),
                      timeText: formatTimeRange(item),
                      countdownText: countdownText(item),
                      description: item.description,
                      capacity: capacity,
                      participantCount: attendeeCount,
                      tags: item.tags,
                      accessibilityInfo: item.accessibilityInfo,
                      onDirectionsTap: () => openDirections(item, ref),
                    ),
                    const SizedBox(height: 12),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(14),
                      child: _availabilityLoading
                          ? const AppLoadingIndicator(
                              title: 'Checking availability',
                              message: 'Checking ticket availability...',
                              centered: false,
                              padding: EdgeInsets.zero,
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  effectiveReserveEnabled
                                      ? Icons.confirmation_number_outlined
                                      : Icons.info_outline,
                                  color: effectiveReserveEnabled
                                      ? scheme.primary
                                      : muted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isOwnEvent
                                        ? 'You cannot reserve a spot for your own event.'
                                        : reserveState.message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: effectiveReserveEnabled
                                          ? scheme.onSurface
                                          : muted,
                                      fontWeight: effectiveReserveEnabled
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    InlineEventCommentsSection(
                      eventId: item.eventId,
                      currentUserId: currentUserId,
                    ),
                  ],
                ),
              ),
            ),
            BottomBar(
              isReserveLoading: _reserveLoading,
              reserveEnabled: effectiveReserveEnabled,
              reserveLabel: effectiveReserveLabel,
              onChatTap: isOwnEvent || item.organizerId == null
                  ? null
                  : () => openDirectChat(
                        context: context,
                        ref: ref,
                        otherUserId: item.organizerId!,
                      ),
              onReserveTap: () => reserve(item),
              onDirectionsTap: () => openDirections(item, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final VoidCallback? onChatTap;
  final VoidCallback onReserveTap;
  final VoidCallback? onDirectionsTap;
  final bool isReserveLoading;
  final bool reserveEnabled;
  final String reserveLabel;

  const BottomBar({
    super.key,
    required this.onChatTap,
    required this.onReserveTap,
    required this.onDirectionsTap,
    this.isReserveLoading = false,
    required this.reserveEnabled,
    required this.reserveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveOnPressed =
        (!reserveEnabled || isReserveLoading) ? null : onReserveTap;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.24)),
        ),
      ),
      child: Row(
        children: [
          if (onChatTap != null) ...[
            AppIconCircleButton(
              onPressed: onChatTap,
              tooltip: 'Open chat',
              icon: Icons.chat_bubble_outline,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: effectiveOnPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isReserveLoading
                    ? AppSpinner(
                        size: 22,
                        strokeWidth: 2.5,
                        color: theme.colorScheme.onPrimary,
                      )
                    : Text(
                        reserveLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppIconCircleButton(
            onPressed: onDirectionsTap,
            tooltip: 'Open directions',
            icon: Icons.navigation_outlined,
          ),
        ],
      ),
    );
  }
}