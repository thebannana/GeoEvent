import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.disabledReason,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const AppSpinner(size: 18, strokeWidth: 2)
                : Text(label),
          ),
        ),
        if (isLoading && disabledReason != null) ...[
          const SizedBox(height: 8),
          Text(
            disabledReason!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}