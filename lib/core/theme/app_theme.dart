import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Shared monochrome theme. Feature widgets inherit foreground colors here.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final foreground = isDark ? AppColors.white : AppColors.black;
    final background = isDark ? AppColors.black : AppColors.white;
    final container = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;
    final border = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: foreground,
          brightness: brightness,
        ).copyWith(
          primary: foreground,
          onPrimary: background,
          primaryContainer: container,
          onPrimaryContainer: foreground,
          secondary: foreground,
          onSecondary: background,
          secondaryContainer: container,
          onSecondaryContainer: foreground,
          tertiary: foreground,
          onTertiary: background,
          tertiaryContainer: container,
          onTertiaryContainer: foreground,
          surface: background,
          onSurface: foreground,
          onSurfaceVariant: foreground,
          surfaceContainerLowest: background,
          surfaceContainerLow: container,
          surfaceContainer: container,
          surfaceContainerHigh: container,
          surfaceContainerHighest: container,
          surfaceDim: container,
          surfaceBright: background,
          surfaceTint: AppColors.transparent,
          outline: border,
          outlineVariant: border,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
    );
    final primaryButtonStyle = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      iconColor: WidgetStatePropertyAll(scheme.onPrimary),
      backgroundColor: WidgetStatePropertyAll(scheme.primary),
      surfaceTintColor: const WidgetStatePropertyAll(AppColors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    final outlinedButtonStyle = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(foreground),
      iconColor: WidgetStatePropertyAll(foreground),
      backgroundColor: WidgetStatePropertyAll(background),
      surfaceTintColor: const WidgetStatePropertyAll(AppColors.transparent),
      side: WidgetStatePropertyAll(BorderSide(color: border)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: background,
      dividerColor: border,
      disabledColor: foreground,
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: foreground),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: AppTextStyles.inherit.copyWith(color: foreground),
        hintStyle: AppTextStyles.inherit.copyWith(
          color: foreground.withValues(alpha: .55),
        ),
        prefixIconColor: foreground,
        suffixIconColor: foreground,
      ),
      textTheme: base.textTheme
          .merge(AppTextStyles.materialTextTheme)
          .apply(bodyColor: foreground, displayColor: foreground),
      iconTheme: IconThemeData(color: foreground),
      primaryIconTheme: IconThemeData(color: foreground),
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(foreground),
          iconColor: WidgetStatePropertyAll(foreground),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(foreground),
          iconColor: WidgetStatePropertyAll(foreground),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: background,
        surfaceTintColor: AppColors.transparent,
        textStyle: AppTextStyles.inherit.copyWith(
          color: foreground,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: container,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: AppTextStyles.inherit.copyWith(
          color: foreground,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
    );
  }
}
