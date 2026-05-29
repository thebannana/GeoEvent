import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/preferences_controller.dart';
import '../../../../shared/profile/models/user_preference.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add preference',
            onPressed: () => _showUpsertDialog(context, ref, null),
          ),
        ],
      ),
      body: prefsAsync.when(
        data: (prefs) {
          if (prefs.isEmpty) {
            return const Center(child: Text('No preferences set yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: prefs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pref = prefs[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_rounded),
                title: Text(_prefTitle(pref)),
                subtitle: Text('Score: ${pref.score.toStringAsFixed(1)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => ref
                      .read(preferencesProvider.notifier)
                      .delete(pref.prefId),
                ),
                onTap: () => _showUpsertDialog(context, ref, pref),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Failed to load preferences.')),
      ),
    );
  }

  String _prefTitle(UserPreference pref) {
    final parts = <String>[];
    if (pref.segmentId != null) parts.add('Segment #${pref.segmentId}');
    if (pref.genreId != null) parts.add('Genre #${pref.genreId}');
    return parts.isEmpty ? 'Preference #${pref.prefId}' : parts.join(' • ');
  }

  Future<void> _showUpsertDialog(
      BuildContext context, WidgetRef ref, UserPreference? existing) async {
    final scoreController = TextEditingController(
        text: existing?.score.toStringAsFixed(1) ?? '50.0');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add preference' : 'Edit preference'),
        content: TextField(
          controller: scoreController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Score (0–100)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final score = double.tryParse(scoreController.text) ?? 50.0;
              await ref.read(preferencesProvider.notifier).upsert(
                    segmentId: existing?.segmentId,
                    genreId: existing?.genreId,
                    score: score,
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}