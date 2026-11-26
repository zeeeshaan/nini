import 'dart:math' as math;

import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/presentation/widgets/messages/chat_attachment_view.dart';
import 'package:hywork/features/chat/presentation/widgets/messages/chat_location_view.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
    this.onSelect,
    this.onOpenAttachment,
    this.selected = false,
    this.selectionMode = false,
  });
  final ChatMessage message;
  final VoidCallback? onLongPress, onSelect, onOpenAttachment;
  final bool selected, selectionMode;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSystem = message.type == BackendChatMessageType.system;
    final foreground = isSystem
        ? colors.onSurface.withValues(alpha: 0.72)
        : message.isMine
        ? colors.onPrimary
        : colors.onSurface;
    final hour =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}';
    final networkImage = message.deleted
        ? null
        : message.imageUrl?.trim().isNotEmpty == true
        ? message.imageUrl!.trim()
        : null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isSystem
            ? Alignment.center
            : message.isMine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(460, MediaQuery.sizeOf(context).width * .76),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 12, 8),
            decoration: BoxDecoration(
              color: isSystem
                  ? colors.surfaceContainerHighest.withValues(alpha: 0.7)
                  : message.isMine
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.deleted)
                  Text(
                    ChatStrings.messageDeleted,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.messageBody.copyWith(
                      color: foreground.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.right,
                  )
                else ...[
                  if (networkImage != null)
                    ChatAttachmentView(
                      id: message.id,
                      attachment: ChatAttachment(
                        path: networkImage,
                        name: AppStrings.photo,
                        type: ChatAttachmentType.image,
                        sizeBytes: 0,
                      ),
                      foreground: foreground,
                      onOpen: onOpenAttachment,
                    ),
                  if (message.attachment != null && networkImage == null)
                    ChatAttachmentView(
                      id: message.id,
                      attachment: message.attachment!,
                      foreground: foreground,
                      onOpen: onOpenAttachment,
                    ),
                  if (message.location != null)
                    ChatLocationView(
                      location: message.location!,
                      foreground: foreground,
                      onOpen: onOpenAttachment,
                    ),
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.messageBody.copyWith(
                        color: foreground,
                      ),
                      textAlign: TextAlign.right,
                    ),
                ],
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.persianDigits(hour),
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.smallPrint.copyWith(
                        color: foreground.withValues(alpha: .75),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (message.isMine && !message.deleted && !isSystem) ...[
                      const SizedBox(width: 4),
                      AppIcon(
                        message.deliveryStatus == ChatDeliveryStatus.read
                            ? AppIcons.checkAll
                            : AppIcons.check,
                        size: 14,
                        color: foreground,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: GestureDetector(
        onLongPress: message.deleted || isSystem ? null : onLongPress,
        onTap: selectionMode ? onSelect : null,
        child: Container(
          color: selected
              ? colors.onSurface.withValues(alpha: .12)
              : AppColors.transparent,
          child: AbsorbPointer(absorbing: selectionMode, child: content),
        ),
      ),
    );
  }
}
