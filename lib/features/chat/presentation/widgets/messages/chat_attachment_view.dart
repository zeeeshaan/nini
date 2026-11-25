import 'package:nini/shared/widgets/app_back_button/app_back_button.dart';

import 'dart:io';

import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

import 'package:flutter/material.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:open_filex/open_filex.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/chat/presentation/widgets/media/chat_voice_player.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class ChatAttachmentView extends StatelessWidget {
  const ChatAttachmentView({
    super.key,
    required this.id,
    required this.attachment,
    required this.foreground,
    this.onOpen,
  });
  final String id;
  final ChatAttachment attachment;
  final Color foreground;
  final VoidCallback? onOpen;
  Future<void> _open(BuildContext context) async {
    onOpen?.call();
    if (attachment.type == ChatAttachmentType.image) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),

              actions: [const AppBackButton()],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: .5,
                maxScale: 5,
                child: Image.file(
                  File(attachment.path),
                  errorBuilder: (_, error, stack) =>
                      const AppIcon(AppIcons.imageUnavailable, size: 48),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
    try {
      final result = await OpenFilex.open(attachment.path);
      if (result.type != ResultType.done && context.mounted) {
        AppToast.error(context, AppStrings.fileOpenFailed);
      }
    } catch (_) {
      if (context.mounted) AppToast.error(context, AppStrings.fileOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (attachment.type == ChatAttachmentType.voice) {
      return ChatVoicePlayer(
        id: id,
        path: attachment.path,
        duration: attachment.duration ?? Duration.zero,
        color: foreground,
      );
    }
    final preview = attachment.type == ChatAttachmentType.image
        ? attachment.path
        : attachment.thumbnailPath;
    return InkWell(
      onTap: () => _open(context),
      child: SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(preview),
                      width: 250,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => SizedBox(
                        height: 80,
                        child: AppIcon(
                          AppIcons.imageUnavailable,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (attachment.type == ChatAttachmentType.video)
                      AppIcon(AppIcons.playCircle, color: foreground, size: 42),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                AppIcon(
                  attachment.type == ChatAttachmentType.video
                      ? AppIcons.video
                      : AppIcons.document,
                  color: foreground,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(color: foreground),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.chatFileSize(attachment.sizeBytes),
                textDirection: TextDirection.ltr,
                style: AppTextStyles.smallPrint.copyWith(
                  color: foreground.withValues(alpha: .7),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
