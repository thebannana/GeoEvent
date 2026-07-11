import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/event_status.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/events/providers/event_refresh_providers.dart';
import '../../../../shared/my_events/models/my_event_response_dto.dart';
import '../../application/my_events_controller.dart';
import '../../../event_reservations/presentation/screens/event_reservations_screen.dart';
import '../widgets/list_paging_footer.dart';
import '../widgets/my_event_card.dart';
import 'edit_event_screen.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  static const List<String> _statuses = [
    'All',
    EventStatus.pending,
    EventStatus.confirmed,
    EventStatus.completed,
    EventStatus.cancelled,
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  String _query = '';
  String _selectedStatus = 'All';
  bool _busyDeleting = false;

@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);

  Future.microtask(() {
    ref.read(myEventsProvider.notifier).refresh();
  });
}

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
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

  Future<void> _refresh() async {
    await ref.read(myEventsProvider.notifier).refresh();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);

    _searchDebouncer.run(() {
      ref.read(myEventsProvider.notifier).applyFilters(
            searchTerm: _query,
            selectedStatus: _selectedStatus,
          );
    });
  }

  Future<void> _clearSearch() async {
    _searchDebouncer.cancel();
    _searchController.clear();
    setState(() => _query = '');

    await ref.read(myEventsProvider.notifier).applyFilters(
          searchTerm: '',
          selectedStatus: _selectedStatus,
        );
  }

  Future<void> _onStatusChanged(String status) async {
    setState(() => _selectedStatus = status);

    await ref.read(myEventsProvider.notifier).applyFilters(
          searchTerm: _query,
          selectedStatus: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(myEventsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('My events'),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          forceMaterialTransparency: true,
          systemOverlayStyle: overlayStyle,
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: eventsAsync.when(
            loading: () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(
                    title: 'Loading your events',
                    message: 'Please wait while we load your events.',
                  ),
                ),
              ],
            ),
            error: (_, _) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: AppErrorState(
                      title: 'Failed to load your events',
                      message: 'Pull to refresh or try again.',
                      onRetry: _refresh,
                    ),
                  ),
                ),
              ],
            ),
            data: (state) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search events',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  onPressed: _clearSearch,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < _statuses.length; i++) ...[
                              AppChip(
                                label: _statuses[i],
                                selected: _selectedStatus == _statuses[i],
                                onTap: () => _onStatusChanged(_statuses[i]),
                              ),
                              if (i != _statuses.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.items.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: AppEmptyState(
                          icon: Icons.event_busy_rounded,
                          title: (_query.trim().isEmpty &&
                                  _selectedStatus == 'All')
                              ? 'No events yet'
                              : 'No matching events',
                          message: (_query.trim().isEmpty &&
                                  _selectedStatus == 'All')
                              ? 'Events you create will appear here.'
                              : 'Try another search or status filter.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      sliver: SliverList.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = state.items[index];
                          return MyEventCard(
                            event: event,
                            actionsDisabled: _busyDeleting,
                            onTap: _busyDeleting ? null : () => _editEvent(event),
                            onEdit:
                                _busyDeleting ? null : () => _editEvent(event),
                            onDelete: _busyDeleting
                                ? null
                                : () => _confirmDelete(event),
                            onViewReservations: _busyDeleting
                                ? null
                                : () => _openReservations(event),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: ListPagingFooter(
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        loadedCount: state.items.length,
                        totalCount: state.totalCount,
                        itemLabel: 'events',
                        onLoadMore: state.hasMore && !state.isLoadingMore
                            ? () => ref.read(myEventsProvider.notifier).loadMore()
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _editEvent(MyEventResponseDto event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditEventScreen(event: event),
      ),
    );

    if (updated == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _confirmDelete(MyEventResponseDto event) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete event?',
      message: '"${event.title}" will be permanently deleted.',
      cancelLabel: 'Keep',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyDeleting = true);

    try {
      final success = await ref.read(myEventsProvider.notifier).deleteEvent(
            event.eventId,
          );

      if (!mounted) return;

      if (success) {
        triggerEventMapRefresh(ref);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Event deleted.' : 'Could not delete event.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete event.',
        tag: 'MyEventsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      final message = ErrorMapper.toMessage(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Could not delete event.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busyDeleting = false);
      }
    }
  }

  void _openReservations(MyEventResponseDto event) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventReservationsScreen(event: event),
      ),
    );
  }
}