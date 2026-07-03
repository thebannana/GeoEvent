import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_colors.dart';
import 'app_theme_metrics.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final themeColors = isDark
        ? const AppThemeColors.dark()
        : const AppThemeColors.light();

    final base = GoogleFonts.afacadTextTheme();
    final textTheme = _buildTextTheme(base, themeColors);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppThemeColors.primary,
      onPrimary: Colors.white,
      secondary: AppThemeColors.primary,
      onSecondary: Colors.white,
      error: AppThemeColors.error,
      onError: Colors.white,
      surface: themeColors.surface,
      onSurface: themeColors.textPrimary,
      surfaceContainerHighest: themeColors.surfaceSoft,
      outline: themeColors.border,
      outlineVariant: themeColors.borderSoft,
      shadow: isDark ? const Color(0x61000000) : const Color(0x1A000000),
      scrim: isDark ? const Color(0x8C000000) : const Color(0x59000000),
      inverseSurface: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF181B1F),
      onInverseSurface: isDark ? const Color(0xFF171A1F) : const Color(0xFFF3F4F6),
      tertiary: AppThemeColors.primary,
      onTertiary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: themeColors.background,
      canvasColor: themeColors.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        themeColors,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.background,
        foregroundColor: themeColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: themeColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: themeColors.card,
        shadowColor: isDark ? const Color(0x33000000) : const Color(0x14000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusXl),
          side: BorderSide(color: themeColors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: themeColors.borderSoft,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: themeColors.textSecondary,
        textColor: themeColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusSm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeColors.inputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: themeColors.textSecondary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: themeColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppThemeColors.error,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppThemeMetrics.inputHorizontal,
          vertical: AppThemeMetrics.inputVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
          borderSide: BorderSide(color: themeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
          borderSide: BorderSide(color: themeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
          borderSide: const BorderSide(
            color: AppThemeColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
          borderSide: const BorderSide(
            color: AppThemeColors.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
          borderSide: const BorderSide(
            color: AppThemeColors.error,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: themeColors.surfaceSoft,
          disabledForegroundColor: themeColors.textSecondary,
          minimumSize: const Size.fromHeight(AppThemeMetrics.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textPrimary,
          minimumSize: const Size.fromHeight(AppThemeMetrics.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          side: BorderSide(color: themeColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeMetrics.radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppThemeColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeMetrics.radiusSm),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: themeColors.surfaceSoft,
        selectedColor: themeColors.selectedFill,
        disabledColor: themeColors.surfaceSoft,
        side: BorderSide(color: themeColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: themeColors.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppThemeMetrics.radiusXl + 2),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: themeColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeMetrics.radiusLg),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, AppThemeColors colors) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: colors.textPrimary,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: colors.textPrimary,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: colors.textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: colors.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: colors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: colors.textPrimary,
        height: 1.25,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: colors.textSecondary,
        height: 1.22,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: colors.textSecondary,
        height: 1.18,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}