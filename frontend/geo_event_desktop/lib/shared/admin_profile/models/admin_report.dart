import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/utils/json_helpers.dart';
import '../data/admin_reports_repository.dart';
import '../providers/admin_reports_providers.dart';

enum AdminReportQueueFilter {
  all,
  open,
  inReview,
  resolved,
  rejected,
  unknown,
}

enum AdminReportSortField {
  createdAt,
  status,
  type,
  reporter,
}

enum AdminReportEntityType {
  user,
  event,
  comment,
  review,
  unknown,
}

class AdminReportsPage {
  final List<AdminReport> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const AdminReportsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages {
    if (totalCount <= 0 || pageSize <= 0) {
      return 1;
    }

    return (totalCount / pageSize).ceil();
  }

  factory AdminReportsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? const [];

    return AdminReportsPage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => AdminReport.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      totalCount: JsonHelpers.asInt(
            json['totalCount'] ?? json['TotalCount'],
          ) ??
          0,
      page: JsonHelpers.asInt(
            json['page'] ?? json['Page'],
          ) ??
          1,
      pageSize: JsonHelpers.asInt(
            json['pageSize'] ?? json['PageSize'],
          ) ??
          10,
    );
  }
}

class AdminReport {
  final int reportId;
  final String targetTypeRaw;
  final int? targetId;
  final String targetDisplay;
  final String? targetUsername;

  final String reason;
  final String? description;
  final String preview;
  final String statusRaw;

  final int? reporterId;
  final String reporterUsername;
  final String? reporterDisplayName;

  final int? resolvedById;
  final String? resolvedByUsername;
  final String? resolvedByDisplayName;

  final String? resolutionNote;
  final String? moderatorAction;

  /// Parsed through JsonHelpers and stored in UTC.
  final DateTime? createdAt;

  /// Parsed through JsonHelpers and stored in UTC.
  final DateTime? resolvedAt;

  const AdminReport({
    required this.reportId,
    required this.targetTypeRaw,
    required this.targetId,
    required this.targetDisplay,
    required this.targetUsername,
    required this.reason,
    required this.description,
    required this.preview,
    required this.statusRaw,
    required this.reporterId,
    required this.reporterUsername,
    required this.reporterDisplayName,
    required this.resolvedById,
    required this.resolvedByUsername,
    required this.resolvedByDisplayName,
    required this.resolutionNote,
    required this.moderatorAction,
    required this.createdAt,
    required this.resolvedAt,
  });

  String get reportIdLabel => '#$reportId';

  AdminReportEntityType get entityType {
    switch (targetTypeRaw.trim().toLowerCase()) {
      case 'user':
        return AdminReportEntityType.user;

      case 'event':
        return AdminReportEntityType.event;

      case 'comment':
        return AdminReportEntityType.comment;

      case 'review':
        return AdminReportEntityType.review;

      default:
        return AdminReportEntityType.unknown;
    }
  }

  AdminReportQueueFilter get queueFilter {
    switch (statusRaw.trim().toLowerCase()) {
      case 'pending':
        return AdminReportQueueFilter.open;

      case 'underreview':
      case 'under_review':
      case 'under review':
        return AdminReportQueueFilter.inReview;

      case 'resolved':
        return AdminReportQueueFilter.resolved;

      case 'dismissed':
        return AdminReportQueueFilter.rejected;

      default:
        return AdminReportQueueFilter.unknown;
    }
  }

  String get title {
    final value = reason.trim();

    if (value.isNotEmpty) {
      return value;
    }

    final descriptionValue = description?.trim() ?? '';

    if (descriptionValue.isNotEmpty) {
      return descriptionValue.length > 80
          ? '${descriptionValue.substring(0, 80).trimRight()}...'
          : descriptionValue;
    }

    return 'Report';
  }

  String get fullContent {
    final value = description?.trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }

    final reasonValue = reason.trim();

    if (reasonValue.isNotEmpty) {
      return reasonValue;
    }

    return 'No additional details provided.';
  }

  String get previewText {
    final value = preview.trim();

    if (value.isNotEmpty) {
      return value;
    }

    final full = fullContent;

    if (full.length <= 120) {
      return full;
    }

    return '${full.substring(0, 120).trimRight()}...';
  }

  String get reporterName {
    final full = reporterDisplayName?.trim() ?? '';

    if (full.isNotEmpty) {
      return full;
    }

    final username = reporterUsername.trim();

    return username.isNotEmpty ? username : 'Unknown reporter';
  }

  String get reporterHandle {
    final value = reporterUsername.trim();

    if (value.isEmpty) {
      return '@unknown';
    }

    return value.startsWith('@') ? value : '@$value';
  }

  String get reportedName {
    final value = targetDisplay.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'Unknown target';
  }

  String get reportedHandle {
    final value = targetUsername?.trim();

    if (value == null || value.isEmpty) {
      return '';
    }

    return value.startsWith('@') ? value : '@$value';
  }

  String get resolvedByName {
    final full = resolvedByDisplayName?.trim() ?? '';

    if (full.isNotEmpty) {
      return full;
    }

    final username = resolvedByUsername?.trim() ?? '';

    if (username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }

    return '—';
  }

  String get moderationSummary {
    final parts = <String>[
      if ((moderatorAction?.trim() ?? '').isNotEmpty)
        moderatorAction!.trim(),
      if ((resolutionNote?.trim() ?? '').isNotEmpty)
        resolutionNote!.trim(),
    ];

    if (parts.isEmpty) {
      return 'No moderation note.';
    }

    return parts.join(' • ');
  }

  bool get isClosed {
    return queueFilter == AdminReportQueueFilter.resolved ||
        queueFilter == AdminReportQueueFilter.rejected;
  }

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    return AdminReport(
      reportId: JsonHelpers.asInt(
            json['reportId'] ?? json['ReportId'],
          ) ??
          0,
      targetTypeRaw:
          (json['targetType'] ?? json['TargetType'] ?? '')
              .toString()
              .trim(),
      targetId: JsonHelpers.asInt(
        json['targetId'] ?? json['TargetId'],
      ),
      targetDisplay:
          (json['targetDisplay'] ?? json['TargetDisplay'] ?? '')
              .toString()
              .trim(),
      targetUsername: JsonHelpers.normalize(
        json['targetUsername'] ?? json['TargetUsername'],
      ),
      reason: (json['reason'] ?? json['Reason'] ?? '').toString().trim(),
      description: JsonHelpers.normalize(
        json['description'] ?? json['Description'],
      ),
      preview: (json['preview'] ?? json['Preview'] ?? '')
          .toString()
          .trim(),
      statusRaw: (json['status'] ?? json['Status'] ?? '')
          .toString()
          .trim(),
      reporterId: JsonHelpers.asInt(
        json['reporterId'] ?? json['ReporterId'],
      ),
      reporterUsername:
          (json['reporterUsername'] ?? json['ReporterUsername'] ?? '')
              .toString()
              .trim(),
      reporterDisplayName: JsonHelpers.normalize(
        json['reporterDisplayName'] ?? json['ReporterDisplayName'],
      ),
      resolvedById: JsonHelpers.asInt(
        json['resolvedById'] ?? json['ResolvedById'],
      ),
      resolvedByUsername: JsonHelpers.normalize(
        json['resolvedByUsername'] ?? json['ResolvedByUsername'],
      ),
      resolvedByDisplayName: JsonHelpers.normalize(
        json['resolvedByDisplayName'] ?? json['ResolvedByDisplayName'],
      ),
      resolutionNote: JsonHelpers.normalize(
        json['resolutionNote'] ?? json['ResolutionNote'],
      ),
      moderatorAction: JsonHelpers.normalize(
        json['moderatorAction'] ?? json['ModeratorAction'],
      ),
      createdAt: JsonHelpers.parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
      ),
      resolvedAt: JsonHelpers.parseDateTime(
        json['resolvedAt'] ?? json['ResolvedAt'],
      ),
    );
  }
}

class AdminReportsQuery {
  final AdminReportQueueFilter status;
  final AdminReportEntityType? targetType;
  final String? search;
  final AdminReportSortField sortBy;
  final bool descending;
  final int page;
  final int pageSize;

  const AdminReportsQuery({
    this.status = AdminReportQueueFilter.all,
    this.targetType,
    this.search,
    this.sortBy = AdminReportSortField.createdAt,
    this.descending = true,
    this.page = 1,
    this.pageSize = 10,
  });

  AdminReportsQuery copyWith({
    AdminReportQueueFilter? status,
    AdminReportEntityType? targetType,
    String? search,
    AdminReportSortField? sortBy,
    bool? descending,
    int? page,
    int? pageSize,
    bool clearTargetType = false,
    bool clearSearch = false,
  }) {
    return AdminReportsQuery(
      status: status ?? this.status,
      targetType: clearTargetType ? null : targetType ?? this.targetType,
      search: clearSearch ? null : search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final map = <String, dynamic>{
      'status': _statusToApi(status),
      'targetType': targetType != null ? _typeToApi(targetType!) : null,
      'search': JsonHelpers.normalize(search),
      'sortBy': _sortByToApi(sortBy),
      'descending': descending,
      'page': page,
      'pageSize': pageSize,
    };

    map.removeWhere((key, value) => value == null);

    return map;
  }

  static String? _statusToApi(AdminReportQueueFilter value) {
    switch (value) {
      case AdminReportQueueFilter.all:
        return null;

      case AdminReportQueueFilter.open:
        return 'Pending';

      case AdminReportQueueFilter.inReview:
        return 'UnderReview';

      case AdminReportQueueFilter.resolved:
        return 'Resolved';

      case AdminReportQueueFilter.rejected:
        return 'Dismissed';

      case AdminReportQueueFilter.unknown:
        return null;
    }
  }

  static String _sortByToApi(AdminReportSortField value) {
    switch (value) {
      case AdminReportSortField.createdAt:
        return 'createdAt';

      case AdminReportSortField.status:
        return 'status';

      case AdminReportSortField.type:
        return 'type';

      case AdminReportSortField.reporter:
        return 'reporter';
    }
  }

  static String? _typeToApi(AdminReportEntityType value) {
    switch (value) {
      case AdminReportEntityType.user:
        return 'User';

      case AdminReportEntityType.event:
        return 'Event';

      case AdminReportEntityType.comment:
        return 'Comment';

      case AdminReportEntityType.review:
        return 'Review';

      case AdminReportEntityType.unknown:
        return null;
    }
  }
}

class AdminReportsState {
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final AdminReportsQuery query;
  final AdminReportsPage? pageData;

  const AdminReportsState({
    required this.isLoading,
    required this.isActionLoading,
    required this.errorMessage,
    required this.query,
    required this.pageData,
  });

  factory AdminReportsState.initial() {
    return const AdminReportsState(
      isLoading: false,
      isActionLoading: false,
      errorMessage: null,
      query: AdminReportsQuery(pageSize: 6),
      pageData: null,
    );
  }

  List<AdminReport> get items => pageData?.items ?? const [];

  int get totalCount => pageData?.totalCount ?? 0;

  int get page => pageData?.page ?? query.page;

  int get totalPages => pageData?.totalPages ?? 1;

  AdminReportsState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    AdminReportsQuery? query,
    AdminReportsPage? pageData,
    bool clearError = false,
    bool clearPageData = false,
  }) {
    return AdminReportsState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      pageData: clearPageData ? null : pageData ?? this.pageData,
    );
  }
}

class AdminReportsNotifier extends StateNotifier<AdminReportsState> {
  AdminReportsNotifier(this.repository)
      : super(AdminReportsState.initial());

  final AdminReportsRepository repository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await repository.getReports(state.query);

      state = state.copyWith(
        isLoading: false,
        pageData: result,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(error),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> setSearch(String value) async {
    state = state.copyWith(
      query: state.query.copyWith(
        search: value,
        page: 1,
        clearSearch: value.trim().isEmpty,
      ),
    );

    await load();
  }

  Future<void> setStatusFilter(AdminReportQueueFilter value) async {
    state = state.copyWith(
      query: state.query.copyWith(
        status: value,
        page: 1,
      ),
    );

    await load();
  }

  Future<void> setTargetType(AdminReportEntityType? value) async {
    state = state.copyWith(
      query: state.query.copyWith(
        targetType: value,
        page: 1,
        clearTargetType: value == null,
      ),
    );

    await load();
  }

  Future<void> setSortField(AdminReportSortField value) async {
    final sameField = state.query.sortBy == value;

    state = state.copyWith(
      query: state.query.copyWith(
        sortBy: value,
        descending: sameField ? !state.query.descending : true,
        page: 1,
      ),
    );

    await load();
  }

  Future<void> goToPage(int page) async {
    if (page <= 0) {
      return;
    }

    state = state.copyWith(
      query: state.query.copyWith(page: page),
    );

    await load();
  }

  Future<void> updateStatus({
    required int reportId,
    required AdminReportQueueFilter status,
    String? resolutionNote,
    String? moderatorAction,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearError: true,
    );

    try {
      final updated = await repository.updateReportStatus(
        reportId: reportId,
        status: status,
        resolutionNote: resolutionNote,
        moderatorAction: moderatorAction,
      );

      final currentItems = [...state.items];
      final index = currentItems.indexWhere(
        (item) => item.reportId == reportId,
      );

      if (index != -1) {
        currentItems[index] = updated;

        final currentPage = state.pageData;

        state = state.copyWith(
          isActionLoading: false,
          pageData: currentPage == null
              ? null
              : AdminReportsPage(
                  items: currentItems,
                  totalCount: currentPage.totalCount,
                  page: currentPage.page,
                  pageSize: currentPage.pageSize,
                ),
        );

        return;
      }

      final refreshed = await repository.getReports(state.query);

      state = state.copyWith(
        isActionLoading: false,
        pageData: refreshed,
      );
    } catch (error) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _cleanErrorMessage(error),
      );
    }
  }

  String _cleanErrorMessage(Object error) {
    final text = error.toString().trim();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length).trim();
    }

    return text;
  }
}

final adminReportsNotifierProvider =
    StateNotifierProvider<AdminReportsNotifier, AdminReportsState>((ref) {
  return AdminReportsNotifier(
    ref.watch(adminReportsRepositoryProvider),
  );
});