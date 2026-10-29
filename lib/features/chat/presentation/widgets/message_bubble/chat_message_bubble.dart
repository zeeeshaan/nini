import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/presentation/widgets/message_bubble/chat_attachment_view.dart';
import 'package:nini/features/chat/presentation/widgets/message_bubble/chat_location_view.dart';

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
    final foreground = message.isMine ? colors.onPrimary : colors.onSurface;
    final hour =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}';
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: message.isMine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(460, MediaQuery.sizeOf(context).width * .76),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 12, 8),
            decoration: BoxDecoration(
              color: message.isMine
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.attachment != null)
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
                    textDirection:
                        RegExp(r'[\u0600-\u06ff]').hasMatch(message.text)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: foreground,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.persianDigits(hour),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 10,
                        color: foreground.withValues(alpha: .75),
                      ),
                    ),
                    if (message.isMine) ...[
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
        onLongPress: onLongPress,
        onTap: selectionMode ? onSelect : null,
        child: Container(
          color: selected
              ? colors.onSurface.withValues(alpha: .12)
              : Colors.transparent,
          child: AbsorbPointer(absorbing: selectionMode, child: content),
        ),
      ),
    );
  }
}
