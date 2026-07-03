import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/bookmarks/models/bookmark.dart';
import '../../../../shared/bookmarks/providers/bookmark_providers.dart';
import '../../../../shared/likes/models/liked_event.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';

enum SavedFilterType { saved, liked }

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  SavedFilterType _selectedFilter = SavedFilterType.saved;
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved event removed successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the saved event.'),
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked event removed successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the liked event.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  bool _matchesBookmark(Bookmark item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    final title = item.title.trim().toLowerCase();
    final memo = (item.memo ?? '').trim().toLowerCase();

    return title.contains(normalizedQuery) || memo.contains(normalizedQuery);
  }

  bool _matchesLikedEvent(LikedEvent item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return item.title.trim().toLowerCase().contains(normalizedQuery);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final likedAsync = ref.watch(likedEventsProvider);

    final isInitialLoading =
        (bookmarksAsync.isLoading && !bookmarksAsync.hasValue) ||
        (likedAsync.isLoading && !likedAsync.hasValue);

    final hasInitialError =
        (bookmarksAsync.hasError && !bookmarksAsync.hasValue) ||
        (likedAsync.hasError && !likedAsync.hasValue);

    final bookmarks = bookmarksAsync.valueOrNull ?? const <Bookmark>[];
    final likedEvents = likedAsync.valueOrNull ?? const <LikedEvent>[];

    final normalizedQuery = _query.trim().toLowerCase();

    final filteredBookmarks = bookmarks
        .where((item) =>
            _selectedFilter == SavedFilterType.saved &&
            _matchesBookmark(item, normalizedQuery))
        .toList();

    final filteredLiked = likedEvents
        .where((item) =>
            _selectedFilter == SavedFilterType.liked &&
            _matchesLikedEvent(item, normalizedQuery))
        .toList();

    final selectedCount = _selectedFilter == SavedFilterType.saved
        ? filteredBookmarks.length
        : filteredLiked.length;

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
                      message: 'Pull to refresh or try again.',
                      onRetry: _refreshAll,
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: _selectedFilter == SavedFilterType.saved
                            ? 'Search saved events'
                            : 'Search liked events',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
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
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppChip(
                          label: 'Saved',
                          selected: _selectedFilter == SavedFilterType.saved,
                          onTap: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFilter = SavedFilterType.saved;
                                  });
                                },
                        ),
                        AppChip(
                          label: 'Liked',
                          selected: _selectedFilter == SavedFilterType.liked,
                          onTap: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFilter = SavedFilterType.liked;
                                  });
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
                if (_selectedFilter == SavedFilterType.saved &&
                    filteredBookmarks.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: bookmarks.isEmpty
                            ? 'No saved events yet'
                            : 'No matching saved events',
                        message: bookmarks.isEmpty
                            ? 'Saved events will appear here.'
                            : 'Try a different search term.',
                      ),
                    ),
                  )
                else if (_selectedFilter == SavedFilterType.liked &&
                    filteredLiked.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: likedEvents.isEmpty
                            ? 'No liked events yet'
                            : 'No matching liked events',
                        message: likedEvents.isEmpty
                            ? 'Liked events will appear here.'
                            : 'Try a different search term.',
                      ),
                    ),
                  )
                else if (_selectedFilter == SavedFilterType.saved)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filteredBookmarks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredBookmarks[index];

                        return _SavedEventCard(
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
                      itemCount: filteredLiked.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredLiked[index];

                        return _LikedEventCard(
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

class _SavedEventCard extends StatelessWidget {
  const _SavedEventCard({
    required this.item,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final Bookmark item;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.memo?.trim().isNotEmpty == true
        ? item.memo!.trim()
        : 'Saved on ${_formatDate(item.savedAt)}';

    return _BookmarkCard(
      title: item.title,
      subtitle: subtitle,
      imageUrl: item.imageUrl,
      icon: Icons.bookmark_rounded,
      accentColor: Theme.of(context).colorScheme.primary,
      removeLabel: 'Remove',
      helperText: 'Tap to open event details',
      disabled: disabled,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

class _LikedEventCard extends StatelessWidget {
  const _LikedEventCard({
    required this.item,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final LikedEvent item;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return _BookmarkCard(
      title: item.title,
      subtitle: 'Liked on ${_formatDate(item.likedAt)}',
      imageUrl: item.imageUrl,
      icon: Icons.favorite_rounded,
      accentColor: Theme.of(context).colorScheme.error,
      removeLabel: 'Unlike',
      helperText: 'Open event details',
      disabled: disabled,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.accentColor,
    required this.removeLabel,
    required this.helperText,
    required this.disabled,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final Color accentColor;
  final String removeLabel;
  final String helperText;
  final bool disabled;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: AppSurfaceCard(
        onTap: disabled ? null : onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title.trim().isNotEmpty ? title.trim() : 'Saved event',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          enabled: !disabled,
                          tooltip: 'More actions',
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(removeLabel),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            helperText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 98,
        height: 92,
        child: hasImage
            ? Image.network(
                normalizedUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return const _CardImageFallback(loading: true);
                },
                errorBuilder: (_, _, _) => const _CardImageFallback(),
              )
            : const _CardImageFallback(),
      ),
    );
  }
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const AppSpinner(size: 22, strokeWidth: 2)
            : Icon(
                Icons.image_not_supported_outlined,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}