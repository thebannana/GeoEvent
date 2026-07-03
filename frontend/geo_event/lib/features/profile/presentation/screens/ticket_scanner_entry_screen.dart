import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../application/my_events_controller.dart';
import '../widgets/ticket_scanner_event_card.dart';
import 'ticket_scanner_screen.dart';

class TicketScannerEntryScreen extends ConsumerWidget {
  const TicketScannerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    Future<void> onRefresh() {
      return ref.read(myEventsProvider.notifier).refresh();
    }

    void openScanner(MyEventResponseDto event) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TicketScannerScreen(
            eventId: event.eventId,
            eventTitle: event.title,
          ),
        ),
      );
    }

    final manageableEvents =
        myEventsAsync.valueOrNull?.where((event) => event.canViewReservations).toList() ??
            const <MyEventResponseDto>[];

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Ticket scanner'),
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: AppAsyncView<List<MyEventResponseDto>>(
          value: myEventsAsync,
          onRetry: onRefresh,
          isEmpty: (_) => manageableEvents.isEmpty,
          empty: const _TicketScannerEmptyView(),
          data: (_) => _TicketScannerEntryContent(
            events: manageableEvents,
            onOpenScanner: openScanner,
          ),
        ),
      ),
    );
  }
}

class _TicketScannerEntryContent extends StatelessWidget {
  const _TicketScannerEntryContent({
    required this.events,
    required this.onOpenScanner,
  });

  final List<MyEventResponseDto> events;
  final ValueChanged<MyEventResponseDto> onOpenScanner;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];

        return TicketScannerEventCard(
          event: event,
          onTap: () => onOpenScanner(event),
        );
      },
    );
  }
}

class _TicketScannerEmptyView extends StatelessWidget {
  const _TicketScannerEmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        AppEmptyState(
          icon: Icons.qr_code_scanner_rounded,
          title: 'No scannable events',
          message:
              'There are no events available for reservation scanning at the moment.',
        ),
      ],
    );
  }
}