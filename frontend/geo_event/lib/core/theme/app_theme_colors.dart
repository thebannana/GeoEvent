import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color card;
  final Color inputFill;
  final Color selectedFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderSoft;
  final Color success;
  final Color warning;
  final Color info;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.card,
    required this.inputFill,
    required this.selectedFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderSoft,
    required this.success,
    required this.warning,
    required this.info,
  });

  const AppThemeColors.light()
      : background = const Color(0xFFF5F6F8),
        surface = const Color(0xFFFFFFFF),
        surfaceSoft = const Color(0xFFF0F2F5),
        card = const Color(0xFFFFFFFF),
        inputFill = const Color(0xFFF2F4F7),
        selectedFill = const Color(0xFFE8EEFF),
        textPrimary = const Color(0xFF171A1F),
        textSecondary = const Color(0xFF6B7280),
        border = const Color(0xFFD9DEE7),
        borderSoft = const Color(0xFFE8ECF2),
        success = const Color(0xFF2E7D32),
        warning = const Color(0xFFED6C02),
        info = const Color(0xFF0288D1);

  const AppThemeColors.dark()
      : background = const Color(0xFF111315),
        surface = const Color(0xFF181B1F),
        surfaceSoft = const Color(0xFF20242A),
        card = const Color(0xFF1A1D21),
        inputFill = const Color(0xFF20242A),
        selectedFill = const Color(0xFF273248),
        textPrimary = const Color(0xFFF3F4F6),
        textSecondary = const Color(0xFFA1A8B3),
        border = const Color(0xFF30353D),
        borderSoft = const Color(0xFF252A31),
        success = const Color(0xFF66BB6A),
        warning = const Color(0xFFFFB74D),
        info = const Color(0xFF4FC3F7);

  static const primary = Color(0xFF5B7CFA);
  static const error = Color(0xFFD84C4C);

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSoft,
    Color? card,
    Color? inputFill,
    Color? selectedFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? borderSoft,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      card: card ?? this.card,
      inputFill: inputFill ?? this.inputFill,
      selectedFill: selectedFill ?? this.selectedFill,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      card: Color.lerp(card, other.card, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      selectedFill: Color.lerp(selectedFill, other.selectedFill, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppThemeColorsX on ThemeData {
  AppThemeColors get appColors => extension<AppThemeColors>()!;
}