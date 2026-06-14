import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_async_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/profile/models/activity_log.dart';
import '../../../../shared/profile/providers/profile_providers.dart';
import '../widgets/activity_log_tile.dart';

class ActivityLogsScreen extends ConsumerWidget {
  const ActivityLogsScreen({super.key});

  static const _params = (page: 1, pageSize: 20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(myActivityLogsProvider(_params));

    Future<void> refresh() async {
      ref.invalidate(myActivityLogsProvider(_params));
      await ref.read(myActivityLogsProvider(_params).future);
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Activity log'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: refresh,
        child: AppAsyncView<List<ActivityLog>>(
          value: logsAsync,
          isEmpty: (logs) => logs.isEmpty,
          empty: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: const [
              AppEmptyState(
                title: 'No activity found',
                message: 'Your recent account activity will appear here.',
                icon: Icons.history_rounded,
              ),
            ],
          ),
          errorBuilder: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppErrorState(
                title: 'Failed to load activity log',
                message: 'Pull to refresh and try again.',
                onRetry: () => ref.invalidate(myActivityLogsProvider(_params)),
              ),
            ],
          ),
          data: (logs) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              return AppSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: ActivityLogTile(log: log),
              );
            },
          ),
        ),
      ),
    );
  }
}