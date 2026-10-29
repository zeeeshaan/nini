import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';

class UnitDialog extends StatelessWidget {
  const UnitDialog({super.key, required this.selected});
  final PostUnit selected;
  @override
  Widget build(BuildContext context) => PostChoiceDialog<PostUnit>(
    title: AppStrings.unit,
    icon: AppIcons.ruler,
    selected: selected,
    values: PostUnit.values,
    label: (value) => value.label,
    tall: true,
  );
}
