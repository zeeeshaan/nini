import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/theme/app_colors.dart';

class PostDeleteActions extends StatelessWidget {
  const PostDeleteActions({
    super.key,
    required this.busy,
    required this.deleting,
    required this.onDelete,
  });
  final bool busy, deleting;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            ProfilePostStrings.cancel,
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: AppColors.white,
          ),
          onPressed: busy ? null : onDelete,
          child: Text(
            deleting
                ? ProfilePostStrings.deleting
                : ProfilePostStrings.deletePost,
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ],
  );
}
