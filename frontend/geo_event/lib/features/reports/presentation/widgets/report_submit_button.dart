import 'package:flutter/material.dart';
import 'package:geo_event/core/widgets/app_spinner.dart';

class ReportSubmitButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const ReportSubmitButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            : const Text('Submit report'),
      ),
    );
  }
}