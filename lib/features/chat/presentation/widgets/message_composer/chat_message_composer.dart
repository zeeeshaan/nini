import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class ChatMessageComposer extends StatelessWidget {
  const ChatMessageComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onEmojiPressed,
    required this.onAttachmentPressed,
    required this.onPhotosPressed,
    required this.onRecord,
    required this.onKeyboardRequested,
    this.enabled = true,
    this.busy = false,
    this.emojiVisible = false,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend,
      onEmojiPressed,
      onAttachmentPressed,
      onPhotosPressed,
      onRecord,
      onKeyboardRequested;
  final bool enabled, busy, emojiVisible;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final interactive = enabled && !busy;
    Widget action(String tooltip, Widget icon, VoidCallback callback) =>
        IconButton(
          tooltip: tooltip,
          onPressed: interactive ? callback : null,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 48),
          padding: const EdgeInsets.all(5),
          icon: icon,
        );
    return SafeArea(
      top: false,
      bottom: !emojiVisible,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    action(
                      emojiVisible ? AppStrings.keyboard : AppStrings.emoji,
                      Icon(
                        emojiVisible
                            ? Icons.keyboard_outlined
                            : Icons.emoji_emotions_outlined,
                        color: colors.onPrimary,
                        size: 22,
                      ),
                      onEmojiPressed,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: interactive,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        onTap: onKeyboardRequested,
                        cursorColor: colors.onPrimary,
                        style: TextStyle(fontSize: 14, color: colors.onPrimary),
                        decoration: InputDecoration(
                          hintText: AppStrings.messageHint,
                          hintStyle: TextStyle(
                            color: colors.onPrimary.withValues(alpha: .65),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    action(
                      AppStrings.attachFile,
                      AppIcon(
                        AppIcons.attachment,
                        size: 22,
                        color: colors.onPrimary,
                      ),
                      onAttachmentPressed,
                    ),
                    action(
                      AppStrings.photosVideos,
                      AppIcon(
                        AppIcons.image,
                        size: 22,
                        color: colors.onPrimary,
                      ),
                      onPhotosPressed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return SizedBox.square(
                  dimension: 50,
                  child: Material(
                    color: colors.primary,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: hasText
                          ? AppStrings.sendMessage
                          : AppStrings.recordVoice,
                      onPressed: interactive
                          ? hasText
                                ? onSend
                                : onRecord
                          : null,
                      icon: busy
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : hasText
                          ? AppIcon(
                              AppIcons.send,
                              size: 24,
                              color: colors.onPrimary,
                            )
                          : AppIcon(
                              AppIcons.microphone,
                              color: colors.onPrimary,
                              size: 25,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
