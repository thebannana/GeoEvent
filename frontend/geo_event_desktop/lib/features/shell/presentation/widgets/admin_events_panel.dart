import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/data/admin_events_repository.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/admin_event.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';
import '../../../../shared/map/data/mapbox_reverse_geocoding_api.dart';
import '../../../../shared/map/models/mapbox_place.dart';
import '../screens/edit_event_screen.dart';
import '../screens/event_attendees_dialog.dart';
import '../screens/event_details_screen.dart';

enum AdminEventViewStyle { list, grid2, grid3 }

enum AdminEventStatusFilter { all, pending, confirmed, cancelled, completed }

enum AdminEventSortField { startDateTime, createdAt, title, views, likes }

class AdminEventsPanel extends StatefulWidget {
  const AdminEventsPanel({
    super.key,
    required this.repository,
    required this.reverseGeocodingApi,
    required this.usersRepository,
    this.onPreview,
    this.onEdit,
    this.onEventDetails,
    this.onAttendeeTap,
  });

  final AdminEventsRepository repository;
  final AdminUsersRepository usersRepository;
  final MapboxReverseGeocodingApi reverseGeocodingApi;
  final ValueChanged<AdminEventRowData>? onPreview;
  final ValueChanged<AdminEventRowData>? onEdit;
  final ValueChanged<AdminEventRowData>? onEventDetails;
  final ValueChanged<ManageableEventAttendeePreview>? onAttendeeTap;

  @override
  State<AdminEventsPanel> createState() => _AdminEventsPanelState();
}

class _AdminEventsPanelState extends State<AdminEventsPanel> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<AdminEventRowData> _events = const [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  int _page = 1;
  final int _pageSize = 9;
  int _totalCount = 0;

  AdminEventStatusFilter _statusFilter = AdminEventStatusFilter.all;
  AdminEventSortField _sortField = AdminEventSortField.startDateTime;
  bool _sortDescending = true;
  AdminEventViewStyle _viewStyle = AdminEventViewStyle.grid3;

  final Map<String, String> _locationCache = <String, String>{};
  final Set<String> _resolvingLocationKeys = <String>{};

  final Map<int, EventReservationSummary> _summaryCache =
      <int, EventReservationSummary>{};
  final Set<int> _loadingSummaryIds = <int>{};

  final Map<int, AdminUserProfileDetails?> _organizerCache =
      <int, AdminUserProfileDetails?>{};
  final Set<int> _loadingOrganizerIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents({int? page, bool showLoader = true}) async {
    final targetPage = page ?? _page;

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final result = await widget.repository.getEvents(
        page: targetPage,
        pageSize: _pageSize,
        searchTerm: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _mapStatus(_statusFilter),
        sortBy: _mapSortBy(_sortField),
        sortDescending: _sortDescending,
      );

      if (!mounted) return;

      final mappedEvents = result.items
          .map(AdminEventRowData.fromEvent)
          .toList(growable: false);

      setState(() {
        _page = result.page <= 0 ? 1 : result.page;
        _totalCount = result.totalCount;
        _events = mappedEvents;
        _isLoading = false;
      });

      unawaited(_resolveLocations(mappedEvents));
      unawaited(_preloadSummaries(mappedEvents));
      unawaited(_preloadOrganizers(mappedEvents));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load events.';
      });
    }
  }

  Future<void> _preloadSummaries(List<AdminEventRowData> events) async {
    for (final event in events) {
      unawaited(_ensureSummaryLoaded(event.id));
    }
  }

  Future<void> _ensureSummaryLoaded(int eventId) async {
    if (_summaryCache.containsKey(eventId) ||
        _loadingSummaryIds.contains(eventId)) {
      return;
    }

    _loadingSummaryIds.add(eventId);

    try {
      final summary = await widget.repository.getEventReservationSummary(eventId);

      if (!mounted) return;

      setState(() {
        _summaryCache[eventId] = summary;
      });
    } catch (_) {
      // ignore
    } finally {
      _loadingSummaryIds.remove(eventId);
    }
  }

  Future<void> _preloadOrganizers(List<AdminEventRowData> events) async {
    for (final event in events) {
      final organizerId = event.organizerId;
      if (organizerId == null || organizerId <= 0) continue;
      unawaited(_ensureOrganizerLoaded(organizerId));
    }
  }

  Future<void> _ensureOrganizerLoaded(int organizerId) async {
    if (_organizerCache.containsKey(organizerId) ||
        _loadingOrganizerIds.contains(organizerId)) {
      return;
    }

    _loadingOrganizerIds.add(organizerId);

    try {
      final profile =
          await widget.usersRepository.getUserProfileDetails(organizerId);

      if (!mounted) return;

      setState(() {
        _organizerCache[organizerId] = profile;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _organizerCache[organizerId] = null;
      });
    } finally {
      _loadingOrganizerIds.remove(organizerId);
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _loadEvents(page: 1);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    _loadEvents(page: 1);
  }

  Future<void> _setStatusFilter(AdminEventStatusFilter value) async {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
    await _loadEvents(page: 1);
  }

  Future<void> _setSort(AdminEventSortField field) async {
    setState(() {
      if (_sortField == field) {
        _sortDescending = !_sortDescending;
      } else {
        _sortField = field;
        _sortDescending = true;
      }
    });

    await _loadEvents(page: 1, showLoader: false);
  }

  void _setViewStyle(AdminEventViewStyle value) {
    if (_viewStyle == value) return;
    setState(() => _viewStyle = value);
  }

  Future<void> _openEditEvent(AdminEventRowData row) async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final fullEvent = await widget.repository.getEventById(row.id);

      if (!mounted) return;

      final updatedEvent = await Navigator.of(context).push<AdminEvent>(
        MaterialPageRoute(
          builder: (_) => EditEventScreen(
            event: fullEvent,
            repository: widget.repository,
          ),
        ),
      );

      if (!mounted) return;

      widget.onEdit?.call(row);

      if (updatedEvent != null) {
        _summaryCache.remove(row.id);
        await _loadEvents(showLoader: false);
        if (!mounted) return;
        _showSnack('${updatedEvent.displayTitle} updated successfully.');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to open edit screen.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(AdminEventRowData event) async {
    if (_isActionLoading) return;

    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: colors.card,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Delete event',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                'Are you sure you want to delete ${event.title}? This action cannot be undone.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() => _isActionLoading = true);

    try {
      await widget.repository.deleteEvent(event.id);
      _summaryCache.remove(event.id);

      final nextPage = _events.length == 1 && _page > 1 ? _page - 1 : _page;
      await _loadEvents(page: nextPage, showLoader: false);

      if (!mounted) return;
      _showSnack('${event.title} deleted successfully.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to delete ${event.title}.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _openAttendees(AdminEventRowData event) async {
    await _ensureSummaryLoaded(event.id);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => EventAttendeesDialog(
        event: event,
        repository: widget.repository,
        usersRepository: widget.usersRepository,
        summary: _summaryCache[event.id],
        onAttendeeTap: widget.onAttendeeTap,
      ),
    );
  }

  void _openEventDetails(int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: eventId,
          usersRepository: widget.usersRepository,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _mapStatus(AdminEventStatusFilter value) {
    switch (value) {
      case AdminEventStatusFilter.all:
        return null;
      case AdminEventStatusFilter.pending:
        return 'Pending';
      case AdminEventStatusFilter.confirmed:
        return 'Confirmed';
      case AdminEventStatusFilter.cancelled:
        return 'Cancelled';
      case AdminEventStatusFilter.completed:
        return 'Completed';
    }
  }

  String _mapSortBy(AdminEventSortField value) {
    switch (value) {
      case AdminEventSortField.startDateTime:
        return 'StartDateTime';
      case AdminEventSortField.createdAt:
        return 'CreatedAt';
      case AdminEventSortField.title:
        return 'Title';
      case AdminEventSortField.views:
        return 'ViewCount';
      case AdminEventSortField.likes:
        return 'LikesCount';
    }
  }

  int get _totalPages {
    if (_totalCount == 0) return 1;
    return (_totalCount / _pageSize).ceil();
  }

  int _resolveCrossAxisCount(double width) {
    if (_viewStyle == AdminEventViewStyle.list) return 1;
    if (_viewStyle == AdminEventViewStyle.grid2) return width < 920 ? 1 : 2;
    if (width >= 1440) return 3;
    if (width >= 920) return 2;
    return 1;
  }

  double _resolveAspectRatio(double width, int crossAxisCount) {
    if (_viewStyle == AdminEventViewStyle.list) {
      return width > 1180 ? 3.45 : 2.20;
    }

    if (crossAxisCount == 1) return 1.28;
    if (crossAxisCount == 2) return width > 1100 ? 1.08 : 1.00;
    return 0.86;
  }

  String _locationKey(AdminEventRowData event) =>
      '${event.latitude.toStringAsFixed(5)},${event.longitude.toStringAsFixed(5)}';

  String _bestLocationLabel(AdminEventRowData event) {
    final cached = _locationCache[_locationKey(event)];
    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }
    return event.fallbackLocationLabel;
  }

  Future<void> _resolveLocations(List<AdminEventRowData> events) async {
    for (final event in events) {
      final key = _locationKey(event);

      if (_locationCache.containsKey(key) ||
          _resolvingLocationKeys.contains(key)) {
        continue;
      }

      _resolvingLocationKeys.add(key);

      try {
        final place = await widget.reverseGeocodingApi.reverseGeocode(
          latitude: event.latitude,
          longitude: event.longitude,
        );

        if (!mounted) return;

        final resolved = _formatPlace(place, event);

        setState(() {
          _locationCache[key] = resolved;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _locationCache[key] = event.fallbackLocationLabel;
        });
      } finally {
        _resolvingLocationKeys.remove(key);
      }
    }
  }

  String _formatPlace(MapboxPlace? place, AdminEventRowData event) {
    if (place == null) return event.fallbackLocationLabel;

    final title = place.title.trim();
    final subtitle = (place.subtitle ?? '').trim();

    if (title.isEmpty && subtitle.isEmpty) {
      return event.fallbackLocationLabel;
    }

    if (title.isEmpty) return subtitle;
    if (subtitle.isEmpty) return title;

    final normalizedTitle = _normalizeLocationPart(title);
    final subtitleParts = subtitle
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final deduplicatedParts = subtitleParts.where((part) {
      return _normalizeLocationPart(part) != normalizedTitle;
    }).toList(growable: false);

    if (deduplicatedParts.isEmpty) {
      return title;
    }

    return '$title, ${deduplicatedParts.join(', ')}';
  }

  String _normalizeLocationPart(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  OrganizerCardData _organizerFor(AdminEventRowData event) {
    final organizerId = event.organizerId;
    final profile =
        organizerId != null && organizerId > 0 ? _organizerCache[organizerId] : null;

    if (profile != null) {
      return OrganizerCardData(
        fullName: profile.fullName.trim().isEmpty ? 'Unnamed user' : profile.fullName,
        username: profile.displayUsername,
        imageUrl: profile.imageUrl,
      );
    }

    final fallbackName = event.promoterName?.trim().isNotEmpty == true
        ? event.promoterName!.trim()
        : event.displayPromoterName;

    return OrganizerCardData(
      fullName: fallbackName,
      username: organizerId != null && organizerId > 0 ? 'User ID $organizerId' : 'Unknown user',
      imageUrl: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search events',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
              PopupMenuButton<AdminEventStatusFilter>(
                tooltip: 'Filter events',
                initialValue: _statusFilter,
                onSelected: _setStatusFilter,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AdminEventStatusFilter.all,
                    child: Text('All events'),
                  ),
                  PopupMenuItem(
                    value: AdminEventStatusFilter.pending,
                    child: Text('Pending'),
                  ),
                  PopupMenuItem(
                    value: AdminEventStatusFilter.confirmed,
                    child: Text('Confirmed'),
                  ),
                  PopupMenuItem(
                    value: AdminEventStatusFilter.cancelled,
                    child: Text('Cancelled'),
                  ),
                  PopupMenuItem(
                    value: AdminEventStatusFilter.completed,
                    child: Text('Completed'),
                  ),
                ],
                child: ToolbarSquareButton(
                  icon: Icons.tune_rounded,
                  color: _statusFilter == AdminEventStatusFilter.all
                      ? colors.textSecondary
                      : colorScheme.primary,
                  colors: colors,
                ),
              ),
              PopupMenuButton<AdminEventSortField>(
                tooltip: 'Sort events',
                initialValue: _sortField,
                onSelected: _setSort,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AdminEventSortField.startDateTime,
                    child: Text('Sort by date'),
                  ),
                  PopupMenuItem(
                    value: AdminEventSortField.createdAt,
                    child: Text('Sort by created'),
                  ),
                  PopupMenuItem(
                    value: AdminEventSortField.title,
                    child: Text('Sort by title'),
                  ),
                  PopupMenuItem(
                    value: AdminEventSortField.views,
                    child: Text('Sort by views'),
                  ),
                  PopupMenuItem(
                    value: AdminEventSortField.likes,
                    child: Text('Sort by likes'),
                  ),
                ],
                child: ToolbarSquareButton(
                  icon: _sortDescending
                      ? Icons.south_rounded
                      : Icons.north_rounded,
                  color: colors.textSecondary,
                  colors: colors,
                ),
              ),
              ViewSwitcher(
                viewStyle: _viewStyle,
                onChanged: _setViewStyle,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.borderSoft),
                ),
                child: Text(
                  '$_totalCount events',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSoft.withValues(alpha: 0.55),
                  border: Border.all(
                    color: colors.borderSoft.withValues(alpha: 0.95),
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildBody(context)),
                    if (_isActionLoading)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.background.withValues(alpha: 0.28),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          EventsPagination(
            page: _page,
            totalPages: _totalPages,
            onPrevious: _page > 1 ? () => _loadEvents(page: _page - 1) : null,
            onNext: _page < _totalPages ? () => _loadEvents(page: _page + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Text(
          'No events found.',
          style: textTheme.titleMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _resolveCrossAxisCount(constraints.maxWidth);
        final aspectRatio =
            _resolveAspectRatio(constraints.maxWidth, crossAxisCount);

        return GridView.builder(
          padding: const EdgeInsets.all(14),
          clipBehavior: Clip.hardEdge,
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            final organizer = _organizerFor(event);

            return EventCard(
              event: event,
              organizer: organizer,
              isList: _viewStyle == AdminEventViewStyle.list,
              isCompactGrid: _viewStyle == AdminEventViewStyle.grid3,
              locationLabel: _bestLocationLabel(event),
              summary: _summaryCache[event.id],
              summaryLoading: _loadingSummaryIds.contains(event.id),
              onPreview:
                  widget.onPreview == null ? null : () => widget.onPreview!(event),
              onViewAttendees: () => _openAttendees(event),
              onViewDetails: () => _openEventDetails(event.id),
              onEdit: () => _openEditEvent(event),
              onDelete: () => _confirmDelete(event),
            );
          },
        );
      },
    );
  }
}

class ToolbarSquareButton extends StatelessWidget {
  const ToolbarSquareButton({
    super.key,
    required this.icon,
    required this.color,
    required this.colors,
  });

  final IconData icon;
  final Color color;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class ViewSwitcher extends StatelessWidget {
  const ViewSwitcher({
    super.key,
    required this.viewStyle,
    required this.onChanged,
  });

  final AdminEventViewStyle viewStyle;
  final ValueChanged<AdminEventViewStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    Widget item({
      required IconData icon,
      required bool active,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 38,
          decoration: BoxDecoration(
            color: active ? colors.selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? colorScheme.primary : colors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(
            icon: Icons.view_agenda_outlined,
            active: viewStyle == AdminEventViewStyle.list,
            onTap: () => onChanged(AdminEventViewStyle.list),
          ),
          item(
            icon: Icons.grid_view_rounded,
            active: viewStyle == AdminEventViewStyle.grid2,
            onTap: () => onChanged(AdminEventViewStyle.grid2),
          ),
          item(
            icon: Icons.apps_rounded,
            active: viewStyle == AdminEventViewStyle.grid3,
            onTap: () => onChanged(AdminEventViewStyle.grid3),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.organizer,
    required this.isList,
    required this.isCompactGrid,
    required this.locationLabel,
    required this.summary,
    required this.summaryLoading,
    required this.onPreview,
    required this.onViewAttendees,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminEventRowData event;
  final OrganizerCardData organizer;
  final bool isList;
  final bool isCompactGrid;
  final String locationLabel;
  final EventReservationSummary? summary;
  final bool summaryLoading;
  final VoidCallback? onPreview;
  final VoidCallback onViewAttendees;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    if (isList) {
      return RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventCoverImage(
                      imageUrl: event.imageUrl,
                      title: event.title,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CardActions(
                        onPreview: onPreview,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: EventStatusBadge(status: event.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OrganizerMetaRow(organizer: organizer),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                CardMetaItem(
                                  icon: Icons.calendar_today_rounded,
                                  label: event.dateLabel,
                                ),
                                CardMetaItem(
                                  icon: Icons.location_on_outlined,
                                  label: locationLabel,
                                ),
                                CardMetaItem(
                                  icon: Icons.visibility_outlined,
                                  label: event.views,
                                ),
                                CardMetaItem(
                                  icon: Icons.favorite_border_rounded,
                                  label: event.likes,
                                ),
                                CardMetaItem(
                                  icon: Icons.group_outlined,
                                  label:
                                      summary?.occupancyLabel ?? '${event.capacity}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ReservationStrip(
                              summary: summary,
                              loading: summaryLoading,
                              fallbackCapacity: event.capacity,
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                event.shortDescription(maxCharacters: 180),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.borderSoft),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: onViewDetails,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 0,
                                  ),
                                  side: BorderSide(color: colors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('View details'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: FilledButton.tonal(
                                onPressed: onViewAttendees,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.selectedFill,
                                  foregroundColor: colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Attendees'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            event.priceLabel,
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 8,
                      color: event.segmentColorValue(colorScheme: colorScheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isCompactGrid ? 7 : 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventCoverImage(
                    imageUrl: event.imageUrl,
                    title: event.title,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CardActions(
                      onPreview: onPreview,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: isCompactGrid ? 13 : 12,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: EventStatusBadge(status: event.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OrganizerMetaRow(organizer: organizer),
                    const SizedBox(height: 8),
                    CardMetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: event.dateLabel,
                    ),
                    const SizedBox(height: 6),
                    CardMetaItem(
                      icon: Icons.location_on_outlined,
                      label: locationLabel,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: CardMetaItem(
                            icon: Icons.visibility_outlined,
                            label: event.views,
                          ),
                        ),
                        Expanded(
                          child: CardMetaItem(
                            icon: Icons.favorite_border_rounded,
                            label: event.likes,
                          ),
                        ),
                        Expanded(
                          child: CardMetaItem(
                            icon: Icons.group_outlined,
                            label:
                                summary?.occupancyLabel ?? '${event.capacity}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ReservationStrip(
                      summary: summary,
                      loading: summaryLoading,
                      fallbackCapacity: event.capacity,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        event.shortDescription(
                          maxCharacters: isCompactGrid ? 90 : 125,
                        ),
                        maxLines: isCompactGrid ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: FilledButton.tonal(
                              onPressed: onViewDetails,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.selectedFill,
                                foregroundColor: colorScheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('View details'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: OutlinedButton(
                              onPressed: onViewAttendees,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.borderSoft),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Attendees'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          event.priceLabel,
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            Container(
              height: 8,
              color: event.segmentColorValue(
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrganizerMetaRow extends StatelessWidget {
  const OrganizerMetaRow({
    super.key,
    required this.organizer,
  });

  final OrganizerCardData organizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    final avatarLetter = organizer.fullName.trim().isNotEmpty
        ? organizer.fullName.characters.first.toUpperCase()
        : 'U';

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.inputFill,
          backgroundImage: (organizer.imageUrl?.trim().isNotEmpty ?? false)
              ? NetworkImage(organizer.imageUrl!.trim())
              : null,
          child: (organizer.imageUrl?.trim().isNotEmpty ?? false)
              ? null
              : Text(
                  avatarLetter,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organizer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                organizer.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReservationStrip extends StatelessWidget {
  const ReservationStrip({
    super.key,
    required this.summary,
    required this.loading,
    required this.fallbackCapacity,
  });

  final EventReservationSummary? summary;
  final bool loading;
  final int fallbackCapacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final progress = summary?.progress ?? 0.0;
    final reservedText = summary == null
        ? 'Reservations • Capacity $fallbackCapacity'
        : 'Reservations • ${summary!.occupancyLabel}';
    final secondaryText = summary == null
        ? (loading
            ? 'Loading reservation summary...'
            : 'Attendee details available')
        : '${summary!.confirmedCount} confirmed • ${summary!.pendingCount} pending';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reservedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                summary?.isSoldOut == true ? 'Sold out' : 'Reservations',
                style: textTheme.labelMedium?.copyWith(
                  color: summary?.isSoldOut == true
                      ? colorScheme.error
                      : colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: loading && summary == null ? null : progress,
              minHeight: 8,
              backgroundColor: colors.borderSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary?.isSoldOut == true
                    ? colorScheme.error
                    : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            secondaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CardActions extends StatelessWidget {
  const CardActions({
    super.key,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback? onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (onPreview != null) ...[
          CardActionButton(
            tooltip: 'Preview event',
            icon: Icons.visibility_outlined,
            color: colors.textPrimary,
            onTap: onPreview!,
          ),
          const SizedBox(width: 6),
        ],
        CardActionButton(
          tooltip: 'Edit event',
          icon: Icons.edit_outlined,
          color: colors.textPrimary,
          onTap: onEdit,
        ),
        const SizedBox(width: 6),
        CardActionButton(
          tooltip: 'Delete event',
          icon: Icons.delete_outline_rounded,
          color: colorScheme.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.card.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSoft),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

class CardMetaItem extends StatelessWidget {
  const CardMetaItem({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final Object label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.info),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class EventCoverImage extends StatelessWidget {
  const EventCoverImage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.borderRadius,
  });

  final String? imageUrl;
  final String title;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: hasImage
          ? Image.network(
              normalizedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => EventImageFallback(title: title),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: colors.surfaceSoft,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            )
          : EventImageFallback(title: title),
    );
  }
}

class EventImageFallback extends StatelessWidget {
  const EventImageFallback({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final trimmed = title.trim();
    final initial = trimmed.isEmpty ? 'E' : trimmed.characters.first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.selectedFill,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final normalized = status.toLowerCase();
    late final Color background;
    late final Color foreground;

    switch (normalized) {
      case 'confirmed':
        background = colors.success.withValues(alpha: 0.12);
        foreground = colors.success;
        break;
      case 'pending':
        background = colors.warning.withValues(alpha: 0.14);
        foreground = colors.warning;
        break;
      case 'cancelled':
        background = colorScheme.error.withValues(alpha: 0.12);
        foreground = colorScheme.error;
        break;
      case 'completed':
        background = colors.info.withValues(alpha: 0.12);
        foreground = colors.info;
        break;
      default:
        background = colors.surfaceSoft;
        foreground = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class EventsPagination extends StatelessWidget {
  const EventsPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    Widget pageChip(String label, {bool active = false}) {
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? null : Border.all(color: colors.borderSoft),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: active ? colors.card : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onPrevious,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        pageChip('$page', active: true),
        const SizedBox(width: 10),
        Text(
          'of $totalPages',
          style: textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onNext,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class OrganizerCardData {
  const OrganizerCardData({
    required this.fullName,
    required this.username,
    required this.imageUrl,
  });

  final String fullName;
  final String username;
  final String? imageUrl;
}

class AdminEventRowData {
  const AdminEventRowData({
    required this.id,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.status,
    required this.category,
    required this.views,
    required this.likes,
    required this.capacity,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.segmentColor,
    required this.imageUrl,
    required this.organizerId,
    required this.promoterName,
    required this.displayPromoterName,
  });

  final int id;
  final String title;
  final String description;
  final String dateLabel;
  final String status;
  final String category;
  final int views;
  final int likes;
  final int capacity;
  final double latitude;
  final double longitude;
  final double price;
  final String? segmentColor;
  final String? imageUrl;
  final int? organizerId;
  final String? promoterName;
  final String displayPromoterName;

  String get fallbackLocationLabel =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  String get priceLabel {
    if (price <= 0) return 'Free';
    final isWhole = price == price.roundToDouble();
    return isWhole
        ? '${price.toStringAsFixed(0)} KM'
        : '${price.toStringAsFixed(2)} KM';
  }

  String shortDescription({required int maxCharacters}) {
    final normalized = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return 'No description provided.';
    if (normalized.length <= maxCharacters) return normalized;
    return '${normalized.substring(0, maxCharacters).trimRight()}...';
  }

  Color segmentColorValue({
    required ColorScheme colorScheme,
  }) {
    final raw = segmentColor?.trim();
    if (raw == null || raw.isEmpty) {
      return colorScheme.primary.withValues(alpha: 0.75);
    }

    final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    if (normalized.length != 6 && normalized.length != 8) {
      return colorScheme.primary.withValues(alpha: 0.75);
    }

    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return colorScheme.primary.withValues(alpha: 0.75);
    }
  }

  factory AdminEventRowData.fromEvent(AdminEvent event) {
    return AdminEventRowData(
      id: event.eventId,
      title: event.displayTitleWithSegment,
      description: event.displayDescription,
      dateLabel: event.dateLabel,
      status: event.displayStatus,
      category: event.hasGenreSubtitle ? event.genreSubtitle : event.category,
      views: event.viewCount,
      likes: event.likesCount,
      capacity: event.capacity,
      latitude: event.latitude,
      longitude: event.longitude,
      price: event.price,
      segmentColor: event.segmentColor,
      imageUrl: event.displayImageUrl,
      organizerId: event.organizerId,
      promoterName: event.promoterName,
      displayPromoterName: event.displayPromoterName,
    );
  }
}