import 'package:flutter_riverpod/legacy.dart';
import 'package:geo_event_desktop/shared/admin_profile/data/admin_refunds_repository.dart';

import '../providers/admin_refunds_providers.dart';

enum AdminRefundQueueFilter {
  all,
  open,
  inReview,
  resolved,
  rejected,
}

class AdminRefundRequestsPage {
  final List<AdminRefundRequest> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const AdminRefundRequestsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages {
    if (totalCount <= 0 || pageSize <= 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  factory AdminRefundRequestsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? const [];

    return AdminRefundRequestsPage(
      items: rawItems is List
          ? rawItems
              .map(
                (e) => AdminRefundRequest.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(growable: false)
          : const [],
      totalCount:
          ((json['totalCount'] ?? json['TotalCount']) as num?)?.toInt() ?? 0,
      page: ((json['page'] ?? json['Page']) as num?)?.toInt() ?? 1,
      pageSize: ((json['pageSize'] ?? json['PageSize']) as num?)?.toInt() ?? 10,
    );
  }
}

class AdminRefundRequest {
  final int reservationId;
  final String refundRequestId;

  final int eventId;
  final String eventTitle;
  final String? eventImageUrl;

  final int userId;
  final String requesterName;
  final String requesterUsername;
  final String? requesterAvatarUrl;

  final String targetName;
  final String targetUsername;

  final String title;
  final String preview;
  final String fullContent;

  final double amount;
  final String currency;
  final String amountLabel;

  final String queueStatusRaw;
  final String refundRequestStatusRaw;

  final DateTime? createdAt;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final int? reviewedByUserId;
  final String? decisionReason;
  final String? moderatorAction;

  final String? paymentMethod;
  final String? paymentStatus;

  const AdminRefundRequest({
    required this.reservationId,
    required this.refundRequestId,
    required this.eventId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.userId,
    required this.requesterName,
    required this.requesterUsername,
    required this.requesterAvatarUrl,
    required this.targetName,
    required this.targetUsername,
    required this.title,
    required this.preview,
    required this.fullContent,
    required this.amount,
    required this.currency,
    required this.amountLabel,
    required this.queueStatusRaw,
    required this.refundRequestStatusRaw,
    required this.createdAt,
    required this.requestedAt,
    required this.reviewedAt,
    required this.reviewedByUserId,
    required this.decisionReason,
    required this.moderatorAction,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  AdminRefundQueueFilter get queueFilter {
    switch (queueStatusRaw.trim().toLowerCase()) {
      case 'open':
        return AdminRefundQueueFilter.open;
      case 'inreview':
      case 'in_review':
      case 'in review':
        return AdminRefundQueueFilter.inReview;
      case 'resolved':
        return AdminRefundQueueFilter.resolved;
      case 'rejected':
        return AdminRefundQueueFilter.rejected;
      default:
        return AdminRefundQueueFilter.open;
    }
  }

  bool get isClosed =>
      queueFilter == AdminRefundQueueFilter.resolved ||
      queueFilter == AdminRefundQueueFilter.rejected;

  bool get canTakeAction =>
      queueFilter == AdminRefundQueueFilter.open &&
      refundRequestStatusRaw.trim().toLowerCase() == 'pending';

  String get requesterHandle {
    final value = requesterUsername.trim();
    if (value.isEmpty) return '@unknown';
    return value.startsWith('@') ? value : '@$value';
  }

  String get targetHandle {
    final value = targetUsername.trim();
    if (value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }

  factory AdminRefundRequest.fromJson(Map<String, dynamic> json) {
    return AdminRefundRequest(
      reservationId:
          ((json['reservationId'] ?? json['ReservationId']) as num?)?.toInt() ?? 0,
      refundRequestId:
          (json['refundRequestId'] ?? json['RefundRequestId'] ?? '')
              .toString()
              .trim(),
      eventId: ((json['eventId'] ?? json['EventId']) as num?)?.toInt() ?? 0,
      eventTitle: (json['eventTitle'] ?? json['EventTitle'] ?? '')
          .toString()
          .trim(),
      eventImageUrl: _normalizeNullableString(
        json['eventImageUrl'] ?? json['EventImageUrl'],
      ),
      userId: ((json['userId'] ?? json['UserId']) as num?)?.toInt() ?? 0,
      requesterName: (json['requesterName'] ?? json['RequesterName'] ?? '')
          .toString()
          .trim(),
      requesterUsername:
          (json['requesterUsername'] ?? json['RequesterUsername'] ?? '')
              .toString()
              .trim(),
      requesterAvatarUrl: _normalizeNullableString(
        json['requesterAvatarUrl'] ?? json['RequesterAvatarUrl'],
      ),
      targetName: (json['targetName'] ?? json['TargetName'] ?? '')
          .toString()
          .trim(),
      targetUsername:
          (json['targetUsername'] ?? json['TargetUsername'] ?? '')
              .toString()
              .trim(),
      title: (json['title'] ?? json['Title'] ?? '').toString().trim(),
      preview: (json['preview'] ?? json['Preview'] ?? '').toString().trim(),
      fullContent:
          (json['fullContent'] ?? json['FullContent'] ?? '').toString().trim(),
      amount: ((json['amount'] ?? json['Amount']) as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? json['Currency'] ?? '').toString().trim(),
      amountLabel:
          (json['amountLabel'] ?? json['AmountLabel'] ?? '').toString().trim(),
      queueStatusRaw:
          (json['queueStatus'] ?? json['QueueStatus'] ?? '').toString().trim(),
      refundRequestStatusRaw:
          (json['refundRequestStatus'] ?? json['RefundRequestStatus'] ?? '')
              .toString()
              .trim(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt']),
      requestedAt: _parseDateTime(json['requestedAt'] ?? json['RequestedAt']),
      reviewedAt: _parseDateTime(json['reviewedAt'] ?? json['ReviewedAt']),
      reviewedByUserId:
          ((json['reviewedByUserId'] ?? json['ReviewedByUserId']) as num?)
              ?.toInt(),
      decisionReason: _normalizeNullableString(
        json['decisionReason'] ?? json['DecisionReason'],
      ),
      moderatorAction: _normalizeNullableString(
        json['moderatorAction'] ?? json['ModeratorAction'],
      ),
      paymentMethod: _normalizeNullableString(
        json['paymentMethod'] ?? json['PaymentMethod'],
      ),
      paymentStatus: _normalizeNullableString(
        json['paymentStatus'] ?? json['PaymentStatus'],
      ),
    );
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

enum AdminRefundSortField {
  createdAt,
  status,
  amount,
}

class AdminRefundRequestsQuery {
  final AdminRefundQueueFilter status;
  final String? search;
  final AdminRefundSortField sortBy;
  final bool descending;
  final int page;
  final int pageSize;
  final int? eventId;

  const AdminRefundRequestsQuery({
    this.status = AdminRefundQueueFilter.all,
    this.search,
    this.sortBy = AdminRefundSortField.createdAt,
    this.descending = true,
    this.page = 1,
    this.pageSize = 10,
    this.eventId,
  });

  AdminRefundRequestsQuery copyWith({
    AdminRefundQueueFilter? status,
    String? search,
    AdminRefundSortField? sortBy,
    bool? descending,
    int? page,
    int? pageSize,
    int? eventId,
    bool clearSearch = false,
    bool clearEventId = false,
  }) {
    return AdminRefundRequestsQuery(
      status: status ?? this.status,
      search: clearSearch ? null : search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      eventId: clearEventId ? null : eventId ?? this.eventId,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final map = <String, dynamic>{
      'status': _statusToApi(status),
      'search': _normalizeNullableString(search),
      'sortBy': _sortByToApi(sortBy),
      'descending': descending,
      'page': page,
      'pageSize': pageSize,
      'eventId': eventId,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  static String? _statusToApi(AdminRefundQueueFilter value) {
    switch (value) {
      case AdminRefundQueueFilter.all:
        return null;
      case AdminRefundQueueFilter.open:
        return 'Open';
      case AdminRefundQueueFilter.inReview:
        return 'InReview';
      case AdminRefundQueueFilter.resolved:
        return 'Resolved';
      case AdminRefundQueueFilter.rejected:
        return 'Rejected';
    }
  }

  static String _sortByToApi(AdminRefundSortField value) {
    switch (value) {
      case AdminRefundSortField.createdAt:
        return 'createdAt';
      case AdminRefundSortField.status:
        return 'status';
      case AdminRefundSortField.amount:
        return 'amount';
    }
  }

  static String? _normalizeNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class AdminRefundsState {
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final AdminRefundRequestsQuery query;
  final AdminRefundRequestsPage? pageData;

  const AdminRefundsState({
    required this.isLoading,
    required this.isActionLoading,
    required this.errorMessage,
    required this.query,
    required this.pageData,
  });

  factory AdminRefundsState.initial() {
    return const AdminRefundsState(
      isLoading: false,
      isActionLoading: false,
      errorMessage: null,
      query: AdminRefundRequestsQuery(pageSize: 6),
      pageData: null,
    );
  }

  List<AdminRefundRequest> get items => pageData?.items ?? const [];
  int get totalCount => pageData?.totalCount ?? 0;
  int get page => pageData?.page ?? query.page;
  int get totalPages => pageData?.totalPages ?? 1;

  AdminRefundsState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    AdminRefundRequestsQuery? query,
    AdminRefundRequestsPage? pageData,
    bool clearError = false,
    bool clearPageData = false,
  }) {
    return AdminRefundsState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      pageData: clearPageData ? null : pageData ?? this.pageData,
    );
  }
}

class AdminRefundsNotifier extends StateNotifier<AdminRefundsState> {
  AdminRefundsNotifier(this.repository) : super(AdminRefundsState.initial());

  final AdminRefundsRepository repository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await repository.getRefundRequests(state.query);
      state = state.copyWith(
        isLoading: false,
        pageData: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
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

  Future<void> setStatusFilter(AdminRefundQueueFilter value) async {
    state = state.copyWith(
      query: state.query.copyWith(
        status: value,
        page: 1,
      ),
    );
    await load();
  }

  Future<void> setSortField(AdminRefundSortField value) async {
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
    if (page <= 0) return;

    state = state.copyWith(
      query: state.query.copyWith(page: page),
    );
    await load();
  }

  Future<void> approveRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearError: true,
    );

    try {
      await repository.approveRefund(
        eventId: eventId,
        reservationId: reservationId,
        decisionReason: decisionReason,
        moderatorAction: moderatorAction,
      );

      state = state.copyWith(isActionLoading: false);
      await load();
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> rejectRefund({
    required int eventId,
    required int reservationId,
    String? decisionReason,
    String? moderatorAction,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearError: true,
    );

    try {
      await repository.rejectRefund(
        eventId: eventId,
        reservationId: reservationId,
        decisionReason: decisionReason,
        moderatorAction: moderatorAction,
      );

      state = state.copyWith(isActionLoading: false);
      await load();
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final adminRefundsNotifierProvider =
    StateNotifierProvider<AdminRefundsNotifier, AdminRefundsState>((ref) {
  return AdminRefundsNotifier(ref.watch(adminRefundsRepositoryProvider));
});