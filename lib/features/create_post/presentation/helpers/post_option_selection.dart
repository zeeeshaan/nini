import 'package:flutter/material.dart';

import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';

Future<void> choosePostOption<T>(
  BuildContext context,
  Widget dialog,
  ValueChanged<T> onSelected,
) async {
  final value = await showPostDialog<T>(context, dialog);
  if (context.mounted && value != null) onSelected(value);
}
