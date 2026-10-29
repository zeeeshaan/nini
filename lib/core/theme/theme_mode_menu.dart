import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// An accessible selector for explicit light/dark modes or the device setting.
class ThemeModeMenu extends StatelessWidget {
  const ThemeModeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return PopupMenuButton<ThemeMode>(
          tooltip: AppStrings.appearance,
          initialValue: mode,
          onSelected: context.read<ThemeCubit>().setThemeMode,
          icon: AppIcon(isDark ? AppIcons.moon : AppIcons.sun, size: 25),
          itemBuilder: (context) => [
            for (final option in ThemeMode.values)
              CheckedPopupMenuItem<ThemeMode>(
                value: option,
                checked: mode == option,
                child: Text(switch (option) {
                  ThemeMode.system => AppStrings.systemTheme,
                  ThemeMode.light => AppStrings.lightTheme,
                  ThemeMode.dark => AppStrings.darkTheme,
                }, textDirection: TextDirection.rtl),
              ),
          ],
        );
      },
    );
  }
}
