import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

Future<bool> confirmChatAction(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = popupSheetTheme(context);
        return Theme(
          data: theme,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              title,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
            content: Text(
              description,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: AppStrings.cancel,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ) ??
    false;
