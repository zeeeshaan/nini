import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared monochrome theme. Feature widgets inherit foreground colors here.
abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : Colors.black;
    final background = isDark ? Colors.black : Colors.white;
    final container = isDark
        ? const Color(0xFF202020)
        : const Color(0xFFF2F2F2);
    final border = isDark ? const Color(0xFF666666) : const Color(0xFFDADADA);
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
          surfaceTint: Colors.transparent,
          outline: border,
          outlineVariant: border,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'YekanBakh',
      colorScheme: scheme,
    );
    final primaryButtonStyle = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      iconColor: WidgetStatePropertyAll(scheme.onPrimary),
      backgroundColor: WidgetStatePropertyAll(scheme.primary),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
    final outlinedButtonStyle = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(foreground),
      iconColor: WidgetStatePropertyAll(foreground),
      backgroundColor: WidgetStatePropertyAll(background),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
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
        labelStyle: TextStyle(color: foreground),
        hintStyle: TextStyle(color: foreground.withValues(alpha: .55)),
        prefixIconColor: foreground,
        suffixIconColor: foreground,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      iconTheme: IconThemeData(color: foreground),
      primaryIconTheme: IconThemeData(color: foreground),
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
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
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: foreground, fontFamily: 'YekanBakh'),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: container,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: foreground, fontFamily: 'YekanBakh'),
      ),
    );
  }
}
