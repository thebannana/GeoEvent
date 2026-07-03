import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/event_status.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/events/providers/event_refresh_providers.dart';
import '../../../my_events/presentation/screens/event_reservations_screen.dart';
import '../../application/my_events_controller.dart';
import 'edit_event_screen.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _statuses = [
    'All',
    EventStatus.pending,
    EventStatus.confirmed,
    EventStatus.completed,
    EventStatus.cancelled,
  ];

  String _query = '';
  String _selectedStatus = 'All';
  bool _busyDeleting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(myEventsProvider.notifier).refresh();
  }

  bool _matchesStatus(MyEventResponseDto event) {
    if (_selectedStatus == 'All') return true;
    return event.displayStatus.toLowerCase() == _selectedStatus.toLowerCase();
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
            data: (events) {
              final query = _query.trim().toLowerCase();

              final filtered = events.where((event) {
                final matchesQuery =
                    query.isEmpty ||
                    event.title.toLowerCase().contains(query) ||
                    event.description.toLowerCase().contains(query) ||
                    (event.genreName?.toLowerCase().contains(query) ?? false);

                final matchesStatus = _matchesStatus(event);

                return matchesQuery && matchesStatus;
              }).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search events',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
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
                                onTap: () {
                                  setState(() => _selectedStatus = _statuses[i]);
                                },
                              ),
                              if (i != _statuses.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: AppEmptyState(
                          icon: Icons.event_busy_rounded,
                          title: events.isEmpty
                              ? 'No events yet'
                              : 'No matching events',
                          message: events.isEmpty
                              ? 'Events you create will appear here.'
                              : 'Try another search or status filter.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          return _EventCard(
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

  static String formatEventDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} • $hour:$minute';
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.actionsDisabled,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReservations,
  });

  final MyEventResponseDto event;
  final bool actionsDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewReservations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = event.displayStatus;
    final statusColor = EventStatus.displayColor(status);

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventImage(imageUrl: event.displayImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<_EventMenuAction>(
                      tooltip: 'Event actions',
                      onSelected: (value) {
                        switch (value) {
                          case _EventMenuAction.edit:
                            onEdit?.call();
                            break;
                          case _EventMenuAction.reservations:
                            if (!event.canViewReservations) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reservations are not available for this event yet.',
                                  ),
                                ),
                              );
                              return;
                            }
                            onViewReservations?.call();
                            break;
                          case _EventMenuAction.delete:
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _EventMenuAction.edit,
                          enabled: !actionsDisabled,
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _EventMenuAction.reservations,
                          enabled: !actionsDisabled && event.canViewReservations,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.groups_rounded,
                              color: (!actionsDisabled &&
                                      event.canViewReservations)
                                  ? null
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                            ),
                            title: Text(
                              event.canViewReservations
                                  ? 'View reservations'
                                  : 'View reservations unavailable',
                              style: (!actionsDisabled &&
                                      event.canViewReservations)
                                  ? null
                                  : TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _EventMenuAction.delete,
                          enabled: !actionsDisabled,
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline_rounded),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (event.genreName?.isNotEmpty ?? false)
                  Text(
                    event.genreName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: 8),
                AppChip(
                  label: status,
                  selected: true,
                  onTap: null,
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  foregroundColor: statusColor,
                  borderColor: statusColor.withValues(alpha: 0.22),
                  selectedBackgroundColor: statusColor.withValues(alpha: 0.14),
                  selectedForegroundColor: statusColor,
                  selectedBorderColor: statusColor.withValues(alpha: 0.22),
                  compact: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _MyEventsScreenState.formatEventDate(event.startDateTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _EventMenuAction {
  edit,
  reservations,
  delete,
}

class _EventImage extends StatelessWidget {
  const _EventImage({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          normalizedUrl,
          width: 98,
          height: 98,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _fallback(context, loading: true);
          },
          errorBuilder: (_, _, _) => _fallback(context),
        ),
      );
    }

    return _fallback(context);
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A3F52), const Color(0xFF1E2230)]
              : [const Color(0xFFD9E7FF), const Color(0xFFEEF3FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: loading
          ? const Center(
              child: AppSpinner(size: 22, strokeWidth: 2),
            )
          : Icon(
              Icons.event_rounded,
              size: 34,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}