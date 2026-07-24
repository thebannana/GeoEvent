import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
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
  });

  final AdminEventRowData event;
  final AdminEventsRepository repository;
  final AdminUsersRepository usersRepository;
  final EventReservationSummary? summary;
  final ValueChanged<ManageableEventAttendeePreview>? onAttendeeTap;
  final ValueChanged<ManageableEventAttendeePreview>? onViewProfile;

  @override
  State<EventAttendeesDialog> createState() => _EventAttendeesDialogState();
}

class _EventAttendeesDialogState extends State<EventAttendeesDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _removing = false;
  String? _errorMessage;
  String? _actionMessage;
  int? _removingReservationId;

  int _page = 1;
  final int _pageSize = 12;
  int _totalCount = 0;

  List<ManageableEventAttendeePreview> _items =
      const <ManageableEventAttendeePreview>[];
  EventReservationSummary? _liveSummary;

  @override
  void initState() {
    super.initState();
    _liveSummary = widget.summary;
    _loadAttendees();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees({int page = 1}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.repository.getManageableEventAttendees(
        eventId: widget.event.id,
        page: page,
        pageSize: _pageSize,
        searchTerm: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _page = response.page <= 0 ? 1 : response.page;
        _totalCount = response.totalCount;
        _items = response.items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load attendees.';
      });
    }
  }

  Future<void> _reloadSummary() async {
    try {
      final summary = await widget.repository.getEventReservationSummary(
        widget.event.id,
      );

      if (!mounted) return;
      setState(() {
        _liveSummary = summary;
      });
    } catch (_) {
      // Keep current summary if refresh fails.
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _loadAttendees(page: 1);
    });
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    _loadAttendees(page: 1);
  }

  int get _totalPages {
    if (_totalCount <= 0) return 1;
    return (_totalCount / _pageSize).ceil();
  }

  Future<String?> _showRemoveAttendeeDialog(
    BuildContext context,
    ManageableEventAttendeePreview attendee,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.appColors;
        final textTheme = theme.textTheme;
        final colorScheme = theme.colorScheme;

        final attendeeName = attendee.displayUsername;

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove $attendeeName from "${widget.event.title}"?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Example: Removed by organizer',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: colors.inputFill,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
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
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _removeAttendee(ManageableEventAttendeePreview attendee) async {
    if (_removing) return;

    final reason = await _showRemoveAttendeeDialog(context, attendee);
    if (reason == null) return;

    setState(() {
      _removing = true;
      _removingReservationId = attendee.reservationId;
      _actionMessage = null;
      _errorMessage = null;
    });

    try {
      await widget.repository.removeAttendee(
        widget.event.id,
        attendee.reservationId,
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );

      if (!mounted) return;

      final updatedItems = _items
          .where((e) => e.reservationId != attendee.reservationId)
          .toList(growable: false);

      setState(() {
        _items = updatedItems;
        _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
        _removing = false;
        _removingReservationId = null;
        _actionMessage = '${attendee.displayUsername} removed successfully.';
      });

      await _reloadSummary();

      if (_items.isEmpty && _page > 1) {
        await _loadAttendees(page: _page - 1);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _removing = false;
        _removingReservationId = null;
        _errorMessage = 'Failed to remove attendee.';
      });
    }
  }

  Future<void> _handleViewProfile(ManageableEventAttendeePreview attendee) async {
    if (widget.onViewProfile != null) {
      widget.onViewProfile!.call(attendee);
      return;
    }

    final userId = attendee.userId;
    if (userId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('User profile is not available.')),
        );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          repository: widget.usersRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 920 ? 820.0 : screenWidth - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: 760,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryChip(
                    label: 'Reserved',
                    value: _liveSummary?.reservedCount.toString() ?? '-',
                  ),
                  _SummaryChip(
                    label: 'Confirmed',
                    value: _liveSummary?.confirmedCount.toString() ?? '-',
                  ),
                  _SummaryChip(
                    label: 'Pending',
                    value: _liveSummary?.pendingCount.toString() ?? '-',
                  ),
                  _SummaryChip(
                    label: 'Available',
                    value: _liveSummary?.availableCount.toString() ?? '-',
                  ),
                  _SummaryChip(
                    label: 'Capacity',
                    value: _liveSummary?.capacity.toString() ??
                        widget.event.capacity.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
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
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              if (_actionMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.success.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    _actionMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null && !_loading) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.borderSoft),
                  ),
                  child: _buildBody(colors, textTheme, colorScheme),
                ),
              ),
              const SizedBox(height: 14),
              _DialogPagination(
                page: _page,
                totalPages: _totalPages,
                onPrevious: _page > 1 && !_loading
                    ? () => _loadAttendees(page: _page - 1)
                    : null,
                onNext: _page < _totalPages && !_loading
                    ? () => _loadAttendees(page: _page + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppThemeColors colors,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final attendee = _items[index];
        final isRemovingThisItem =
            _removing && _removingReservationId == attendee.reservationId;

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
          onKick: isRemovingThisItem ? null : () => _removeAttendee(attendee),
        );
      },
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSoft),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AttendeeAvatar(
                          username: attendee.displayUsername,
                          avatarUrl: attendee.avatarUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AttendeeTextBlock(attendee: attendee),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ProfileButton(
                            onPressed: isBusy ? null : onViewProfile,
                          ),
                          _KickButton(
                            isRemovingThisItem: isRemovingThisItem,
                            colorScheme: colorScheme,
                            onPressed: onKick,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AttendeeAvatar(
                    username: attendee.displayUsername,
                    avatarUrl: attendee.avatarUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _AttendeeTextBlock(attendee: attendee),
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ProfileButton(onPressed: isBusy ? null : onViewProfile),
                        _KickButton(
                          isRemovingThisItem: isRemovingThisItem,
                          colorScheme: colorScheme,
                          onPressed: onKick,
                        ),
                      ],
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
}

class _AttendeeTextBlock extends StatelessWidget {
  const _AttendeeTextBlock({
    required this.attendee,
  });

  final ManageableEventAttendeePreview attendee;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          attendee.displayUsername,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attendee.quantity == 1
              ? '1 ticket'
              : '${attendee.quantity} tickets',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: colors.borderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.person_outline_rounded, size: 18),
        label: const Text(
          'View profile',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _KickButton extends StatelessWidget {
  const _KickButton({
    required this.isRemovingThisItem,
    required this.colorScheme,
    required this.onPressed,
  });

  final bool isRemovingThisItem;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: colorScheme.error.withValues(alpha: 0.10),
          foregroundColor: colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isRemovingThisItem
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.error,
                  ),
                ),
              )
            : const Icon(Icons.person_remove_rounded, size: 18),
        label: Text(
          isRemovingThisItem ? 'Removing...' : 'Kick',
          overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
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
    final textTheme = Theme.of(context).textTheme;

    final normalized = avatarUrl?.trim();
    final hasImage = normalized != null && normalized.isNotEmpty;
    final initial = username.trim().isEmpty
        ? 'U'
        : username.trim().characters.first.toUpperCase();

    if (hasImage) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: colors.surfaceSoft,
        backgroundImage: NetworkImage(normalized),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.selectedFill,
      child: Text(
        initial,
        style: textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
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