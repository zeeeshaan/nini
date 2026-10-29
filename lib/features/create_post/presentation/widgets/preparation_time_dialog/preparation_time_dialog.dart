import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';

class PreparationTimeDialog extends StatelessWidget {
  const PreparationTimeDialog({super.key, required this.selected});
  final PreparationTime selected;
  @override
  Widget build(BuildContext context) => PostChoiceDialog<PreparationTime>(
    title: AppStrings.preparationTime,
    selected: selected,
    values: PreparationTime.values,
    label: (value) => value.label,
    tall: true,
  );
}
