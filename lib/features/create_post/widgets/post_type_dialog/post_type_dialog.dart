import 'package:flutter/material.dart';

import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';

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
