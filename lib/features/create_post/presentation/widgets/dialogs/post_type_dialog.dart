import 'package:flutter/material.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';

class TypePostDialog extends StatelessWidget {
  const TypePostDialog({super.key, this.selected});
  final CreatePostType? selected;
  @override
  Widget build(BuildContext context) => PostChoiceDialog<CreatePostType>(
    title: CreatePostStrings.postType,
    selected: selected,
    values: CreatePostType.values,
    label: (value) => value == CreatePostType.product
        ? CreatePostStrings.product
        : CreatePostStrings.services,
  );
}
