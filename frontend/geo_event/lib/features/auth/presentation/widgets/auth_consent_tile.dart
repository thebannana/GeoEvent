import 'package:flutter/material.dart';

class AuthConsentTile extends FormField<bool> {
  AuthConsentTile({
    super.key,
    required String title,
    super.validator,
    bool enabled = true,
    super.initialValue = false,
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
                  onChanged: enabled ? state.didChange : null,
                  title: Text(title),
                  subtitle: Text(
                    enabled
                        ? 'Required to create your account.'
                        : 'Consent cannot be changed while registration is in progress.',
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