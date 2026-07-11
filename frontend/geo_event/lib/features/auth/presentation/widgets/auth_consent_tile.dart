import 'package:flutter/material.dart';

class AuthConsentTile extends FormField<bool> {
  AuthConsentTile({
    super.key,
    required String title,
    super.validator,
    bool enabled = true,
    super.initialValue = false,
    ValueChanged<bool?>? onChanged,
    String requiredSubtitle = 'Required to create your account.',
    String disabledSubtitle =
        'Consent cannot be changed while registration is in progress.',
  }) : super(
          builder: (state) {
            final theme = Theme.of(state.context);
            final errorText = state.errorText;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.value ?? false,
                  onChanged: enabled
                      ? (value) {
                          state.didChange(value);
                          onChanged?.call(value);
                        }
                      : null,
                  title: Text(title),
                  subtitle: Text(
                    enabled ? requiredSubtitle : disabledSubtitle,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      top: 4,
                    ),
                    child: Text(
                      errorText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}