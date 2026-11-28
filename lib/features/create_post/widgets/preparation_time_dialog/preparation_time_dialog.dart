import 'package:flutter/material.dart';

import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/models/post_options.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';

class PreparationTimeDialog extends StatelessWidget {
  const PreparationTimeDialog({super.key, required this.selected});
  final PreparationTime selected;
  @override
  Widget build(BuildContext context) => PostChoiceDialog<PreparationTime>(
    title: CreatePostStrings.preparationTime,
    selected: selected,
    values: PreparationTime.values,
    label: (value) => CreatePostStrings.optionLabel(value),
    tall: true,
  );
}
