import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

import '../../cubit/settings_query_cubit.dart';

class SettingsSearchField extends StatefulWidget {
  const SettingsSearchField({super.key});
  @override
  State<SettingsSearchField> createState() => _SettingsSearchFieldState();
}

class _SettingsSearchFieldState extends State<SettingsSearchField> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsQueryCubit>().state,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: AppTextField(
      controller: _controller,
      hint: ProfileSettingsStrings.searchHint,
      onChanged: context.read<SettingsQueryCubit>().search,
      suffixIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: AppIcon(AppIcons.search, size: 22),
      ),
    ),
  );
}
