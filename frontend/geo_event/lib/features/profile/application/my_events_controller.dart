import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/my_events/data/my_events_api.dart';
import '../../../shared/my_events/data/my_events_repository.dart';
import '../../../shared/my_events/models/my_event_response_dto.dart';

const int kMyEventsDefaultPageSize = 20;
const int kMyEventsMaxPageSize = 50;

final myEventsApiProvider = Provider<MyEventsApi>((ref) {
  return MyEventsApi(ref.watch(authorizedDioProvider));
});

final myEventsRepositoryProvider = Provider<MyEventsRepository>((ref) {
  return MyEventsRepository(ref.watch(myEventsApiProvider));
});

final myEventsProvider =
    AsyncNotifierProvider<MyEventsController, MyEventsState>(
  MyEventsController.new,
);

class MyEventsState {
  final List<MyEventResponseDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchTerm;
  final String selectedStatus;

  const MyEventsState({
    this.items = const [],
    this.page = 1,
    this.pageSize = kMyEventsDefaultPageSize,
    this.totalCount = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchTerm = '',
    this.selectedStatus = 'All',
  });

  MyEventsState copyWith({
    List<MyEventResponseDto>? items,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchTerm,
    String? selectedStatus,
  }) {
    return MyEventsState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class MyEventsController extends AsyncNotifier<MyEventsState> {
  MyEventsRepository get _repository => ref.read(myEventsRepositoryProvider);

  @override
  Future<MyEventsState> build() async {
    return _loadFirstPage();
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadFirstPage(
        searchTerm: current?.searchTerm ?? '',
        selectedStatus: current?.selectedStatus ?? 'All',
      ),
    );
  }

  Future<void> applyFilters({
    required String searchTerm,
    required String selectedStatus,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadFirstPage(
        searchTerm: searchTerm,
        selectedStatus: selectedStatus,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;

      final result = await _repository.getMyEvents(
        page: nextPage,
        pageSize: current.pageSize,
        searchTerm: current.searchTerm,
        status: current.selectedStatus,
        canViewReservations: null,
      );

      final mergedItems = [...current.items, ...result.items];

      state = AsyncData(
        current.copyWith(
          items: mergedItems,
          page: result.page,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          hasMore: (result.page * result.pageSize) < result.totalCount,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<bool> deleteEvent(int eventId) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    try {
      await _repository.deleteEvent(eventId);

      final updatedItems = current.items
          .where((event) => event.eventId != eventId)
          .toList(growable: false);

      final updatedTotalCount =
          current.totalCount > 0 ? current.totalCount - 1 : 0;

      state = AsyncData(
        current.copyWith(
          items: updatedItems,
          totalCount: updatedTotalCount,
          hasMore: (current.page * current.pageSize) < updatedTotalCount,
        ),
      );

      return true;
    } catch (_) {
      state = AsyncData(current);
      return false;
    }
  }

  Future<MyEventsState> _loadFirstPage({
    String searchTerm = '',
    String selectedStatus = 'All',
  }) async {
    final result = await _repository.getMyEvents(
      page: 1,
      pageSize: kMyEventsDefaultPageSize,
      searchTerm: searchTerm,
      status: selectedStatus,
      canViewReservations: null,
    );

    return MyEventsState(
      items: result.items,
      page: result.page,
      pageSize: result.pageSize,
      totalCount: result.totalCount,
      hasMore: (result.page * result.pageSize) < result.totalCount,
      isLoadingMore: false,
      searchTerm: searchTerm,
      selectedStatus: selectedStatus,
    );
  }
}