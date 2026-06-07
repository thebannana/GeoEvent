import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_events/presentation/screens/event_reservations_screen.dart';
import '../../application/my_events_controller.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import 'edit_event_screen.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  final _searchController = TextEditingController();

  static const List<String> _statuses = [
    'All',
    'Published',
    'Draft',
    'Cancelled',
    'Completed',
    'Postponed',
  ];

  String _query = '';
  String _selectedStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        body: RefreshIndicator(
          onRefresh: () => ref.read(myEventsProvider.notifier).refresh(),
          child: eventsAsync.when(
            loading: () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (_, __) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _TopStateCard(
                      icon: Icons.cloud_off_rounded,
                      title: 'Failed to load your events',
                      subtitle: 'Pull to refresh or try again.',
                      actionLabel: 'Retry',
                      onAction: () {
                        ref.read(myEventsProvider.notifier).refresh();
                      },
                    ),
                  ),
                ),
              ],
            ),
            data: (events) {
              final filtered = events.where((event) {
                final query = _query.trim().toLowerCase();

                final matchesQuery =
                    query.isEmpty ||
                    event.title.toLowerCase().contains(query) ||
                    event.description.toLowerCase().contains(query) ||
                    (event.venueName?.toLowerCase().contains(query) ?? false) ||
                    (event.genreName?.toLowerCase().contains(query) ?? false);

                final uiStatus = _normalizeStatus(event.status);
                final matchesStatus =
                    _selectedStatus == 'All' || uiStatus == _selectedStatus;

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
                              _StatusChip(
                                label: _statuses[i],
                                selected: _selectedStatus == _statuses[i],
                                onTap: () {
                                  setState(
                                    () => _selectedStatus = _statuses[i],
                                  );
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
                        child: _TopStateCard(
                          icon: Icons.event_busy_rounded,
                          title: events.isEmpty
                              ? 'No events yet'
                              : 'No matching events',
                          subtitle: events.isEmpty
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          return _EventCard(
                            event: event,
                            isDark: isDark,
                            onTap: () {
                              _editEvent(event);
                            },
                            onEdit: () {
                              _editEvent(event);
                            },
                            onDelete: () {
                              _confirmDelete(event);
                            },
                            onViewReservations: () {
                              _openReservations(event);
                            },
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
      await ref.read(myEventsProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(MyEventResponseDto event) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete event?'),
      content: Text(
        '"${event.title}" will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  final success = await ref
      .read(myEventsProvider.notifier)
      .deleteEvent(event.eventId);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Event deleted.' : 'Could not delete event.',
      ),
    ),
  );
}

void _openReservations(MyEventResponseDto event) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EventReservationsScreen(event: event),
    ),
  );
}

  static String _normalizeStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'active':
      case 'published':
        return 'Published';
      case 'draft':
        return 'Draft';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'postponed':
        return 'Postponed';
      default:
        return status.trim().isEmpty ? 'Unknown' : status;
    }
  }

  static String _formatEventDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} • $hour:$minute';
  }
}

class _EventCard extends StatelessWidget {
  final MyEventResponseDto event;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewReservations;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReservations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _MyEventsScreenState._normalizeStatus(event.status);
    final statusColor = _statusColor(status);

    return Material(
      color: isDark ? const Color(0xFF17191D) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE5EAF2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventImage(
                imageUrl: event.displayImageUrl,
                isDark: isDark,
              ),
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
                                onEdit();
                                break;
                              case _EventMenuAction.reservations:
                                onViewReservations();
                                break;
                              case _EventMenuAction.delete:
                                onDelete();
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _EventMenuAction.edit,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_rounded),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _EventMenuAction.reservations,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.groups_rounded),
                                title: Text('View reservations'),
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: _EventMenuAction.delete,
                              child: ListTile(
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
                    if ((event.venueName?.isNotEmpty ?? false) ||
                        (event.genreName?.isNotEmpty ?? false))
                      Text(
                        [
                          if (event.genreName?.isNotEmpty ?? false)
                            event.genreName!,
                          if (event.venueName?.isNotEmpty ?? false)
                            event.venueName!,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
                            _MyEventsScreenState._formatEventDate(
                              event.startDateTime,
                            ),
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
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return const Color(0xFF43A047);
      case 'draft':
        return const Color(0xFFF0A500);
      case 'cancelled':
        return const Color(0xFFE05C5C);
      case 'completed':
        return const Color(0xFF5B9ED6);
      case 'postponed':
        return const Color(0xFF8E6AD8);
      default:
        return const Color(0xFF5B9ED6);
    }
  }
}

enum _EventMenuAction {
  edit,
  reservations,
  delete,
}

class _EventImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _EventImage({
    required this.imageUrl,
    required this.isDark,
  });

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
            return _fallback(loading: true);
          },
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback({bool loading = false}) {
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
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const Icon(Icons.event_rounded, size: 34),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.6)
                : isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? primary
                : isDark
                    ? Colors.white70
                    : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _TopStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}