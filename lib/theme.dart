import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'YekanBakh';

  static ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepBlack,
      onPrimary: AppColors.pureWhite,
      secondary: AppColors.midGray,
      onSecondary: AppColors.deepBlack,
      primaryContainer: AppColors.surfaceOnLight,
      onPrimaryContainer: AppColors.deepBlack,
      secondaryContainer: AppColors.surfaceOnLight,
      onSecondaryContainer: AppColors.deepBlack,
      surface: AppColors.pureWhite,
      onSurface: AppColors.deepBlack,
      onSurfaceVariant: AppColors.midGray,
      outline: AppColors.divider,
      error: AppColors.deepBlack,
    ),
    scaffoldBackgroundColor: AppColors.pureWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.deepBlack,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.deepBlack,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.deepBlack,
      ),
      bodyMedium: TextStyle(height: 1.4, color: AppColors.deepBlack),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.pureWhite,
      onPrimary: AppColors.deepBlack,
      secondary: AppColors.midGray,
      onSecondary: AppColors.deepBlack,
      primaryContainer: AppColors.surfaceOnDark,
      onPrimaryContainer: AppColors.pureWhite,
      secondaryContainer: AppColors.surfaceOnDark,
      onSecondaryContainer: AppColors.pureWhite,
      surface: AppColors.deepBlack,
      onSurface: AppColors.pureWhite,
      onSurfaceVariant: AppColors.midGray,
      outline: AppColors.dividerOnDark,
      error: AppColors.midGray,
    ),
    scaffoldBackgroundColor: AppColors.deepBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.pureWhite,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceOnDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
  );
}
