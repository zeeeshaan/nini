import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_images/profile_image_provider.dart';

class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  String _formatTime(DateTime date) => AppStrings.persianDigits(
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label:
          '${conversation.name}, ${AppStrings.unreadMessageCount(conversation.unreadCount)}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(conversation.lastMessageAt),
                      style: AppTextStyles.label.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.42),
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                    if (conversation.unreadCount > 0) ...[
                      const SizedBox(height: 9),
                      Container(
                        width: 19,
                        height: 19,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.onSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conversation.unreadCount > 99
                              ? AppStrings.persianDigits('99+')
                              : AppStrings.persianDigits(
                                  conversation.unreadCount,
                                ),
                          style: AppTextStyles.smallPrintMedium.copyWith(
                            color: colors.surface,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      conversation.name,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.conversationName.copyWith(
                        color: colors.onSurface,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      conversation.isBlocked
                          ? AppStrings.blocked
                          : conversation.lastMessage,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.compactBody.copyWith(
                        color: colors.onSurface,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              _ChatAvatar(conversation: conversation),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatar = profileImageProvider(conversation.avatarAsset);

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.onSurface.withValues(alpha: 0.15),
      ),
      child: avatar != null
          ? Image(
              image: avatar,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const AppIcon(AppIcons.profile, size: 26),
            )
          : const AppIcon(AppIcons.profile, size: 26),
    );
  }
}
