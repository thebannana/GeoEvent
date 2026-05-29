import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/bookmarks/application/bookmark_controller.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bookmarksProvider.notifier).refresh(),
        child: bookmarksAsync.when(
          loading: () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: const [
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (_, __) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: _TopMessageState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Failed to load bookmarks',
                    subtitle: 'Pull to refresh or try again.',
                    actionLabel: 'Retry',
                      onAction: () => ref.read(bookmarksProvider.notifier).refresh(),
                  ),
                ),
              ),
            ],
          ),
          data: (bookmarks) {
            final filtered = bookmarks.where((b) {
              final q = _query.trim().toLowerCase();
              if (q.isEmpty) return true;
              final memo = (b.memo ?? '').toLowerCase();
              final eventId = b.eventId.toString();
              return memo.contains(q) || eventId.contains(q);
            }).toList();

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
                        hintText: 'Search bookmarks',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _TopPill(
                          label: 'All',
                          selected: true,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _TopPill(
                          label: '${filtered.length}',
                          selected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _TopMessageState(
                        icon: Icons.bookmark_border_rounded,
                        title: bookmarks.isEmpty
                            ? 'No bookmarks yet'
                            : 'No matching bookmarks',
                        subtitle: bookmarks.isEmpty
                            ? 'Saved events will appear here.'
                            : 'Try a different search term.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _BookmarkCard(
                          title: (item.memo != null && item.memo!.trim().isNotEmpty)
                              ? item.memo!.trim()
                              : 'Saved event #${item.eventId}',
                          subtitle: 'Event ID: ${item.eventId}',
                          savedText: 'Saved ${_formatDate(item.savedAt)}',
                          imageUrl: item.imageUrl,
                          isDark: isDark,
                          onDelete: () => ref
                              .read(bookmarksProvider.notifier)
                              .deleteBookmark(item.bookmarkId),
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
  final bool isDark;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.title,
    required this.subtitle,
    required this.savedText,
    required this.imageUrl,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? const Color(0xFF17191D) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A303A)
                  : const Color(0xFFE5EAF2),
            ),
          ),
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
                            onSelected: (value) {
                              if (value == 'delete') onDelete();
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Remove'),
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
                            Icons.bookmark_rounded,
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
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;

  const _CardImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 98,
        height: 92,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _CardImageFallback(),
              )
            : const _CardImageFallback(),
      ),
    );
  }
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 28),
    );
  }
}

class _TopPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : theme.dividerColor.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _TopMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}