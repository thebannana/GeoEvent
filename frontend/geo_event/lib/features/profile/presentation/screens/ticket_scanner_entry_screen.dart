import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/my_events/models/my_event_response_dto.dart';
import '../../application/my_events_controller.dart';
import '../widgets/ticket_scanner_event_card.dart';
import 'ticket_scanner_screen.dart';

class TicketScannerEntryScreen extends ConsumerStatefulWidget {
  const TicketScannerEntryScreen({super.key});

  @override
  ConsumerState<TicketScannerEntryScreen> createState() =>
      _TicketScannerEntryScreenState();
}

class _TicketScannerEntryScreenState
    extends ConsumerState<TicketScannerEntryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(myEventsProvider);
      state.whenData((data) {
        if (data.items.isEmpty) {
          ref.read(myEventsProvider.notifier).refresh();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(myEventsProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() {
    return ref.read(myEventsProvider.notifier).refresh();
  }

Future<void> _openScanner(
  BuildContext context,
  MyEventResponseDto event,
) async {
  final didValidate = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => TicketScannerScreen(
        eventId: event.eventId,
        eventTitle: event.title,
      ),
    ),
  );

  if (!mounted || didValidate != true) {
    return;
  }

  await ref.read(myEventsProvider.notifier).refresh();
}

  @override
  Widget build(BuildContext context) {
    final myEventsAsync = ref.watch(myEventsProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Ticket scanner'),
      ),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: AppAsyncView(
          value: myEventsAsync,
          loading: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              AppLoadingIndicator(
                title: 'Loading events',
                message: 'Please wait while we load your scannable events.',
              ),
            ],
          ),
          errorBuilder: (_, _) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                AppErrorState(
                  title: 'Failed to load events',
                  message: 'Pull to refresh or try again.',
                  onRetry: _onRefresh,
                ),
              ],
            );
          },
          data: (state) {
            final events = state.items;

            if (events.isEmpty) {
              return const _TicketScannerEmptyView();
            }

            return ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: events.length + 1,
              separatorBuilder: (_, index) {
                if (index >= events.length - 1) {
                  return const SizedBox(height: 0);
                }
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                if (index == events.length) {
                  return _TicketScannerListFooter(
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    loadedCount: state.items.length,
                    totalCount: state.totalCount,
                    onLoadMore: () =>
                        ref.read(myEventsProvider.notifier).loadMore(),
                  );
                }

                final event = events[index];

                return TicketScannerEventCard(
                  event: event,
                  onTap: () => _openScanner(context, event),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TicketScannerListFooter extends StatelessWidget {
  const _TicketScannerListFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadedCount,
    required this.totalCount,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int loadedCount;
  final int totalCount;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: AppSpinner(size: 22, strokeWidth: 2),
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(
              totalCount > 0
                  ? 'Load more ($loadedCount/$totalCount)'
                  : 'Load more',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Showing all $loadedCount events',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
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