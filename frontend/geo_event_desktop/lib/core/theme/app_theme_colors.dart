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
      : background = const Color(0xFFF9FCFF),
        surface = const Color(0xFFFFFFFF),
        surfaceSoft = const Color(0xFFF3F6F9),
        card = const Color(0xFFFFFFFF),
        inputFill = const Color(0xFFF3F6F9),
        selectedFill = const Color(0xFFEAF4F8),
        textPrimary = const Color(0xFF1E2A36),
        textSecondary = const Color(0xFF61788A),
        border = const Color(0xFFE1EAF1),
        borderSoft = const Color(0xFFDCE6EE),
        success = const Color(0xFF2F7D57),
        warning = const Color(0xFFB7791F),
        info = const Color(0xFF2C82A6);

  const AppThemeColors.dark()
      : background = const Color(0xFF0F1720),
        surface = const Color(0xFF16212B),
        surfaceSoft = const Color(0xFF1B2A36),
        card = const Color(0xFF18242E),
        inputFill = const Color(0xFF1B2A36),
        selectedFill = const Color(0xFF213848),
        textPrimary = const Color(0xFFEAF2F7),
        textSecondary = const Color(0xFF9BB0BE),
        border = const Color(0xFF29404F),
        borderSoft = const Color(0xFF213442),
        success = const Color(0xFF58A67D),
        warning = const Color(0xFFD39A43),
        info = const Color(0xFF69B7D7);

  static const primary = Color(0xFF2C82A6);
  static const primaryDark = Color(0xFF69B7D7);
  static const accent = Color(0xFF183B56);
  static const accentDark = Color(0xFF8AC6E4);
  static const error = Color(0xFFD65C5C);
  static const errorDark = Color(0xFFFF8A80);

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