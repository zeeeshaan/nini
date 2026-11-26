import 'package:flutter/material.dart';

import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';

class PostPublishActions extends StatelessWidget {
  const PostPublishActions({
    super.key,
    required this.publishing,
    required this.onCancel,
    required this.onPublish,
    this.isEditing = false,
  });
  final bool publishing;
  final bool isEditing;
  final VoidCallback onCancel, onPublish;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final primaryLabel = isEditing
        ? (publishing
              ? ProfilePostStrings.saving
              : ProfilePostStrings.saveChanges)
        : (publishing
              ? CreatePostStrings.publishing
              : CreatePostStrings.publish);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: theme.dividerColor, width: .5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: CreatePostStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: publishing ? null : onCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: primaryLabel,
                    isLoading: publishing,
                    onPressed: onPublish,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
