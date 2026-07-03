import 'package:flutter/material.dart';

import 'package:geo_event/core/widgets/feedback/app_spinner.dart';

class ReportSubmitButton extends StatelessWidget {
  static const String _buttonText = 'Submit report';

  final bool enabled;
  final bool loading;
  final String? disabledReason;
  final VoidCallback onPressed;

  const ReportSubmitButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedDisabledReason = disabledReason?.trim();

    final button = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: AppSpinner(
                  size: 20,
                  strokeWidth: 2.4,
                ),
              )
            : const Text(_buttonText),
      ),
    );

    if (enabled ||
        resolvedDisabledReason == null ||
        resolvedDisabledReason.isEmpty) {
      return button;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: 8),
        Text(
          resolvedDisabledReason,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}