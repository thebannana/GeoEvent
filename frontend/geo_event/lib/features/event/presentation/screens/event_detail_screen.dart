import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/bookmarks/providers/bookmark_providers.dart';
import '../../../../shared/chat/models/chat_thread_args.dart';
import '../../../../shared/chat/models/chat_thread_type.dart';
import '../../../../shared/chat/providers/chat_providers.dart';
import '../../../../shared/events/models/create_event_models.dart';
import '../../../../shared/location/models/event_directions_request.dart';
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

  const EventDetailsScreen({
    super.key,
    required this.eventId,
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

  List<EventAttendeeItem> _attendees = [];
  List<EventTicketItem> _tickets = const [];

  int _publicReservedCount = 0;
  int _publicCapacity = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadReservationData();
      await _loadTickets();
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
    } catch (e) {
      debugPrint('Failed to load tickets summary: $e');
    }

    try {
      final attendeeResponse =
          await ticketsRepository.getEventAttendees(widget.eventId);
      attendees = attendeeResponse.items;
    } catch (e) {
      debugPrint('Failed to load attendees: $e');
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
    } catch (_) {
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
      if (item.coverImageUrl?.trim().isNotEmpty == true) item.coverImageUrl!.trim(),
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
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) {
      return '${weekday(start)}, ${start.day}.${start.month}.${start.year}.';
    }

    return '${start.day}.${start.month}.${start.year}. - ${end.day}.${end.month}.${end.year}.';
  }

  String formatTimeRange(EventItem item) {
    final start = item.startDateTime;
    final end = item.endDateTime;
    return '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
  }

  String countdownText(EventItem item) {
    final now = DateTime.now();
    final diff = item.startDateTime.difference(now);

    if (diff.isNegative) return 'Event started or finished';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) return 'Starts in $days days, $hours hours';
    if (hours > 0) return 'Starts in $hours hours, $minutes minutes';
    return 'Starts in $minutes minutes';
  }

  String weekday(DateTime dt) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[dt.weekday - 1];
  }

  String two(int value) => value.toString().padLeft(2, '0');

  void openDirections(EventItem item) {
    Navigator.of(context).pop(
      EventDirectionsRequest(
        eventId: item.eventId,
        latitude: item.latitude,
        longitude: item.longitude,
        title: item.title,
      ),
    );
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
      return DraggableScrollableSheet(
        initialChildSize: 0.52,
        minChildSize: 0.32,
        maxChildSize: 0.94,
        expand: false,
        snap: true,
        snapSizes: const [0.32, 0.52, 0.94],
        builder: (context, scrollController) {
          final attendees = _attendees;

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF17191D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Attendees',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${attendees.length}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (_reservationDataLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoadingIndicator(
                        message: 'Loading attendees...',
                      ),
                    )
                  else if (attendees.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No attendees yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: attendees.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final attendee = attendees[index];
                          final username = attendee.username.trim().isNotEmpty
                              ? attendee.username.trim()
                              : 'User ${attendee.userId}';
                          final avatarUrl = attendee.avatarUrl?.trim();

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              Navigator.of(context).pop();
                              _openUserProfile(attendee.userId);
                            },
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white12,
                              backgroundImage:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      username.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              attendee.quantity > 1
                                  ? '${attendee.quantity} tickets'
                                  : '1 ticket',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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

    final reserveState = _buildReserveState(_tickets);
    if (!reserveState.canReserve || reserveState.ticket == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reserveState.message)),
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
    } on DioException catch (e) {
      final message = _readDioMessage(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start reservation flow.')),
      );
    } finally {
      if (mounted) {
        setState(() => _reserveLoading = false);
      }
    }
  }

  String _readDioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (e.response?.statusCode == 401) {
      return 'Please sign in to reserve tickets.';
    }
    if (e.response?.statusCode == 409) {
      return 'This ticket is no longer available.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> openShareSheet(EventItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EventShareSheet(
        item: item,
        onCopyLink: () async {
          final link = buildEventShareLink(item);
          await Clipboard.setData(ClipboardData(text: link));
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event link copied.')),
          );
        },
        onSystemShare: () async {
          final text = buildEventShareText(item);
          await SharePlus.instance.share(
            ShareParams(
              text: text,
              subject: item.title,
            ),
          );
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      onSendInChat: () {
        Navigator.of(context).pop();
        openDirectChat(
          context: context,
          ref: ref,
          otherUserId: item.organizerId!,
        );
      },
      ),
    );
  }

  String buildEventShareLink(EventItem item) {
    return 'https://your-domain.com/events/${item.eventId}';
  }

  String buildEventShareText(EventItem item) {
    final date = formatDateRange(item);
    final time = formatTimeRange(item);
    final location = item.isOnline
        ? 'Online event'
        : (item.venueName?.trim().isNotEmpty == true
            ? item.venueName!.trim()
            : 'Location TBA');

    return [
      item.title,
      if (item.segmentName?.trim().isNotEmpty == true) item.segmentName!.trim(),
      '$date • $time',
      location,
      buildEventShareLink(item),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventDetailsControllerProvider(widget.eventId));
    final controller =
        ref.read(eventDetailsControllerProvider(widget.eventId).notifier);
    final bookmarksState = ref.watch(bookmarksProvider);
    final bookmarksController = ref.read(bookmarksProvider.notifier);
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.userId;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1014),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasError || state.event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1014),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.error ?? 'Failed to load event.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final item = state.event!;
    final isLiked = item.isLiked;
    final isBookmarked =
        bookmarksState.valueOrNull?.any((b) => b.eventId == item.eventId) ?? false;
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
      data: (bundle) =>
          bundle.user.username.trim().isNotEmpty ? bundle.user.username.trim() : null,
      orElse: () => null,
    );

    final ownerAvatarUrl = ownerProfileState?.maybeWhen(
      data: (bundle) => bundle.user.imageUrl?.trim().isNotEmpty == true
          ? bundle.user.imageUrl!.trim()
          : null,
      orElse: () => null,
    );

    final capacity = _publicCapacity > 0 ? _publicCapacity : item.capacity;
    final reservedCount = _publicReservedCount;
    final attendeeCount = _attendees.length;

    final previewUsers = _attendees
        .take(5)
        .map(
          (e) => AttendeePreviewUser(
            userId: e.userId,
            label: e.username.trim().isNotEmpty ? e.username.trim() : 'User ${e.userId}',
            avatarUrl: e.avatarUrl,
          ),
        )
        .toList();

    final reserveState = _buildReserveState(_tickets);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: Stack(
        children: [
          if (gallery.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                gallery.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    const Color(0xFF0F1014).withValues(alpha: 0.82),
                    const Color(0xFF0F1014),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.refresh();
                      await _loadReservationData();
                      await _loadTickets();
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
                          likes: item.likesCount,
                          views: item.viewCount,
                          price: item.price,
                          isLiked: isLiked,
                          isBookmarked: isBookmarked,
                          onBack: () => Navigator.of(context).maybePop(),
                          onLikeTap: () async {
                            try {
                              if (isLiked) {
                                await controller.unlikeEvent();
                              } else {
                                await controller.likeEvent();
                              }
                            } catch (_) {}
                          },
                          onBookmarkTap: () async {
                            await bookmarksController.toggleBookmark(
                              eventId: item.eventId,
                            );
                          },
                          onReportTap: () => openReportEventScreen(item),
                          onShareTap: () => openShareSheet(item),
                          onOwnerTap: item.organizerId == null
                              ? null
                              : () => openOwnerProfile(item),
                        ),
                        const SizedBox(height: 18),
                        EventGallery(imageUrls: gallery),
                        const SizedBox(height: 18),
                        if (_reservationDataLoading)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const AppLoadingIndicator(
                              size: 26,
                              strokeWidth: 2.6,
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
                          location: item.isOnline ? 'Online event' : item.venueName,
                          dateText: formatDateRange(item),
                          timeText: formatTimeRange(item),
                          countdownText: countdownText(item),
                          description: item.description,
                          capacity: capacity,
                          participantCount: attendeeCount,
                          isOnline: item.isOnline,
                          tags: item.tags,
                          accessibilityInfo: item.accessibilityInfo,
                          onDirectionsTap:
                              item.isOnline ? null : () => openDirections(item),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _availabilityLoading
                              ? const AppLoadingIndicator(
                                  size: 22,
                                  strokeWidth: 2.4,
                                  message: 'Checking ticket availability...',
                                  centered: false,
                                  padding: EdgeInsets.zero,
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      reserveState.canReserve
                                          ? Icons.confirmation_number_outlined
                                          : Icons.info_outline,
                                      color: reserveState.canReserve
                                          ? const Color(0xFF63B3ED)
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        reserveState.message,
                                        style: TextStyle(
                                          color: reserveState.canReserve
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: reserveState.canReserve
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (item.externalUrl != null &&
                            item.externalUrl!.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Colors.white70),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.externalUrl!,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  reserveEnabled: reserveState.canReserve,
                  reserveLabel: reserveState.buttonLabel,
                  onChatTap: () => openDirectChat(          
                    context: context,
                    ref: ref,
                    otherUserId: item.organizerId!,),
                  onReserveTap: () => reserve(item),
                  onDirectionsTap: item.isOnline ? null : () => openDirections(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final VoidCallback onChatTap;
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
    final effectiveOnPressed =
        (!reserveEnabled || isReserveLoading) ? null : onReserveTap;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          ActionIcon(
            icon: Icons.chat_bubble_outline,
            onTap: onChatTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: effectiveOnPressed,
                style: ButtonStyle(
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return const Color(0xFF3A3F46);
                    }
                    return const Color(0xFF3B82C4);
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.white70;
                    }
                    return Colors.white;
                  }),
                ),
                child: isReserveLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        reserveLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ActionIcon(
            icon: Icons.navigation_outlined,
            onTap: onDirectionsTap,
          ),
        ],
      ),
    );
  }
}

class ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ActionIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: onTap == null ? Colors.white30 : Colors.white,
          ),
        ),
      ),
    );
  }
}