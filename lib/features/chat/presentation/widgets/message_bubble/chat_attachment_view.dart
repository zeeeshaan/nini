import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/chat/presentation/widgets/voice_message/chat_voice_player.dart';
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
              title: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: .5,
                maxScale: 5,
                child: Image.file(
                  File(attachment.path),
                  errorBuilder: (_, error, stack) =>
                      const Icon(Icons.broken_image_outlined, size: 48),
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
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (attachment.type == ChatAttachmentType.video)
                      Icon(Icons.play_circle, color: foreground, size: 42),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  attachment.type == ChatAttachmentType.video
                      ? Icons.videocam_outlined
                      : Icons.insert_drive_file_outlined,
                  color: foreground,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: foreground),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.chatFileSize(attachment.sizeBytes),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 10,
                  color: foreground.withValues(alpha: .7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
