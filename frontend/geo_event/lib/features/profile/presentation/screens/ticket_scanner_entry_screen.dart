import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/my_events_controller.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import 'ticket_scanner_screen.dart';

class TicketScannerEntryScreen extends ConsumerWidget {
  const TicketScannerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    Future<void> onRefresh() async {
      await ref.read(myEventsProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket scanner')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: myEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.event_busy_rounded, size: 42),
                  SizedBox(height: 12),
                  Center(
                    child: Text('You do not manage any events.'),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 14, bottom: 20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];

                return TicketScannerEventCard(
                  event: event,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TicketScannerScreen(
                          eventId: event.eventId,
                          eventTitle: event.title,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 220),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Center(child: Text('$error')),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketScannerEventCard extends StatelessWidget {
  final MyEventResponseDto event;
  final VoidCallback onTap;

  const TicketScannerEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _segmentColor() {
    final source = (
      event.segmentName ??
      event.genreName ??
      event.subGenreName ??
      ''
    ).toLowerCase();

    if (source.contains('concert') || source.contains('music')) {
      return const Color(0xFF5E7BFF);
    }
    if (source.contains('sport')) {
      return const Color(0xFFFF5A76);
    }
    if (source.contains('education') || source.contains('seminar')) {
      return const Color(0xFF68C95A);
    }
    return const Color(0xFF6B8FBF);
  }

  String _formatPrice(num? price) {
    if (price == null || price <= 0) return 'Free';
    if (price % 1 == 0) return '${price.toInt()}\$';
    return '${price.toStringAsFixed(2)}\$';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _segmentColor();

    final subtitleParts = [
      if ((event.segmentName ?? '').isNotEmpty) event.segmentName!,
      if ((event.genreName ?? '').isNotEmpty) event.genreName!,
    ];
    final subtitle = subtitleParts.join(' · ');

    final imageUrl = event.coverImageUrl ??
        ((event.imageUrls.isNotEmpty) ? event.imageUrls.first : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2028) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: SizedBox(
                    width: 82,
                    height: 96,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return _TicketScannerImageFallback(accent: accent);
                            },
                          )
                        : _TicketScannerImageFallback(accent: accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Scan tickets',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF3F6FA),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    _formatPrice(event.price),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Open scanner',
                              onPressed: onTap,
                              icon: const Icon(Icons.chevron_right_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF3F6FA),
                                foregroundColor: accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketScannerImageFallback extends StatelessWidget {
  final Color accent;

  const _TicketScannerImageFallback({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.90),
      alignment: Alignment.center,
      child: const Icon(
        Icons.qr_code_scanner_rounded,
        size: 30,
        color: Colors.white,
      ),
    );
  }
}