import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/reports/models/report_state.dart';
import '../../../../shared/reports/models/report_target_type.dart';
import '../../application/report_controller.dart';
import '../widgets/report_reason_selector.dart';
import '../widgets/report_submit_button.dart';
import '../widgets/report_target_preview.dart';
import '../widgets/report_text_field.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final ReportTargetType targetType;
  final int targetId;
  final String? targetTitle;
  final String? targetSubtitle;
  final String? targetImageUrl;

  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
    this.targetSubtitle,
    this.targetImageUrl,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late final TextEditingController _detailsController;
  late final ReportState _initialState;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
    _initialState = ReportState(
      targetType: widget.targetType,
      targetId: widget.targetId,
      targetTitle: widget.targetTitle,
      targetSubtitle: widget.targetSubtitle,
      targetImageUrl: widget.targetImageUrl,
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = reportControllerProvider(_initialState);
    final state = ref.watch(provider);
    final ctrl = ref.read(provider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassScaffold(
      appBar: AppBar(
        title: Text('Report ${widget.targetType.displayName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text(
              'What is the reason for your report?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the option that best describes the issue. You can add more details below.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ReportTargetPreview(
              targetType: state.targetType,
              title: state.targetTitle,
              subtitle: state.targetSubtitle,
              imageUrl: state.targetImageUrl,
            ),
            const SizedBox(height: 18),
            ReportReasonSelector(
              selected: state.selectedReason,
              onSelected: ctrl.selectReason,
            ),
            const SizedBox(height: 8),
            ReportTextField(
              controller: _detailsController,
              onChanged: ctrl.setDescription,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            ReportSubmitButton(
              enabled: state.canSubmit,
              loading: state.isSubmitting,
              onPressed: () async {
                final success = await ctrl.submit();
                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully.'),
                    ),
                  );
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}