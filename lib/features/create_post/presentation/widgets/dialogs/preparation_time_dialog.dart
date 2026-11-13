import 'package:flutter/material.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';

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
