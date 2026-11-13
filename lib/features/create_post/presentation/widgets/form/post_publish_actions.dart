import 'package:flutter/material.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class PostPublishActions extends StatelessWidget {
  const PostPublishActions({
    super.key,
    required this.publishing,
    required this.onCancel,
    required this.onPublish,
  });
  final bool publishing;
  final VoidCallback onCancel, onPublish;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
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
                    label: publishing
                        ? CreatePostStrings.publishing
                        : CreatePostStrings.publish,
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
