import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/theme_cubit.dart';

class ThemeOptions extends StatelessWidget {
  const ThemeOptions({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, mode) => RadioGroup<ThemeMode>(
      groupValue: mode,
      onChanged: (selected) {
        if (selected != null) {
          context.read<ThemeCubit>().setThemeMode(selected);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              AppStrings.appearance,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final option in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: option,
              controlAffinity: ListTileControlAffinity.trailing,
              title: Text(switch (option) {
                ThemeMode.system => AppStrings.systemTheme,
                ThemeMode.light => AppStrings.lightTheme,
                ThemeMode.dark => AppStrings.darkTheme,
              }, textAlign: TextAlign.right),
            ),
        ],
      ),
    ),
  );
}
