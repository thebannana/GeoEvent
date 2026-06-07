import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/preferences_controller.dart';
import '../../../../shared/profile/models/user_preference.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Affinity Preferences'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(preferencesControllerProvider.notifier).refresh(),
        child: prefsAsync.when(
          data: (prefs) {
            final segmentPrefs = prefs
                .where((p) => p.segmentId != null)
                .toList()
              ..sort((a, b) {
                final byScore = b.score.compareTo(a.score);
                if (byScore != 0) return byScore;
                return (a.segmentId ?? 0).compareTo(b.segmentId ?? 0);
              });

            final genrePrefs = prefs
                .where((p) => p.genreId != null)
                .toList()
              ..sort((a, b) {
                final byScore = b.score.compareTo(a.score);
                if (byScore != 0) return byScore;
                return (a.genreId ?? 0).compareTo(b.genreId ?? 0);
              });

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _AffinityExplainerCard(),
                const SizedBox(height: 16),
                _PreferenceSection(
                  title: 'Segments',
                  icon: Icons.category_rounded,
                  preferences: segmentPrefs,
                  emptyMessage: 'No segment affinities have been recorded yet.',
                  isDark: isDark,
                  onTap: (pref) => _showEditDialog(context, ref, pref),
                ),
                const SizedBox(height: 16),
                _PreferenceSection(
                  title: 'Genres',
                  icon: Icons.local_offer_rounded,
                  preferences: genrePrefs,
                  emptyMessage: 'No genre affinities have been recorded yet.',
                  isDark: isDark,
                  onTap: (pref) => _showEditDialog(context, ref, pref),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _AffinityExplainerCard(),
              const SizedBox(height: 16),
              _PreferencesStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Failed to load affinity data',
                subtitle: 'Pull to refresh or try again.',
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(preferencesControllerProvider.notifier).refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserPreference pref,
  ) async {
    final formKey = GlobalKey<FormState>();
    final scoreController = TextEditingController(
      text: pref.score.toStringAsFixed(1),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(_prefTitle(pref)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: scoreController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Score (0–100)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final score = double.tryParse((value ?? '').trim());
                    if (score == null) return 'Enter a valid number';
                    if (score < 0 || score > 100) {
                      return 'Score must be between 0 and 100';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setLocalState(() => saving = true);

                          try {
                            final score =
                                double.parse(scoreController.text.trim());

                            await ref
                                .read(preferencesControllerProvider.notifier)
                                .upsert(
                                  segmentId: pref.segmentId,
                                  genreId: pref.genreId,
                                  score: score,
                                );

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Affinity score updated.'),
                                ),
                              );
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not update affinity score.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setLocalState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    scoreController.dispose();
  }

  String _prefTitle(UserPreference pref) {
    if (pref.segmentId != null) {
      return 'Segment #${pref.segmentId}';
    }
    if (pref.genreId != null) {
      return 'Genre #${pref.genreId}';
    }
    return 'Preference #${pref.prefId}';
  }
}

class _AffinityExplainerCard extends StatelessWidget {
  const _AffinityExplainerCard();

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
          color: isDark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'What affinity means',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Affinity scores show how strongly a user is associated with event segments and genres. '
            'The app is intended to update these values automatically from user behavior such as browsing, liking, bookmarking, and similar activity.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'For demonstration purposes, the professor can also edit these scores manually. '
            'Higher scores indicate stronger affinity, and values are ordered from highest to lowest.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<UserPreference> preferences;
  final String emptyMessage;
  final bool isDark;
  final ValueChanged<UserPreference> onTap;

  const _PreferenceSection({
    required this.title,
    required this.icon,
    required this.preferences,
    required this.emptyMessage,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (preferences.isEmpty)
          _PreferencesStateCard(
            icon: icon,
            title: 'Nothing here yet',
            subtitle: emptyMessage,
          )
        else
          ...preferences.map(
            (pref) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PreferenceTile(
                preference: pref,
                isDark: isDark,
                onTap: () => onTap(pref),
              ),
            ),
          ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final UserPreference preference;
  final bool isDark;
  final VoidCallback onTap;

  const _PreferenceTile({
    required this.preference,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSegment = preference.segmentId != null;
    final title = isSegment
        ? 'Segment #${preference.segmentId}'
        : 'Genre #${preference.genreId}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17191D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isSegment ? Icons.category_rounded : Icons.local_offer_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score: ${preference.score.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (preference.score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _PreferencesStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PreferencesStateCard({
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
          color: isDark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
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