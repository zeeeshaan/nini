import 'package:flutter/material.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';

enum ChatMessageDeleteAction { deleteMyMessage }

/// Confirms Swagger `DELETE /chats/{id}/messages/{messageId}` (“Delete my
/// message”: soft `deleted: true`; peers get `chat:message_deleted`).
Future<ChatMessageDeleteAction?> showChatMessageDeleteSheet(
  BuildContext context,
) {
  final theme = popupSheetTheme(context);
  return showModalBottomSheet<ChatMessageDeleteAction>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    builder: (sheetContext) {
      return Theme(
        data: theme,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  AppStrings.deleteMyMessage,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  ChatMessageDeleteAction.deleteMyMessage,
                ),
              ),
              ListTile(
                title: const Text(
                  AppStrings.cancel,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}
