import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/event_reservations/models/event_reservations_state.dart';
import '../../../../shared/event_reservations/models/organizer_reservation.dart';
import '../../../../shared/event_reservations/providers/event_reservations_providers.dart';
import '../../../../shared/my_events/models/my_event_response_dto.dart';
import '../../../../shared/profile/data/public_users_api.dart';
import '../../../../shared/profile/models/public_user_profile.dart';
import '../../../../shared/reservations/models/reservation_status.dart';
import '../../../profile/presentation/screens/ticket_scanner_screen.dart';
import '../../../public_profile/presentation/screens/public_profile_screen.dart';
import '../widgets/event_reservation_card.dart';
import '../widgets/event_reservations_header_card.dart';
import '../widgets/event_reservations_pagination_footer.dart';
import '../widgets/event_reservations_status_filter_bar.dart';

class EventReservationsScreen extends ConsumerStatefulWidget {
  const EventReservationsScreen({
    super.key,
    required this.event,
  });

  final MyEventResponseDto event;

  @override
  ConsumerState<EventReservationsScreen> createState() =>
      _EventReservationsScreenState();
}

class _EventReservationsScreenState
    extends ConsumerState<EventReservationsScreen> {
  static const int _nextPageTriggerOffset = 280;

  late final ScrollController _scrollController;
  final Debouncer _filterDebouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );

  final Map<int, PublicUserProfileDto> _profilesByUserId = {};

  bool _loadingProfiles = false;
  bool _didRequestInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didRequestInitialLoad) return;
    _didRequestInitialLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(
            eventReservationsControllerProvider(widget.event.eventId).notifier,
          )
          .loadInitial(
            status: ReservationStatus.confirmed,
          );

      await _loadMissingProfiles();
    });
  }

void _showSnackBarMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _showMappedError(
  BuildContext context, {
  required Object error,
  required StackTrace stackTrace,
  required String fallbackMessage,
  required String tag,
}) {
  AppLogger.error(
    fallbackMessage,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );

  if (!context.mounted) return;

  _showSnackBarMessage(
    context,
    ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: fallbackMessage,
    ),
  );
}

  void _onScroll() {
  if (!_scrollController.hasClients) {
    return;
  }

  final state = ref.read(
    eventReservationsControllerProvider(
      widget.event.eventId,
    ),
  );

  if (state.isInitialLoading ||
      state.isLoadingMore ||
      !state.hasNextPage) {
    return;
  }

  final position = _scrollController.position;

  final shouldLoadNextPage =
      position.pixels >=
          position.maxScrollExtent -
              _nextPageTriggerOffset;

  if (!shouldLoadNextPage) {
    return;
  }

  ref
      .read(
        eventReservationsControllerProvider(
          widget.event.eventId,
        ).notifier,
      )
      .loadNextPage()
      .then((_) {
        if (mounted) {
          return _loadMissingProfiles();
        }
      });
}

  Future<void> _loadMissingProfiles() async {
    if (!mounted || _loadingProfiles) return;

    final state =
        ref.read(eventReservationsControllerProvider(widget.event.eventId));

    final userIds = state.items.map((e) => e.userId).toSet().toList();
    final missingIds = userIds
        .where((userId) => !_profilesByUserId.containsKey(userId))
        .toList(growable: false);

    if (missingIds.isEmpty) return;

    _loadingProfiles = true;
    try {
      final profiles =
          await ref.read(publicUsersApiProvider).getPublicProfiles(missingIds);

      if (!mounted) return;

      setState(() {
        _profilesByUserId.addAll(profiles);
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load missing public profiles.',
        tag: 'EventReservationsScreen',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _loadingProfiles = false;
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(
          eventReservationsControllerProvider(widget.event.eventId).notifier,
        )
        .refresh();

    if (!mounted) return;
    await _loadMissingProfiles();
  }

  void _onFilterSelected(ReservationStatus? status) {
    _filterDebouncer.run(() async {
      await ref
          .read(
            eventReservationsControllerProvider(widget.event.eventId).notifier,
          )
          .applyStatusFilter(status);

      if (!mounted) return;

      setState(() {
        _profilesByUserId.clear();
      });

      await _loadMissingProfiles();

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _filterDebouncer.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState =
        ref.watch(eventReservationsControllerProvider(widget.event.eventId));

    ref.listen<EventReservationsState>(
      eventReservationsControllerProvider(widget.event.eventId),
      (previous, next) {
        final previousCount = previous?.items.length ?? 0;
        final nextCount = next.items.length;

        if (nextCount > previousCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadMissingProfiles();
          });
        }
      },
    );

    final reservations = controllerState.items;
    final totalTickets = reservations.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Attendees'),
        actions: [
          IconButton(
            tooltip: 'Open ticket scanner',
            onPressed: () async {
              final didValidate = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TicketScannerScreen(
                    eventId: widget.event.eventId,
                    eventTitle: widget.event.title,
                  ),
                ),
              );

              if (!mounted || didValidate != true) {
                return;
              }

              await _refresh();
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      child: _buildBody(
        context: context,
        ref: ref,
        state: controllerState,
        reservations: reservations,
        totalTickets: totalTickets,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required EventReservationsState state,
    required List<OrganizerReservationDto> reservations,
    required int totalTickets,
  }) {
    if (state.isInitialLoading && state.items.isEmpty) {
      return const AppLoadingIndicator(
        title: 'Loading attendees',
        message: 'Please wait while we fetch the attendee list.',
      );
    }

    if ((state.errorMessage ?? '').trim().isNotEmpty && state.items.isEmpty) {
      return AppErrorState(
        title: 'Failed to load attendees',
        message: state.errorMessage!,
        onRetry: () async {
          await ref
              .read(
                eventReservationsControllerProvider(widget.event.eventId)
                    .notifier,
              )
              .loadInitial(
                status: state.status ?? ReservationStatus.confirmed,
                force: true,
              );

          await _loadMissingProfiles();
        },
      );
    }

    if (reservations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            EventReservationsHeaderCard(
              eventTitle: widget.event.title,
              attendeeCount: 0,
              totalTickets: 0,
              totalReservations: state.totalCount,
            ),
            const SizedBox(height: 12),
            EventReservationsStatusFilterBar(
              selectedStatus: state.status,
              onSelected: _onFilterSelected,
            ),
            const SizedBox(height: 16),
            AppEmptyState(
              title: 'No attendees yet',
              message: 'Attendees for "${widget.event.title}" will appear here.',
              icon: Icons.event_busy_rounded,
            ),
          ],
        ),
      );
    }

    final footerMode = state.isLoadingMore
        ? EventReservationsPaginationMode.loading
        : (!state.hasNextPage && reservations.isNotEmpty)
            ? EventReservationsPaginationMode.end
            : EventReservationsPaginationMode.none;

    final itemCount = reservations.length +
        2 +
        (footerMode == EventReservationsPaginationMode.none ? 0 : 1);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return EventReservationsHeaderCard(
              eventTitle: widget.event.title,
              attendeeCount: reservations.length,
              totalTickets: totalTickets,
              totalReservations: state.totalCount,
            );
          }

          if (index == 1) {
            return EventReservationsStatusFilterBar(
              selectedStatus: state.status,
              onSelected: _onFilterSelected,
            );
          }

          final dataIndex = index - 2;

          if (dataIndex >= reservations.length) {
            return EventReservationsPaginationFooter(mode: footerMode);
          }

          final item = reservations[dataIndex];
          final profile = _profilesByUserId[item.userId];

          final isRemoving = state.removing &&
              state.removingReservationId == item.reservationId;

          final isCollectingCash = state.markingCashCollected &&
              state.cashCollectionReservationId == item.reservationId;

          return EventReservationCard(
            reservation: item,
            profile: profile,
            isRemoving: isRemoving,
            isCollectingCash: isCollectingCash,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    userId: item.userId,
                  ),
                ),
              );

              if (!mounted) {
                return;
              }

              await _refresh();
            },
            onRemove: () => _removeAttendee(context, ref, item),
            onCollectCash: () => _collectCash(context, ref, item),
          );
        },
      ),
    );
  }

  Future<void> _removeAttendee(
  BuildContext context,
  WidgetRef ref,
  OrganizerReservationDto reservation,
) async {
  final confirm = await AppConfirmDialog.show(
    context,
    title: 'Remove attendee?',
    message: 'This will remove the attendee from the event and cancel the reservation for event entry.',
    confirmLabel: 'Remove',
    destructive: true,
  );

  if (!confirm || !context.mounted) return;

  final controller = ref.read(
    eventReservationsControllerProvider(widget.event.eventId).notifier,
  );

  try {
    await controller.removeAttendee(
      reservation.reservationId,
      reason: 'Removed by organizer. Standard refund review required.',
    );

    final state =
        ref.read(eventReservationsControllerProvider(widget.event.eventId));

    if (!context.mounted) return;

    if ((state.errorMessage ?? '').trim().isNotEmpty) {
      _showSnackBarMessage(context, state.errorMessage!.trim());
      return;
    }

    _showSnackBarMessage(context, 'Attendee removed successfully.');
  } catch (error, stackTrace) {
    _showMappedError(
      context,
      error: error,
      stackTrace: stackTrace,
      fallbackMessage: 'Could not remove attendee.',
      tag: 'EventReservationsScreen',
    );
  }
}

  Future<void> _collectCash(
  BuildContext context,
  WidgetRef ref,
  OrganizerReservationDto reservation,
) async {
  final amountLabel = PriceFormatter.format(
    reservation.totalAmount,
    currency: reservation.currency,
  );

  final confirm = await AppConfirmDialog.show(
    context,
    title: 'Mark cash as received?',
    message:
        'This will mark $amountLabel as collected in cash for this attendee.',
    confirmLabel: 'Confirm',
  );

  if (!confirm || !context.mounted) return;

  final controller = ref.read(
    eventReservationsControllerProvider(widget.event.eventId).notifier,
  );

  try {
    await controller.markCashCollected(reservation.reservationId);

    final state =
        ref.read(eventReservationsControllerProvider(widget.event.eventId));

    if (!context.mounted) return;

    if ((state.errorMessage ?? '').trim().isNotEmpty) {
      _showSnackBarMessage(context, state.errorMessage!.trim());
      return;
    }

    _showSnackBarMessage(
      context,
      'Cash payment marked as received.',
    );
  } catch (error, stackTrace) {
    _showMappedError(
      context,
      error: error,
      stackTrace: stackTrace,
      fallbackMessage: 'Could not update cash collection status.',
      tag: 'EventReservationsScreen',
    );
  }
}
}