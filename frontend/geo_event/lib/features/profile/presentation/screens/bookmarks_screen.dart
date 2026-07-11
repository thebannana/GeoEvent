import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/bookmarks/application/bookmark_controller.dart';
import '../../../../shared/bookmarks/models/bookmark.dart';
import '../../../../shared/likes/models/liked_event.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../widgets/bookmark_event_card.dart';
import '../widgets/list_paging_footer.dart';

enum SavedFilterType { saved, liked }

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  static const _searchDelay = Duration(milliseconds: 350);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(delay: _searchDelay);

  String _query = '';
  SavedFilterType _selectedFilter = SavedFilterType.saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(bookmarksProvider.notifier).loadInitial();
      await ref.read(likedEventsProvider.notifier).loadInitial();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;

    if (_selectedFilter == SavedFilterType.saved) {
      ref.read(bookmarksProvider.notifier).loadMore();
    } else {
      ref.read(likedEventsProvider.notifier).loadMore();
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(bookmarksProvider.notifier).refresh(),
      ref.read(likedEventsProvider.notifier).refresh(),
    ]);
  }

  void _openEventDetails(BuildContext context, int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: eventId),
      ),
    );
  }

  Future<bool> _confirmRemoval({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return AppConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: true,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _removeBookmark(Bookmark item) async {
    if (_busy) return;

    final confirmed = await _confirmRemoval(
      context: context,
      title: 'Remove saved event',
      message: 'This event will be removed from your saved list.',
      confirmLabel: 'Remove',
    );

    if (!confirmed || !mounted) return;

    setState(() => _busy = true);

    try {
      await ref.read(bookmarksProvider.notifier).deleteBookmark(item.bookmarkId);
      _showMessage('Saved event removed successfully.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to remove bookmark.',
        tag: 'BookmarksScreen',
        error: error,
        stackTrace: stackTrace,
      );

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not remove the saved event.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeLikedEvent(LikedEvent item) async {
    if (_busy) return;

    final confirmed = await _confirmRemoval(
      context: context,
      title: 'Remove liked event',
      message: 'This event will be removed from your liked list.',
      confirmLabel: 'Unlike',
    );

    if (!confirmed || !mounted) return;

    setState(() => _busy = true);

    try {
      await ref.read(likedEventsProvider.notifier).unlikeEvent(item.eventId);
      _showMessage('Liked event removed successfully.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to remove liked event.',
        tag: 'BookmarksScreen',
        error: error,
        stackTrace: stackTrace,
      );

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not update the liked event.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);

    _debouncer.runAsync(() async {
      try {
        if (_selectedFilter == SavedFilterType.saved) {
          await ref.read(bookmarksProvider.notifier).search(value);
        } else {
          await ref.read(likedEventsProvider.notifier).refresh();
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to apply bookmarks search.',
          tag: 'BookmarksScreen',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _clearSearch(bool isSavedSelected) async {
    _debouncer.cancel();
    _searchController.clear();
    setState(() => _query = '');

    if (isSavedSelected) {
      await ref.read(bookmarksProvider.notifier).search('');
    } else {
      await ref.read(likedEventsProvider.notifier).refresh();
    }
  }

  Widget _buildFooter({
    required bool loadingMore,
    required bool hasMore,
    required int loadedCount,
    required int totalCount,
  }) {
    return ListPagingFooter(
      isLoadingMore: loadingMore,
      hasMore: hasMore,
      loadedCount: loadedCount,
      totalCount: totalCount,
      itemLabel: _selectedFilter == SavedFilterType.saved
          ? 'saved events'
          : 'liked events',
      onLoadMore: hasMore && !loadingMore
          ? () {
              if (_selectedFilter == SavedFilterType.saved) {
                ref.read(bookmarksProvider.notifier).loadMore();
              } else {
                ref.read(likedEventsProvider.notifier).loadMore();
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksState = ref.watch(bookmarksProvider);
    final likedState = ref.watch(likedEventsProvider);

    final normalizedQuery = _query.trim().toLowerCase();

    final filteredLiked = likedState.items.where((item) {
      if (normalizedQuery.isEmpty) return true;
      return item.title.trim().toLowerCase().contains(normalizedQuery);
    }).toList();

    final isSavedSelected = _selectedFilter == SavedFilterType.saved;
    final currentState = isSavedSelected ? bookmarksState : likedState;

    final selectedCount = isSavedSelected
        ? bookmarksState.totalCount
        : likedState.totalCount;

    final isInitialLoading = currentState.loading && currentState.items.isEmpty;
    final hasInitialError =
        currentState.error != null && currentState.items.isEmpty;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Saved events'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Builder(
          builder: (context) {
            if (isInitialLoading) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingIndicator(
                      title: 'Loading saved items',
                      message: 'Please wait while we load your events.',
                    ),
                  ),
                ],
              );
            }

            if (hasInitialError) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorState(
                      title: 'Failed to load saved items',
                      message: currentState.error!,
                      onRetry: _refreshAll,
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      decoration: InputDecoration(
                        hintText: isSavedSelected
                            ? 'Search saved events'
                            : 'Search liked events',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                onPressed: () => _clearSearch(isSavedSelected),
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
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppChip(
                          label: 'Saved',
                          selected: isSavedSelected,
                          onTap: _busy
                              ? null
                              : () async {
                                  setState(() {
                                    _selectedFilter = SavedFilterType.saved;
                                  });

                                  await ref.read(bookmarksProvider.notifier).loadInitial(
                                        query: _query,
                                        force: true,
                                      );
                                },
                        ),
                        AppChip(
                          label: 'Liked',
                          selected: !isSavedSelected,
                          onTap: _busy
                              ? null
                              : () async {
                                  setState(() {
                                    _selectedFilter = SavedFilterType.liked;
                                  });

                                  await ref
                                      .read(likedEventsProvider.notifier)
                                      .loadInitial(force: true);
                                },
                        ),
                        AppChip(
                          label: '$selectedCount',
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (currentState.error != null && currentState.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AppErrorState(
                        message: currentState.error!,
                        onRetry: isSavedSelected
                            ? () => ref.read(bookmarksProvider.notifier).refresh()
                            : () => ref.read(likedEventsProvider.notifier).refresh(),
                      ),
                    ),
                  ),
                if (isSavedSelected && bookmarksState.items.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No saved events yet',
                        message: 'Saved events will appear here.',
                      ),
                    ),
                  )
                else if (!isSavedSelected && filteredLiked.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: likedState.items.isEmpty
                            ? 'No liked events yet'
                            : 'No matching liked events',
                        message: likedState.items.isEmpty
                            ? 'Liked events will appear here.'
                            : 'Try a different search term.',
                      ),
                    ),
                  )
                else if (isSavedSelected)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: bookmarksState.items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == bookmarksState.items.length) {
                          return _buildFooter(
                            loadingMore: bookmarksState.loadingMore,
                            hasMore: bookmarksState.hasMore,
                            loadedCount: bookmarksState.items.length,
                            totalCount: bookmarksState.totalCount,
                          );
                        }

                        final item = bookmarksState.items[index];

                        return SavedEventCard(
                          item: item,
                          disabled: _busy,
                          onTap: () {
                            final eventId = item.eventId;
                            if (eventId == null || _busy) return;
                            _openEventDetails(context, eventId);
                          },
                          onDelete: () => _removeBookmark(item),
                        );
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filteredLiked.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == filteredLiked.length) {
                          return _buildFooter(
                            loadingMore: likedState.loadingMore,
                            hasMore: likedState.hasMore,
                            loadedCount: likedState.items.length,
                            totalCount: likedState.totalCount,
                          );
                        }

                        final item = filteredLiked[index];

                        return LikedEventCard(
                          item: item,
                          disabled: _busy,
                          onTap: _busy
                              ? null
                              : () => _openEventDetails(context, item.eventId),
                          onDelete: () => _removeLikedEvent(item),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}