import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../../../shared/profile/models/activity_log.dart';

final activityLogsProvider = FutureProvider<List<ActivityLog>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getActivityLogs(page: 1, pageSize: 20);
});

class ActivityLogsScreen extends ConsumerWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity log'),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No activity found.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text('${log.actionType} • ${log.targetType}'),
                  subtitle: Text(
                    log.metadata.trim().isEmpty
                        ? 'Target ID: ${log.targetId}'
                        : log.metadata,
                  ),
                  trailing: Text(
                    _formatDate(log.createdAt),
                    textAlign: TextAlign.end,
                  ),
                ),
              );
            },
          );
        },
        error: (_, __) => const Center(
          child: Text('Failed to load activity logs.'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final date = dateTime.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year\n$hour:$minute';
  }
}