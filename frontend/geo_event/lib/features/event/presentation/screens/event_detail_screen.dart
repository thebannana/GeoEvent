import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/events/data/events_api.dart';
import '../../../../shared/events/models/create_event_models.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final int eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  EventItem? event;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await ref.read(eventsApiProvider).getEventById(widget.eventId);
      if (!mounted) return;
      setState(() {
        event = item;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(error ?? 'Failed to load event.'),
        ),
      );
    }

    final item = event!;
    final imageUrl = (item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty)
        ? item.coverImageUrl!
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
      ),
      body: ListView(
        children: [
          if (imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(item.description),
                const SizedBox(height: 12),
                Text('Price: ${item.price}'),
                Text('Likes: ${item.likesCount}'),
                Text('Views: ${item.viewCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}