import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/bookmarks/providers/bookmark_providers.dart';
import '../../../../shared/likes/providers/liked_events_providers.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';

enum SavedFilterType { saved, liked }

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  SavedFilterType _selectedFilter = SavedFilterType.saved;

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

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final likedAsync = ref.watch(likedEventsProvider);

    final isLoading = bookmarksAsync.isLoading || likedAsync.isLoading;
    final hasError = bookmarksAsync.hasError || likedAsync.hasError;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Builder(
          builder: (context) {
            if (isLoading &&
                !bookmarksAsync.hasValue &&
                !likedAsync.hasValue) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingIndicator(
                      title: 'Loading bookmarks',
                      message: 'Please wait while we load your saved items.',
                    ),
                  ),
                ],
              );
            }

            if (hasError &&
                !bookmarksAsync.hasValue &&
                !likedAsync.hasValue) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorState(
                      title: 'Failed to load bookmarks',
                      message: 'Pull to refresh or try again.',
                      onRetry: _refreshAll,
                    ),
                  ),
                ],
              );
            }

            final bookmarks = bookmarksAsync.valueOrNull ?? const [];
            final likedEvents = likedAsync.valueOrNull ?? const [];

            final q = _query.trim().toLowerCase();

            final filteredBookmarks = bookmarks.where((b) {
              if (_selectedFilter != SavedFilterType.saved) return false;
              if (b.eventId == null) return false;
              if (q.isEmpty) return true;

              final memo = (b.memo ?? '').toLowerCase();
              final eventId = b.eventId.toString();
              return memo.contains(q) || eventId.contains(q);
            }).toList();

            final filteredLiked = likedEvents.where((e) {
              if (_selectedFilter != SavedFilterType.liked) return false;
              if (q.isEmpty) return true;

              final title = e.title.toLowerCase();
              final eventId = e.eventId.toString();
              return title.contains(q) || eventId.contains(q);
            }).toList();

            final selectedCount = _selectedFilter == SavedFilterType.saved
                ? filteredBookmarks.length
                : filteredLiked.length;

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
                        hintText: 'Search saved or liked events',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppChip(
                          label: 'Saved',
                          selected: _selectedFilter == SavedFilterType.saved,
                          onTap: () {
                            setState(() {
                              _selectedFilter = SavedFilterType.saved;
                            });
                          },
                        ),
                        AppChip(
                          label: 'Liked',
                          selected: _selectedFilter == SavedFilterType.liked,
                          onTap: () {
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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredBookmarks[index];
                        final eventId = item.eventId!;

                        return _BookmarkCard(
                          title: (item.memo != null &&
                                  item.memo!.trim().isNotEmpty)
                              ? item.memo!.trim()
                              : 'Saved event #$eventId',
                          subtitle: 'Event ID: $eventId',
                          savedText: 'Saved ${_formatDate(item.savedAt)}',
                          imageUrl: item.imageUrl,
                          icon: Icons.bookmark_rounded,
                          removeLabel: 'Remove',
                          onTap: () => _openEventDetails(context, eventId),
                          onDelete: () async {
                            try {
                              await ref
                                  .read(bookmarksProvider.notifier)
                                  .deleteBookmark(item.bookmarkId);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bookmark removed.'),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not remove bookmark.'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filteredLiked.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredLiked[index];

                        return _BookmarkCard(
                          title: item.title.trim().isNotEmpty
                              ? item.title.trim()
                              : 'Liked event #${item.eventId}',
                          subtitle: 'Event ID: ${item.eventId}',
                          savedText: 'Liked ${_formatDate(item.likedAt)}',
                          imageUrl: item.imageUrl,
                          icon: Icons.favorite_rounded,
                          removeLabel: 'Unlike',
                          onTap: () =>
                              _openEventDetails(context, item.eventId),
                          onDelete: () async {
                            try {
                              await ref
                                  .read(likedEventsProvider.notifier)
                                  .unlikeEvent(item.eventId);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Removed from liked events.'),
                                ),
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not update liked event.',
                                  ),
                                ),
                              );
                            }
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
    );
  }

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

class _BookmarkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String savedText;
  final String? imageUrl;
  final IconData icon;
  final String removeLabel;
  final VoidCallback? onTap;
  final Future<void> Function() onDelete;

  const _BookmarkCard({
    required this.title,
    required this.subtitle,
    required this.savedText,
    required this.imageUrl,
    required this.icon,
    required this.removeLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurfaceCard(
      onTap: onTap,
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
                          title,
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
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
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
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          savedText,
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
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;

  const _CardImage({required this.imageUrl});

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
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return const _CardImageFallback(loading: true);
                },
                errorBuilder: (_, __, ___) =>
                    const _CardImageFallback(),
              )
            : const _CardImageFallback(),
      ),
    );
  }
}

class _CardImageFallback extends StatelessWidget {
  final bool loading;

  const _CardImageFallback({
    this.loading = false,
  });

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