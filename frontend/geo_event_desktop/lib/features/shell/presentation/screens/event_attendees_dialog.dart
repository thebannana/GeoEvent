import 'package:flutter/material.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/admin_profile/data/admin_events_repository.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/admin_event.dart';
import '../widgets/admin_events_panel.dart';
import 'user_profile_screen.dart';

class EventAttendeesDialog extends StatefulWidget {
  const EventAttendeesDialog({
    super.key,
    required this.event,
    required this.repository,
    required this.usersRepository,
    required this.summary,
    this.onAttendeeTap,
    this.onViewProfile,
    this.onAttendeeRemoved,
  });

  final AdminEventRowData event;
  final AdminEventsRepository repository;
  final AdminUsersRepository usersRepository;
  final EventReservationSummary? summary;
  final ValueChanged<ManageableEventAttendeePreview>? onAttendeeTap;
  final ValueChanged<ManageableEventAttendeePreview>? onViewProfile;
  final Future<void> Function()? onAttendeeRemoved;

  @override
  State<EventAttendeesDialog> createState() =>
      _EventAttendeesDialogState();
}

class _EventAttendeesDialogState
    extends State<EventAttendeesDialog> {
  static const _loggerTag = 'EventAttendeesDialog';
  static const _pageSize = 12;

  final _searchController = TextEditingController();

  final _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 400),
  );

  bool _loading = true;
  bool _removing = false;

  String? _errorMessage;
  String? _actionMessage;

  int? _removingReservationId;
  int _requestId = 0;

  int _page = 1;
  int _totalCount = 0;

  List<ManageableEventAttendeePreview> _items =
      const <ManageableEventAttendeePreview>[];

  EventReservationSummary? _liveSummary;

  @override
  void initState() {
    super.initState();

    _liveSummary = widget.summary;

    AppLogger.debug(
      'Event-attendees dialog initialized.',
      tag: _loggerTag,
    );

    _loadAttendees();
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Event-attendees dialog disposed.',
      tag: _loggerTag,
    );

    _searchDebouncer.dispose();
    _searchController.dispose();

    super.dispose();
  }

  int get _totalPages {
    if (_totalCount <= 0) {
      return 1;
    }

    return (_totalCount / _pageSize).ceil();
  }

  Future<void> _loadAttendees({
    int page = 1,
  }) async {
    final requestId = ++_requestId;

    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    AppLogger.debug(
      'Loading event attendees. Page: $page.',
      tag: _loggerTag,
    );

    try {
      final searchTerm = _searchController.text.trim();

      final response =
          await widget.repository.getManageableEventAttendees(
        eventId: widget.event.id,
        page: page,
        pageSize: _pageSize,
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _page = response.page <= 0 ? 1 : response.page;
        _totalCount = response.totalCount;
        _items = response.items;
        _loading = false;
      });

      AppLogger.info(
        'Event attendees loaded successfully.',
        tag: _loggerTag,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load event attendees.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _loading = false;
        _errorMessage = ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not load attendees. Please try again.',
        );
      });
    }
  }

  Future<void> _reloadSummary() async {
    try {
      final summary = await widget.repository
          .getEventReservationSummary(widget.event.id);

      if (!mounted) return;

      setState(() {
        _liveSummary = summary;
      });

      AppLogger.debug(
        'Event reservation summary refreshed.',
        tag: _loggerTag,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Could not refresh event reservation summary.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onSearchChanged(String _) {
    _searchDebouncer.cancel();

    _searchDebouncer.run(() {
      if (!mounted) return;
      _loadAttendees(page: 1);
    });

    setState(() {});
  }

  void _clearSearch() {
    _searchDebouncer.cancel();
    _searchController.clear();

    setState(() {
      _errorMessage = null;
      _actionMessage = null;
    });

    _loadAttendees(page: 1);
  }

  Future<String?> _showRemoveAttendeeDialog(
    BuildContext context,
    ManageableEventAttendeePreview attendee,
  ) async {
    final reasonController = TextEditingController();

    try {
      return await showDialog<String?>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final colors = theme.appColors;
          final textTheme = theme.textTheme;
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            backgroundColor: colors.card,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Remove attendee',
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remove ${attendee.displayUsername} from '
                    '"${widget.event.title}"?',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Example: Removed by administrator',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: colors.inputFill,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(null);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    reasonController.text.trim(),
                  );
                },
                child: const Text('Remove'),
              ),
            ],
          );
        },
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _removeAttendee(
    ManageableEventAttendeePreview attendee,
  ) async {
    if (_removing) {
      AppLogger.debug(
        'Duplicate attendee-removal action ignored.',
        tag: _loggerTag,
      );
      return;
    }

    final reason = await _showRemoveAttendeeDialog(
      context,
      attendee,
    );

    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _removing = true;
      _removingReservationId = attendee.reservationId;
      _actionMessage = null;
      _errorMessage = null;
    });

    AppLogger.info(
      'Attendee removal started.',
      tag: _loggerTag,
    );

    try {
      await widget.repository.removeAttendee(
        widget.event.id,
        attendee.reservationId,
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );

      if (!mounted) return;

      final updatedItems = _items
          .where(
            (item) =>
                item.reservationId != attendee.reservationId,
          )
          .toList(growable: false);

      final nextPage = updatedItems.isEmpty && _page > 1
          ? _page - 1
          : _page;

      setState(() {
        _items = updatedItems;
        _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
        _removing = false;
        _removingReservationId = null;
        _actionMessage =
            '${attendee.displayUsername} removed successfully.';
      });

      AppLogger.info(
        'Attendee removed successfully.',
        tag: _loggerTag,
      );

      await _reloadSummary();

      if (widget.onAttendeeRemoved != null) {
        await widget.onAttendeeRemoved!();
      }

      if (!mounted) return;

      await _loadAttendees(page: nextPage);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to remove attendee.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _removing = false;
        _removingReservationId = null;
        _errorMessage = ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not remove attendee. Please try again.',
        );
      });
    }
  }

  Future<void> _handleViewProfile(
    ManageableEventAttendeePreview attendee,
  ) async {
    if (widget.onViewProfile != null) {
      widget.onViewProfile!(attendee);
      return;
    }

    final userId = attendee.userId;

    if (userId <= 0) {
      AppLogger.warning(
        'Attendee profile was unavailable.',
        tag: _loggerTag,
      );

      if (!mounted) return;

      _showMessage(
        'User profile is not available.',
      );
      return;
    }

    AppLogger.debug(
      'Opening attendee profile.',
      tag: _loggerTag,
    );

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileScreen(
          userId: userId,
          repository: widget.usersRepository,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final screenSize = MediaQuery.sizeOf(context);

    final dialogWidth = screenSize.width >= 900
        ? 820.0
        : (screenSize.width - 32).clamp(360.0, 820.0);

    final dialogHeight = (screenSize.height - 40).clamp(420.0, 760.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 360,
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: 0.12,
                ),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                textTheme: textTheme,
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildSummary(
                context,
                textTheme: textTheme,
              ),
              const SizedBox(height: 16),
              _buildSearchField(
                context,
                colors: colors,
              ),
              if (_actionMessage != null) ...[
                const SizedBox(height: 14),
                _MessageBanner(
                  message: _actionMessage!,
                  color: colors.success,
                ),
              ],
              if (_errorMessage != null && !_loading) ...[
                const SizedBox(height: 14),
                _MessageBanner(
                  message: _errorMessage!,
                  color: colorScheme.error,
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: _buildBody(
                  context,
                  colors: colors,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 14),
              _DialogPagination(
                page: _page,
                totalPages: _totalPages,
                onPrevious: _page > 1 && !_loading && !_removing
                    ? () => _loadAttendees(page: _page - 1)
                    : null,
                onNext: _page < _totalPages && !_loading && !_removing
                    ? () => _loadAttendees(page: _page + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required TextTheme textTheme,
    required AppThemeColors colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendees',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context, {
    required TextTheme textTheme,
  }) {
    final summary = _liveSummary;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryChip(
          label: 'Reserved',
          value: summary?.reservedCount.toString() ?? '-',
        ),
        _SummaryChip(
          label: 'Confirmed',
          value: summary?.confirmedCount.toString() ?? '-',
        ),
        _SummaryChip(
          label: 'Pending',
          value: summary?.pendingCount.toString() ?? '-',
        ),
        _SummaryChip(
          label: 'Available',
          value: summary?.availableCount.toString() ?? '-',
        ),
        _SummaryChip(
          label: 'Capacity',
          value: summary?.capacity.toString() ??
              widget.event.capacity.toString(),
        ),
      ],
    );
  }

  Widget _buildSearchField(
    BuildContext context, {
    required AppThemeColors colors,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search attendees',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.textSecondary,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
        ),
      ),
    );
  }

Widget _buildBody(
  BuildContext context, {
  required AppThemeColors colors,
  required TextTheme textTheme,
  required ColorScheme colorScheme,
}) {
  if (_loading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  if (_items.isEmpty) {
    return Center(
      child: Text(
        'No attendees found.',
        style: textTheme.titleMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: colors.surfaceSoft.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colors.borderSoft,
      ),
    ),
    child: ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final attendee = _items[index];
        final isRemovingThisItem = _removing &&
            _removingReservationId == attendee.reservationId;

        return _AttendeeListTile(
          attendee: attendee,
          isBusy: _removing,
          isRemovingThisItem: isRemovingThisItem,
          onTap: widget.onAttendeeTap == null || _removing
              ? null
              : () => widget.onAttendeeTap!(attendee),
          onViewProfile: _removing
              ? null
              : () => _handleViewProfile(attendee),
          onKick: _removing
              ? null
              : () => _removeAttendee(attendee),
        );
      },
    ),
  );
}
}

class _AttendeeListTile extends StatelessWidget {
  const _AttendeeListTile({
    required this.attendee,
    required this.isBusy,
    required this.isRemovingThisItem,
    required this.onTap,
    required this.onViewProfile,
    required this.onKick,
  });

  final ManageableEventAttendeePreview attendee;
  final bool isBusy;
  final bool isRemovingThisItem;
  final VoidCallback? onTap;
  final VoidCallback? onViewProfile;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;

    final username = attendee.displayUsername.trim().isEmpty
        ? 'Unknown user'
        : attendee.displayUsername.trim();

    final ticketLabel = attendee.quantity == 1
        ? '1 ticket'
        : '${attendee.quantity} tickets';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.borderSoft,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AttendeeAvatar(
                    username: username,
                    avatarUrl: attendee.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticketLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onViewProfile,
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Profile'),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: FilledButton.tonalIcon(
                      onPressed: isBusy ? null : onKick,
                      style: FilledButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor:
                            colorScheme.error.withValues(alpha: 0.10),
                      ),
                      icon: isRemovingThisItem
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  colorScheme.error,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_remove_rounded,
                              size: 18,
                            ),
                      label: Text(
                        isRemovingThisItem
                            ? 'Removing...'
                            : 'Remove attendee',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendeeAvatar extends StatelessWidget {
  const _AttendeeAvatar({
    required this.username,
    required this.avatarUrl,
  });

  final String username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final normalizedUrl = avatarUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: colors.surfaceSoft,
        backgroundImage: NetworkImage(normalizedUrl),
      );
    }

    final normalizedUsername = username.trim();
    final initial = normalizedUsername.isEmpty
        ? 'U'
        : normalizedUsername.characters.first.toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.selectedFill,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderSoft,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: textTheme.labelLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DialogPagination extends StatelessWidget {
  const _DialogPagination({
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onPrevious,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.textPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$page',
            style: textTheme.labelMedium?.copyWith(
              color: colors.card,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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