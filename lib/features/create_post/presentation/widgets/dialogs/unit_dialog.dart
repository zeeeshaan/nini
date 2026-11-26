import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/domain/models/post_options.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';

class UnitDialog extends StatelessWidget {
  const UnitDialog({super.key, required this.selected});
  final PostUnit selected;
  @override
  Widget build(BuildContext context) => PostChoiceDialog<PostUnit>(
    title: CreatePostStrings.unit,
    icon: AppIcons.ruler,
    selected: selected,
    values: PostUnit.values,
    label: (value) => CreatePostStrings.optionLabel(value),
    tall: true,
  );
}
