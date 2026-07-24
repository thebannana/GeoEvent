import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/models/admin_refund.dart';
import '../../../../shared/admin_profile/models/admin_report.dart' as report_model;
import '../../../../shared/admin_profile/models/admin_report.dart';

enum AdminModerationTab {
  reports,
  refunds,
}

enum AdminReportEntityType {
  user,
  event,
  comment,
  review,
  refund,
}

enum AdminReportQueueFilter {
  all,
  open,
  inReview,
  resolved,
  rejected,
}

enum AdminReportSortField {
  createdAt,
  status,
  type,
  reporter,
  reportedUser,
}

class AdminReportsPanel extends ConsumerStatefulWidget {
  const AdminReportsPanel({super.key});

  @override
  ConsumerState<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends ConsumerState<AdminReportsPanel> {
  final TextEditingController searchController = TextEditingController();
  Timer? searchDebounce;

  AdminModerationTab activeTab = AdminModerationTab.reports;
  final Set<String> expandedIds = <String>{};

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(adminReportsNotifierProvider.notifier).load();
      if (!mounted) return;
      await ref.read(adminRefundsNotifierProvider.notifier).load();

      if (!mounted) return;
      final activeSearch =
          ref.read(adminReportsNotifierProvider).query.search ?? '';
      searchController.text = activeSearch;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  bool get _isRefundTab => activeTab == AdminModerationTab.refunds;

  AdminReportQueueFilter get _queueFilter {
    if (_isRefundTab) {
      return _mapRefundFilterToUi(
        ref.watch(adminRefundsNotifierProvider).query.status,
      );
    }

    return _mapReportFilterToUi(
      ref.watch(adminReportsNotifierProvider).query.status,
    );
  }

  AdminReportSortField get _sortField {
    if (_isRefundTab) {
      return _mapRefundSortToUi(
        ref.watch(adminRefundsNotifierProvider).query.sortBy,
      );
    }

    return _mapReportSortToUi(
      ref.watch(adminReportsNotifierProvider).query.sortBy,
    );
  }

  bool get _sortDescending {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).query.descending;
    }

    return ref.watch(adminReportsNotifierProvider).query.descending;
  }

  bool get _isLoading {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).isLoading;
    }

    return ref.watch(adminReportsNotifierProvider).isLoading;
  }

  bool get _isActionLoading {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).isActionLoading;
    }

    return ref.watch(adminReportsNotifierProvider).isActionLoading;
  }

  String? get _errorMessage {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).errorMessage;
    }

    return ref.watch(adminReportsNotifierProvider).errorMessage;
  }

  int get _page {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).page;
    }

    return ref.watch(adminReportsNotifierProvider).page;
  }

  int get _totalPages {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).totalPages;
    }

    return ref.watch(adminReportsNotifierProvider).totalPages;
  }

  int get _totalCount {
    if (_isRefundTab) {
      return ref.watch(adminRefundsNotifierProvider).totalCount;
    }

    return ref.watch(adminReportsNotifierProvider).totalCount;
  }

  List<AdminModerationItemRowData> get _items {
    if (_isRefundTab) {
      final state = ref.watch(adminRefundsNotifierProvider);
      return state.items
          .map(AdminModerationItemRowData.fromRefund)
          .toList(growable: false);
    }

    final state = ref.watch(adminReportsNotifierProvider);
    return state.items
        .map(AdminModerationItemRowData.fromReport)
        .toList(growable: false);
  }

  Future<void> _reloadActiveTab() async {
    if (_isRefundTab) {
      await ref.read(adminRefundsNotifierProvider.notifier).load();
      return;
    }

    await ref.read(adminReportsNotifierProvider.notifier).load();
  }

  void onSearchChanged(String value) {
    setState(() {});
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      if (_isRefundTab) {
        await ref.read(adminRefundsNotifierProvider.notifier).setSearch(value);
      } else {
        await ref.read(adminReportsNotifierProvider.notifier).setSearch(value);
      }
    });
  }

  Future<void> clearSearch() async {
    searchDebounce?.cancel();
    searchController.clear();
    setState(() {});

    if (_isRefundTab) {
      await ref.read(adminRefundsNotifierProvider.notifier).setSearch('');
    } else {
      await ref.read(adminReportsNotifierProvider.notifier).setSearch('');
    }
  }

  Future<void> setTab(AdminModerationTab value) async {
    if (activeTab == value) return;

    setState(() {
      activeTab = value;
      expandedIds.clear();
    });

    final activeSearch = value == AdminModerationTab.refunds
        ? ref.read(adminRefundsNotifierProvider).query.search
        : ref.read(adminReportsNotifierProvider).query.search;

    if (searchController.text.trim() != (activeSearch ?? '')) {
      searchController.text = activeSearch ?? '';
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
      setState(() {});
    }

    await _reloadActiveTab();
  }

  Future<void> setQueueFilter(AdminReportQueueFilter value) async {
    expandedIds.clear();
    setState(() {});

    if (_isRefundTab) {
      await ref
          .read(adminRefundsNotifierProvider.notifier)
          .setStatusFilter(_mapUiFilterToRefund(value));
      return;
    }

    await ref
        .read(adminReportsNotifierProvider.notifier)
        .setStatusFilter(_mapUiFilterToReport(value));
  }

  Future<void> setSortField(AdminReportSortField value) async {
    expandedIds.clear();
    setState(() {});

    if (_isRefundTab) {
      final mapped = _mapUiSortToRefund(value);
      if (mapped == null) {
        showSnack('This sort option is not available for refunds.');
        return;
      }

      await ref
          .read(adminRefundsNotifierProvider.notifier)
          .setSortField(mapped);
      return;
    }

    await ref
        .read(adminReportsNotifierProvider.notifier)
        .setSortField(_mapUiSortToReport(value));
  }

  Future<void> goToPreviousPage() async {
    if (_page <= 1) return;
    expandedIds.clear();
    setState(() {});

    if (_isRefundTab) {
      await ref.read(adminRefundsNotifierProvider.notifier).goToPage(_page - 1);
      return;
    }

    await ref.read(adminReportsNotifierProvider.notifier).goToPage(_page - 1);
  }

  Future<void> goToNextPage() async {
    if (_page >= _totalPages) return;
    expandedIds.clear();
    setState(() {});

    if (_isRefundTab) {
      await ref.read(adminRefundsNotifierProvider.notifier).goToPage(_page + 1);
      return;
    }

    await ref.read(adminReportsNotifierProvider.notifier).goToPage(_page + 1);
  }

  void toggleExpanded(AdminModerationItemRowData item) {
    setState(() {
      if (expandedIds.contains(item.uniqueKey)) {
        expandedIds.remove(item.uniqueKey);
      } else {
        expandedIds.add(item.uniqueKey);
      }
    });
  }

  Future<void> setStatus(
    AdminModerationItemRowData item,
    AdminReportQueueFilter status,
  ) async {
    try {
      if (_isRefundTab) {
        await _handleRefundStatusChange(item, status);
        return;
      }

      await _handleReportStatusChange(item, status);
    } catch (e) {
      showSnack(_cleanError(e));
    }
  }

  Future<void> _handleReportStatusChange(
    AdminModerationItemRowData item,
    AdminReportQueueFilter status,
  ) async {
    if (item.reportNumericId == null) {
      showSnack('Missing report ID.');
      return;
    }

    if (status == AdminReportQueueFilter.all) {
      showSnack('Invalid report status selection.');
      return;
    }

    if (status == AdminReportQueueFilter.open) {
      showSnack(
        'Report cannot be moved back to open because backend rejects Pending transitions.',
      );
      return;
    }

    if (status == item.status) {
      showSnack('Report is already in that status.');
      return;
    }

    final dialogResult = await showDialog<_ModerationDecisionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModerationDecisionDialog.forReport(
        item: item,
        nextStatus: status,
      ),
    );

    if (dialogResult == null || !dialogResult.confirmed) return;
    if (!mounted) return;

    await ref.read(adminReportsNotifierProvider.notifier).updateStatus(
          reportId: item.reportNumericId!,
          status: _mapUiFilterToReport(status),
          resolutionNote: dialogResult.note?.trim().isEmpty == true
              ? null
              : dialogResult.note?.trim(),
          moderatorAction: dialogResult.moderatorAction?.trim().isEmpty == true
              ? null
              : dialogResult.moderatorAction?.trim(),
        );

    showSnack('Report status updated.');
  }

  Future<void> _handleRefundStatusChange(
    AdminModerationItemRowData item,
    AdminReportQueueFilter status,
  ) async {
    if (status == AdminReportQueueFilter.all ||
        status == AdminReportQueueFilter.open ||
        status == AdminReportQueueFilter.inReview) {
      showSnack(
        'Refund can only be approved or rejected from this panel.',
      );
      return;
    }

    if (!item.canTakeRefundAction) {
      showSnack(
        'Only pending refund requests can be approved or rejected.',
      );
      return;
    }

    if (item.eventId == null || item.reservationNumericId == null) {
      showSnack('Missing refund identifiers.');
      return;
    }

    if (status == item.status) {
      showSnack('Refund is already in that status.');
      return;
    }

    final dialogResult = await showDialog<_ModerationDecisionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModerationDecisionDialog.forRefund(
        item: item,
        nextStatus: status,
      ),
    );

    if (dialogResult == null || !dialogResult.confirmed) return;
    if (!mounted) return;

    final note = dialogResult.note?.trim().isNotEmpty == true
        ? dialogResult.note!.trim()
        : null;
    final moderatorAction = dialogResult.moderatorAction?.trim().isNotEmpty == true
        ? dialogResult.moderatorAction!.trim()
        : null;

    if (status == AdminReportQueueFilter.resolved) {
      await ref.read(adminRefundsNotifierProvider.notifier).approveRefund(
            eventId: item.eventId!,
            reservationId: item.reservationNumericId!,
            decisionReason: note,
            moderatorAction: moderatorAction,
          );
      showSnack('Refund approved.');
      return;
    }

    if (status == AdminReportQueueFilter.rejected) {
      await ref.read(adminRefundsNotifierProvider.notifier).rejectRefund(
            eventId: item.eventId!,
            reservationId: item.reservationNumericId!,
            decisionReason: note,
            moderatorAction: moderatorAction,
          );
      showSnack('Refund rejected.');
    }
  }

  String _cleanError(Object error) {
    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length).trim();
    }
    return text;
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String queueFilterLabel(AdminReportQueueFilter value) {
    switch (value) {
      case AdminReportQueueFilter.all:
        return 'All';
      case AdminReportQueueFilter.open:
        return 'Open';
      case AdminReportQueueFilter.inReview:
        return 'In review';
      case AdminReportQueueFilter.resolved:
        return 'Resolved';
      case AdminReportQueueFilter.rejected:
        return 'Rejected';
    }
  }

  String sortLabel(AdminReportSortField value) {
    switch (value) {
      case AdminReportSortField.createdAt:
        return 'Date';
      case AdminReportSortField.status:
        return 'Status';
      case AdminReportSortField.type:
        return 'Type';
      case AdminReportSortField.reporter:
        return _isRefundTab ? 'Requester' : 'Reporter';
      case AdminReportSortField.reportedUser:
        return _isRefundTab ? 'Target' : 'Reported user';
    }
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
        color: colors.card.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? const Color(0x16000000)
                : const Color(0x12000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTopToolbar(
            colors: colors,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          buildTabBar(
            colors: colors,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.borderSoft.withValues(alpha: 0.92),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildBody(
                      colors: colors,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  ),
                  if (_isActionLoading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 16),
          ReportsPagination(
            page: _page,
            totalPages: _totalPages,
            onPrevious: _page > 1 ? goToPreviousPage : null,
            onNext: _page < _totalPages ? goToNextPage : null,
          ),
        ],
      ),
    );
  }

  Widget buildTopToolbar({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText:
                  _isRefundTab ? 'Search refunds' : 'Search moderation queue',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        PopupMenuButton<AdminReportQueueFilter>(
          tooltip: 'Filter by queue',
          initialValue: _queueFilter,
          onSelected: setQueueFilter,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: AdminReportQueueFilter.all,
              child: Text('All items'),
            ),
            PopupMenuItem(
              value: AdminReportQueueFilter.open,
              child: Text('Open'),
            ),
            PopupMenuItem(
              value: AdminReportQueueFilter.inReview,
              child: Text('In review'),
            ),
            PopupMenuItem(
              value: AdminReportQueueFilter.resolved,
              child: Text('Resolved'),
            ),
            PopupMenuItem(
              value: AdminReportQueueFilter.rejected,
              child: Text('Rejected'),
            ),
          ],
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: _queueFilter == AdminReportQueueFilter.all
                      ? colors.textSecondary
                      : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  queueFilterLabel(_queueFilter),
                  style: textTheme.labelLarge?.copyWith(
                    color: _queueFilter == AdminReportQueueFilter.all
                        ? colors.textSecondary
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuButton<AdminReportSortField>(
          tooltip: 'Sort moderation items',
          initialValue: _sortField,
          onSelected: setSortField,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: AdminReportSortField.createdAt,
              child: Text('Sort by date'),
            ),
            const PopupMenuItem(
              value: AdminReportSortField.status,
              child: Text('Sort by status'),
            ),
            if (!_isRefundTab)
              const PopupMenuItem(
                value: AdminReportSortField.type,
                child: Text('Sort by type'),
              ),
            if (!_isRefundTab)
              PopupMenuItem(
                value: AdminReportSortField.reporter,
                child: const Text('Sort by reporter'),
              ),
            if (!_isRefundTab)
              PopupMenuItem(
                value: AdminReportSortField.reportedUser,
                child: const Text('Sort by reported user'),
              ),
          ],
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sortDescending ? Icons.south_rounded : Icons.north_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  sortLabel(_sortField),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SpacerOrWrapGap(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Text(
            '$_totalCount items',
            style: textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTabBar({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PanelModeTab(
              label: 'Reports',
              icon: Icons.flag_outlined,
              active: activeTab == AdminModerationTab.reports,
              onTap: () => setTab(AdminModerationTab.reports),
            ),
            const SizedBox(width: 10),
            PanelModeTab(
              label: 'Refunds',
              icon: Icons.reply_all_rounded,
              active: activeTab == AdminModerationTab.refunds,
              onTap: () => setTab(AdminModerationTab.refunds),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QueueTab(
                label: 'All',
                active: _queueFilter == AdminReportQueueFilter.all,
                onTap: () => setQueueFilter(AdminReportQueueFilter.all),
              ),
              QueueTab(
                label: 'Open',
                active: _queueFilter == AdminReportQueueFilter.open,
                onTap: () => setQueueFilter(AdminReportQueueFilter.open),
              ),
              QueueTab(
                label: 'In review',
                active: _queueFilter == AdminReportQueueFilter.inReview,
                onTap: () => setQueueFilter(AdminReportQueueFilter.inReview),
              ),
              QueueTab(
                label: 'Resolved',
                active: _queueFilter == AdminReportQueueFilter.resolved,
                onTap: () => setQueueFilter(AdminReportQueueFilter.resolved),
              ),
              QueueTab(
                label: 'Rejected',
                active: _queueFilter == AdminReportQueueFilter.rejected,
                onTap: () => setQueueFilter(AdminReportQueueFilter.rejected),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildBody({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) {
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _reloadActiveTab,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          _isRefundTab ? 'No refunds found.' : 'No reports found.',
          style: textTheme.titleMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            ReportsHeader(activeTab: activeTab),
            const SizedBox(height: 8),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReportExpandableRow(
                  item: item,
                  expanded: expandedIds.contains(item.uniqueKey),
                  activeTab: activeTab,
                  onTap: () => toggleExpanded(item),
                  onStatusChanged: (status) => setStatus(item, status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AdminReportQueueFilter _mapReportFilterToUi(
    report_model.AdminReportQueueFilter value,
  ) {
    switch (value) {
      case report_model.AdminReportQueueFilter.all:
        return AdminReportQueueFilter.all;
      case report_model.AdminReportQueueFilter.open:
        return AdminReportQueueFilter.open;
      case report_model.AdminReportQueueFilter.inReview:
        return AdminReportQueueFilter.inReview;
      case report_model.AdminReportQueueFilter.resolved:
        return AdminReportQueueFilter.resolved;
      case report_model.AdminReportQueueFilter.rejected:
        return AdminReportQueueFilter.rejected;
      case report_model.AdminReportQueueFilter.unknown:
        return AdminReportQueueFilter.all;
    }
  }

  report_model.AdminReportQueueFilter _mapUiFilterToReport(
    AdminReportQueueFilter value,
  ) {
    switch (value) {
      case AdminReportQueueFilter.all:
        return report_model.AdminReportQueueFilter.all;
      case AdminReportQueueFilter.open:
        return report_model.AdminReportQueueFilter.open;
      case AdminReportQueueFilter.inReview:
        return report_model.AdminReportQueueFilter.inReview;
      case AdminReportQueueFilter.resolved:
        return report_model.AdminReportQueueFilter.resolved;
      case AdminReportQueueFilter.rejected:
        return report_model.AdminReportQueueFilter.rejected;
    }
  }

  AdminReportQueueFilter _mapRefundFilterToUi(AdminRefundQueueFilter value) {
    switch (value) {
      case AdminRefundQueueFilter.all:
        return AdminReportQueueFilter.all;
      case AdminRefundQueueFilter.open:
        return AdminReportQueueFilter.open;
      case AdminRefundQueueFilter.inReview:
        return AdminReportQueueFilter.inReview;
      case AdminRefundQueueFilter.resolved:
        return AdminReportQueueFilter.resolved;
      case AdminRefundQueueFilter.rejected:
        return AdminReportQueueFilter.rejected;
    }
  }

  AdminRefundQueueFilter _mapUiFilterToRefund(AdminReportQueueFilter value) {
    switch (value) {
      case AdminReportQueueFilter.all:
        return AdminRefundQueueFilter.all;
      case AdminReportQueueFilter.open:
        return AdminRefundQueueFilter.open;
      case AdminReportQueueFilter.inReview:
        return AdminRefundQueueFilter.inReview;
      case AdminReportQueueFilter.resolved:
        return AdminRefundQueueFilter.resolved;
      case AdminReportQueueFilter.rejected:
        return AdminRefundQueueFilter.rejected;
    }
  }

  AdminReportSortField _mapReportSortToUi(
    report_model.AdminReportSortField value,
  ) {
    switch (value) {
      case report_model.AdminReportSortField.createdAt:
        return AdminReportSortField.createdAt;
      case report_model.AdminReportSortField.status:
        return AdminReportSortField.status;
      case report_model.AdminReportSortField.type:
        return AdminReportSortField.type;
      case report_model.AdminReportSortField.reporter:
        return AdminReportSortField.reporter;
      case report_model.AdminReportSortField.reportedUser:
        return AdminReportSortField.reportedUser;
    }
  }

  report_model.AdminReportSortField _mapUiSortToReport(
    AdminReportSortField value,
  ) {
    switch (value) {
      case AdminReportSortField.createdAt:
        return report_model.AdminReportSortField.createdAt;
      case AdminReportSortField.status:
        return report_model.AdminReportSortField.status;
      case AdminReportSortField.type:
        return report_model.AdminReportSortField.type;
      case AdminReportSortField.reporter:
        return report_model.AdminReportSortField.reporter;
      case AdminReportSortField.reportedUser:
        return report_model.AdminReportSortField.reportedUser;
    }
  }

  AdminReportSortField _mapRefundSortToUi(AdminRefundSortField value) {
    switch (value) {
      case AdminRefundSortField.createdAt:
        return AdminReportSortField.createdAt;
      case AdminRefundSortField.status:
        return AdminReportSortField.status;
      case AdminRefundSortField.amount:
        return AdminReportSortField.status;
    }
  }

  AdminRefundSortField? _mapUiSortToRefund(AdminReportSortField value) {
    switch (value) {
      case AdminReportSortField.createdAt:
        return AdminRefundSortField.createdAt;
      case AdminReportSortField.status:
        return AdminRefundSortField.status;
      case AdminReportSortField.type:
      case AdminReportSortField.reporter:
      case AdminReportSortField.reportedUser:
        return null;
    }
  }
}

class _ModerationDecisionResult {
  const _ModerationDecisionResult({
    required this.confirmed,
    this.note,
    this.moderatorAction,
  });

  final bool confirmed;
  final String? note;
  final String? moderatorAction;
}

class _ModerationDecisionDialog extends StatefulWidget {
  const _ModerationDecisionDialog({
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.noteLabel,
    required this.noteHint,
    required this.noteRequired,
    required this.showModeratorAction,
  });

  factory _ModerationDecisionDialog.forReport({
    required AdminModerationItemRowData item,
    required AdminReportQueueFilter nextStatus,
  }) {
    final requiresNote =
        nextStatus == AdminReportQueueFilter.resolved ||
        nextStatus == AdminReportQueueFilter.rejected;

    final actionLabel = switch (nextStatus) {
      AdminReportQueueFilter.inReview => 'Move to in review',
      AdminReportQueueFilter.resolved => 'Resolve report',
      AdminReportQueueFilter.rejected => 'Reject report',
      _ => 'Apply',
    };

    final nextLabel = switch (nextStatus) {
      AdminReportQueueFilter.inReview => 'In review',
      AdminReportQueueFilter.resolved => 'Resolved',
      AdminReportQueueFilter.rejected => 'Rejected',
      _ => nextStatus.name,
    };

    return _ModerationDecisionDialog(
      title: 'Update report status',
      description:
          'Are you sure you want to change "${item.reportId}" to $nextLabel? This action cannot be reverted.',
      primaryActionLabel: actionLabel,
      noteLabel: nextStatus == AdminReportQueueFilter.rejected
          ? 'Rejection note'
          : 'Resolution note',
      noteHint: nextStatus == AdminReportQueueFilter.rejected
          ? 'Explain why this report is being rejected.'
          : 'Explain how this report was reviewed or resolved.',
      noteRequired: requiresNote,
      showModeratorAction: true,
    );
  }

  factory _ModerationDecisionDialog.forRefund({
    required AdminModerationItemRowData item,
    required AdminReportQueueFilter nextStatus,
  }) {
    final isReject = nextStatus == AdminReportQueueFilter.rejected;

    return _ModerationDecisionDialog(
      title: isReject ? 'Reject refund request' : 'Approve refund request',
      description: isReject
          ? 'Are you sure you want to reject refund request "${item.reportId}"? This action cannot be reverted.'
          : 'Are you sure you want to approve refund request "${item.reportId}"? This action cannot be reverted.',
      primaryActionLabel: isReject ? 'Reject refund' : 'Approve refund',
      noteLabel: 'Decision note',
      noteHint: isReject
          ? 'Explain why this refund request is being rejected.'
          : 'Add an optional note for this refund approval.',
      noteRequired: false,
      showModeratorAction: true,
    );
  }

  final String title;
  final String description;
  final String primaryActionLabel;
  final String noteLabel;
  final String noteHint;
  final bool noteRequired;
  final bool showModeratorAction;

  @override
  State<_ModerationDecisionDialog> createState() =>
      _ModerationDecisionDialogState();
}

class _ModerationDecisionDialogState extends State<_ModerationDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final TextEditingController _moderatorActionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _moderatorActionController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _moderatorActionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This action cannot be reverted.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _noteController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: widget.noteRequired
                        ? '${widget.noteLabel} *'
                        : widget.noteLabel,
                    hintText: widget.noteHint,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: colors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (widget.noteRequired &&
                        (value == null || value.trim().isEmpty)) {
                      return 'This field is required.';
                    }
                    return null;
                  },
                ),
                if (widget.showModeratorAction) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _moderatorActionController,
                    enabled: !_isSubmitting,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Moderator action',
                      hintText: 'Example: approved PayPal refund, rejected duplicate claim',
                      filled: true,
                      fillColor: colors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  setState(() => _isSubmitting = true);

                  Navigator.of(context).pop(
                    _ModerationDecisionResult(
                      confirmed: true,
                      note: _noteController.text,
                      moderatorAction: widget.showModeratorAction
                          ? _moderatorActionController.text
                          : null,
                    ),
                  );
                },
          child: Text(_isSubmitting ? 'Submitting...' : widget.primaryActionLabel),
        ),
      ],
    );
  }
}

class AdminModerationItemRowData {
  const AdminModerationItemRowData({
    required this.uniqueKey,
    required this.id,
    required this.reportId,
    required this.type,
    required this.title,
    required this.preview,
    required this.fullContent,
    required this.reporterName,
    required this.reporterUsername,
    required this.reportedName,
    required this.reportedUsername,
    required this.status,
    required this.createdAt,
    this.amountLabel,
    this.reportNumericId,
    this.reservationNumericId,
    this.eventId,
    this.canTakeRefundAction = false,
    this.decisionReason,
    this.moderatorAction,
  });

  final String uniqueKey;
  final int id;
  final String reportId;
  final AdminReportEntityType type;
  final String title;
  final String preview;
  final String fullContent;
  final String reporterName;
  final String reporterUsername;
  final String reportedName;
  final String reportedUsername;
  final AdminReportQueueFilter status;
  final DateTime createdAt;
  final String? amountLabel;

  final int? reportNumericId;
  final int? reservationNumericId;
  final int? eventId;
  final bool canTakeRefundAction;
  final String? decisionReason;
  final String? moderatorAction;

  factory AdminModerationItemRowData.fromReport(report_model.AdminReport report) {
    return AdminModerationItemRowData(
      uniqueKey: 'report-${report.reportId}',
      id: report.reportId,
      reportId: report.reportIdLabel,
      type: _mapReportEntity(report.entityType),
      title: report.title,
      preview: report.previewText,
      fullContent: report.fullContent,
      reporterName: report.reporterName,
      reporterUsername: report.reporterHandle,
      reportedName: report.reportedName,
      reportedUsername: report.reportedHandle,
      status: _mapReportStatus(report.queueFilter),
      createdAt: report.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      reportNumericId: report.reportId,
      decisionReason: report.resolutionNote,
      moderatorAction: report.moderatorAction,
    );
  }

  factory AdminModerationItemRowData.fromRefund(AdminRefundRequest refund) {
    return AdminModerationItemRowData(
      uniqueKey: 'refund-${refund.reservationId}',
      id: refund.reservationId,
      reportId: refund.refundRequestId,
      type: AdminReportEntityType.refund,
      title: refund.title,
      preview: refund.preview,
      fullContent: refund.fullContent,
      reporterName: refund.requesterName,
      reporterUsername: refund.requesterHandle,
      reportedName: refund.targetName,
      reportedUsername: refund.targetHandle,
      status: _mapRefundStatus(refund.queueFilter),
      createdAt: refund.requestedAt ??
          refund.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      amountLabel: refund.amountLabel,
      reservationNumericId: refund.reservationId,
      eventId: refund.eventId,
      canTakeRefundAction: refund.canTakeAction,
      decisionReason: refund.decisionReason,
      moderatorAction: refund.moderatorAction,
    );
  }

  static AdminReportEntityType _mapReportEntity(
    report_model.AdminReportEntityType value,
  ) {
    switch (value) {
      case report_model.AdminReportEntityType.user:
        return AdminReportEntityType.user;
      case report_model.AdminReportEntityType.event:
        return AdminReportEntityType.event;
      case report_model.AdminReportEntityType.comment:
        return AdminReportEntityType.comment;
      case report_model.AdminReportEntityType.review:
        return AdminReportEntityType.review;
      case report_model.AdminReportEntityType.unknown:
        return AdminReportEntityType.comment;
    }
  }

  static AdminReportQueueFilter _mapReportStatus(
    report_model.AdminReportQueueFilter value,
  ) {
    switch (value) {
      case report_model.AdminReportQueueFilter.all:
        return AdminReportQueueFilter.all;
      case report_model.AdminReportQueueFilter.open:
        return AdminReportQueueFilter.open;
      case report_model.AdminReportQueueFilter.inReview:
        return AdminReportQueueFilter.inReview;
      case report_model.AdminReportQueueFilter.resolved:
        return AdminReportQueueFilter.resolved;
      case report_model.AdminReportQueueFilter.rejected:
        return AdminReportQueueFilter.rejected;
      case report_model.AdminReportQueueFilter.unknown:
        return AdminReportQueueFilter.open;
    }
  }

  static AdminReportQueueFilter _mapRefundStatus(AdminRefundQueueFilter value) {
    switch (value) {
      case AdminRefundQueueFilter.all:
        return AdminReportQueueFilter.all;
      case AdminRefundQueueFilter.open:
        return AdminReportQueueFilter.open;
      case AdminRefundQueueFilter.inReview:
        return AdminReportQueueFilter.inReview;
      case AdminRefundQueueFilter.resolved:
        return AdminReportQueueFilter.resolved;
      case AdminRefundQueueFilter.rejected:
        return AdminReportQueueFilter.rejected;
    }
  }

  String get typeLabel {
    switch (type) {
      case AdminReportEntityType.user:
        return 'User';
      case AdminReportEntityType.event:
        return 'Event';
      case AdminReportEntityType.comment:
        return 'Comment';
      case AdminReportEntityType.review:
        return 'Review';
      case AdminReportEntityType.refund:
        return 'Refund';
    }
  }

  String get statusLabel {
    switch (status) {
      case AdminReportQueueFilter.all:
        return 'All';
      case AdminReportQueueFilter.open:
        return 'Open';
      case AdminReportQueueFilter.inReview:
        return 'In review';
      case AdminReportQueueFilter.resolved:
        return 'Resolved';
      case AdminReportQueueFilter.rejected:
        return 'Rejected';
    }
  }

  String get dateTimeLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return '—';

    final local = createdAt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy - $hh:$min';
  }
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    super.key,
    required this.activeTab,
  });

  final AdminModerationTab activeTab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    final style = textTheme.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.inputFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(flex: 2, child: Text('Type', style: style)),
          Expanded(
            flex: 3,
            child: Text(
              activeTab == AdminModerationTab.refunds
                  ? 'Refund reason'
                  : 'Flagged for',
              style: style,
            ),
          ),
          Expanded(flex: 2, child: Text('Report ID', style: style)),
          Expanded(
            flex: 2,
            child: Text(
              activeTab == AdminModerationTab.refunds ? 'Requester' : 'Reporter',
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              activeTab == AdminModerationTab.refunds ? 'Target' : 'Reported',
              style: style,
            ),
          ),
          Expanded(flex: 2, child: Text('DateTime', style: style)),
          Expanded(flex: 2, child: Text('Status', style: style)),
        ],
      ),
    );
  }
}

class ReportExpandableRow extends StatelessWidget {
  const ReportExpandableRow({
    super.key,
    required this.item,
    required this.expanded,
    required this.activeTab,
    required this.onTap,
    required this.onStatusChanged,
  });

  final AdminModerationItemRowData item;
  final bool expanded;
  final AdminModerationTab activeTab;
  final VoidCallback onTap;
  final ValueChanged<AdminReportQueueFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.typeLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.border,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.reportId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.reporterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.reportedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.dateTimeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(status: item.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: colors.borderSoft),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: DetailPreviewCard(
                          item: item,
                          activeTab: activeTab,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: ModerationActionCard(
                          item: item,
                          activeTab: activeTab,
                          onStatusChanged: onStatusChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class DetailPreviewCard extends StatelessWidget {
  const DetailPreviewCard({
    super.key,
    required this.item,
    required this.activeTab,
  });

  final AdminModerationItemRowData item;
  final AdminModerationTab activeTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MiniInfoChip(
                icon: activeTab == AdminModerationTab.refunds
                    ? Icons.reply_all_rounded
                    : Icons.flag_outlined,
                label: item.typeLabel,
                foreground: colorScheme.primary,
                background: colorScheme.primary.withValues(alpha: 0.10),
              ),
              if (item.amountLabel != null)
                MiniInfoChip(
                  icon: Icons.payments_outlined,
                  label: item.amountLabel!,
                  foreground: colors.textPrimary,
                  background: colors.card,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.fullContent,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          PreviewInfoRow(
            label: activeTab == AdminModerationTab.refunds
                ? 'Requester'
                : 'Reported by',
            value: '${item.reporterName} ${item.reporterUsername}'.trim(),
          ),
          PreviewInfoRow(
            label: activeTab == AdminModerationTab.refunds
                ? 'Refund target'
                : 'Reported target',
            value: '${item.reportedName} ${item.reportedUsername}'.trim(),
          ),
          PreviewInfoRow(label: 'Report ID', value: item.reportId),
          PreviewInfoRow(label: 'Submitted', value: item.dateTimeLabel),
          PreviewInfoRow(label: 'Preview', value: item.preview),
          if ((item.decisionReason?.trim().isNotEmpty ?? false) ||
              (item.moderatorAction?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            if (item.moderatorAction?.trim().isNotEmpty ?? false)
              PreviewInfoRow(
                label: 'Action',
                value: item.moderatorAction!.trim(),
              ),
            if (item.decisionReason?.trim().isNotEmpty ?? false)
              PreviewInfoRow(
                label: 'Note',
                value: item.decisionReason!.trim(),
              ),
          ],
        ],
      ),
    );
  }
}

class ModerationActionCard extends StatelessWidget {
  const ModerationActionCard({
    super.key,
    required this.item,
    required this.activeTab,
    required this.onStatusChanged,
  });

  final AdminModerationItemRowData item;
  final AdminModerationTab activeTab;
  final ValueChanged<AdminReportQueueFilter> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    final isRefund = activeTab == AdminModerationTab.refunds;
    final isClosed = item.status == AdminReportQueueFilter.resolved ||
        item.status == AdminReportQueueFilter.rejected;
    final canTakeRefundAction = item.canTakeRefundAction;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Current status',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          StatusPill(status: item.status),
          const SizedBox(height: 18),
          Text(
            'Set status',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (!isRefund && isClosed)
            Text(
              'Closed reports cannot be changed.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (isRefund && !canTakeRefundAction)
            Text(
              isClosed
                  ? 'This refund decision is final and cannot be changed.'
                  : 'Only pending refund requests can be approved or rejected.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isRefund)
                  StatusActionChip(
                    label: 'In review',
                    active: item.status == AdminReportQueueFilter.inReview,
                    onTap: () => onStatusChanged(AdminReportQueueFilter.inReview),
                  ),
                StatusActionChip(
                  label: isRefund ? 'Approve' : 'Resolved',
                  active: item.status == AdminReportQueueFilter.resolved,
                  onTap: () => onStatusChanged(AdminReportQueueFilter.resolved),
                ),
                StatusActionChip(
                  label: isRefund ? 'Reject' : 'Rejected',
                  active: item.status == AdminReportQueueFilter.rejected,
                  onTap: () => onStatusChanged(AdminReportQueueFilter.rejected),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class PanelModeTab extends StatelessWidget {
  const PanelModeTab({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? colors.selectedFill : colors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? colorScheme.primary.withValues(alpha: 0.22)
                : colors.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? colorScheme.primary : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: active ? colorScheme.primary : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QueueTab extends StatelessWidget {
  const QueueTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: active ? colorScheme.primary : colors.textSecondary,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class PreviewInfoRow extends StatelessWidget {
  const PreviewInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniInfoChip extends StatelessWidget {
  const MiniInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
  });

  final AdminReportQueueFilter status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = statusStyle(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.foreground),
          const SizedBox(width: 8),
          Text(
            style.label,
            style: textTheme.labelMedium?.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusActionChip extends StatelessWidget {
  const StatusActionChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? colors.selectedFill : colors.inputFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? colorScheme.primary.withValues(alpha: 0.22)
                : colors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: active ? colorScheme.primary : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ReportsPagination extends StatelessWidget {
  const ReportsPagination({
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
        width: 32,
        height: 32,
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

class SpacerOrWrapGap extends StatelessWidget {
  const SpacerOrWrapGap({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return const SizedBox(width: 8);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class StatusStyleData {
  const StatusStyleData({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

StatusStyleData statusStyle(
  BuildContext context,
  AdminReportQueueFilter status,
) {
  final theme = Theme.of(context);
  final colors = theme.appColors;
  final colorScheme = theme.colorScheme;

  switch (status) {
    case AdminReportQueueFilter.open:
      return const StatusStyleData(
        label: 'Open',
        icon: Icons.mark_chat_unread_outlined,
        background: Color(0xFFF0ECCD),
        foreground: Color(0xFF7C6A18),
      );
    case AdminReportQueueFilter.inReview:
      return const StatusStyleData(
        label: 'In review',
        icon: Icons.auto_awesome_outlined,
        background: Color(0xFFE8DCF8),
        foreground: Color(0xFF6E54A8),
      );
    case AdminReportQueueFilter.resolved:
      return StatusStyleData(
        label: 'Resolved',
        icon: Icons.check_rounded,
        background: colors.success.withValues(alpha: 0.14),
        foreground: colors.success,
      );
    case AdminReportQueueFilter.rejected:
      return StatusStyleData(
        label: 'Rejected',
        icon: Icons.close_rounded,
        background: colorScheme.error.withValues(alpha: 0.12),
        foreground: colorScheme.error,
      );
    case AdminReportQueueFilter.all:
      return StatusStyleData(
        label: 'All',
        icon: Icons.inbox_outlined,
        background: colors.inputFill,
        foreground: colors.textSecondary,
      );
  }
}