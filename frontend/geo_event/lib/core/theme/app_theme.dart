import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static const _radiusXl = 26.0;
  static const _radiusLg = 20.0;
  static const _radiusMd = 16.0;

  static ThemeData get lightTheme {
    final base = GoogleFonts.afacadTextTheme();
    final textTheme = _buildTextTheme(base, Brightness.light);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.lightSurfaceSoft,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLightSoft,
      shadow: Color(0x1A000000),
      scrim: Color(0x59000000),
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.textPrimaryDark,
      tertiary: AppColors.primary,
      onTertiary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimaryLight,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        shadowColor: const Color(0x14000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusXl),
          side: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLightSoft,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondaryLight,
        textColor: AppColors.textPrimaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightSurfaceSoft,
          disabledForegroundColor: AppColors.textSecondaryLight,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(
            color: AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceSoft,
        selectedColor: AppColors.lightSelectedFill,
        disabledColor: AppColors.lightSurfaceSoft,
        side: const BorderSide(
          color: AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = GoogleFonts.afacadTextTheme();
    final textTheme = _buildTextTheme(base, Brightness.dark);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.darkSurfaceSoft,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDarkSoft,
      shadow: Color(0x61000000),
      scrim: Color(0x8C000000),
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.textPrimaryLight,
      tertiary: AppColors.primary,
      onTertiary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        shadowColor: const Color(0x33000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusXl),
          side: const BorderSide(
            color: AppColors.borderDark,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDarkSoft,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.borderDark,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.darkSurfaceSoft,
          disabledForegroundColor: AppColors.textSecondaryDark,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(
            color: AppColors.borderDark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceSoft,
        selectedColor: AppColors.darkSelectedFill,
        disabledColor: AppColors.darkSurfaceSoft,
        side: const BorderSide(
          color: AppColors.borderDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: primaryText,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primaryText,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryText,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primaryText,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryText,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: primaryText,
        height: 1.25,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: secondaryText,
        height: 1.22,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: secondaryText,
        height: 1.18,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: secondaryText,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: secondaryText,
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: borderRadius ?? BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}