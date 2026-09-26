import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SimpleApp());
}

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  static const _locale = Locale('fa', 'IR');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'های‌ورک',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // Persian is the only UI language: every screen, dialog, picker and
          // snackbar is laid out right-to-left.
          locale: _locale,
          supportedLocales: const [_locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const SplashScreen(),
        );
      },
    );
  }
}
