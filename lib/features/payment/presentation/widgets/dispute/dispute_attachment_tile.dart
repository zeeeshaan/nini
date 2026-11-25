import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/dispute_attachment.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class DisputeAttachmentTile extends StatelessWidget {
  const DisputeAttachmentTile({
    super.key,
    required this.attachment,
    this.onRemove,
  });
  final DisputeAttachment attachment;
  final VoidCallback? onRemove;

  Future<void> _open(BuildContext context) async {
    try {
      final result = await OpenFilex.open(attachment.path);
      if (result.type != ResultType.done && context.mounted) {
        AppToast.warning(context, AppStrings.fileOpenFailed);
      }
    } catch (_) {
      if (context.mounted) AppToast.warning(context, AppStrings.fileOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    onTap: () => _open(context),
    leading: attachment.isImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(attachment.path),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) =>
                  const AppIcon(AppIcons.imageUnavailable),
            ),
          )
        : const AppIcon(AppIcons.document),
    title: Text(
      attachment.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    ),
    trailing: onRemove == null
        ? null
        : IconButton(
            tooltip: ReceiptStrings.removeAttachment,
            onPressed: onRemove,
            icon: const AppIcon(AppIcons.close, size: 18),
          ),
  );
}
