import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TeamSearchField extends StatelessWidget {
  const TeamSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => AppTextField(
    hint: "جستجو",
    onChanged: onChanged,
    prefixIcon: const Center(
      widthFactor: 1,
      heightFactor: 1,
      child: AppIcon(AppIcons.search, size: 18),
    ),
  );
}
