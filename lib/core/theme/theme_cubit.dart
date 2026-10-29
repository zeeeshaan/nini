import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A session-level preference. System mode follows platform brightness live.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeMode initialMode = ThemeMode.system}) : super(initialMode);

  void setThemeMode(ThemeMode mode) => emit(mode);

  void useSystemTheme() => setThemeMode(ThemeMode.system);

  /// Uses the rendered brightness, including when the preference is "system".
  void toggleTheme(Brightness currentBrightness) => setThemeMode(
    currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );
}
