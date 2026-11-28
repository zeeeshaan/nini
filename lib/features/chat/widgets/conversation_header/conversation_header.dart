import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_images/profile_image_provider.dart';

enum ConversationAction { select, clear, block, copy }

class ConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationHeader({
    super.key,
    required this.conversation,
    this.subtitle,
    required this.selectionMode,
    required this.selectedCount,
    required this.blocked,
    required this.hasMessages,
    required this.busy,
    required this.onBack,
    required this.onDelete,
    required this.onSelectAll,
    required this.onAction,
    required this.onVoiceCall,
    required this.onVideoCall,
    this.canCopy = false,
    this.peerTyping = false,
    this.toolbarHeight = 70,
    this.titleContent,
    this.bottom,
    this.allowBlocking = true,
  });
  final ChatConversation conversation;
  final String? subtitle;
  final Widget? titleContent;
  final PreferredSizeWidget? bottom;
  final bool allowBlocking;
  final bool selectionMode, blocked, hasMessages, busy, canCopy, peerTyping;
  final int selectedCount;
  final double toolbarHeight;
  final VoidCallback onBack, onDelete, onSelectAll, onVoiceCall, onVideoCall;
  final ValueChanged<ConversationAction> onAction;
  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight + (selectionMode ? 0 : bottom?.preferredSize.height ?? 0),
  );
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatar = profileImageProvider(conversation.avatarAsset);
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
      bottom: selectionMode ? null : bottom,
      centerTitle: false,
      titleSpacing: 0,
      title: Align(
        alignment: Alignment.centerRight,
        child: selectionMode
            ? Text(
                AppStrings.selectedMessages(selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.comfortableBody,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              )
            : titleContent ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              conversation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.comfortableBodyBold,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.ltr,
                            ),
                            if (subtitle?.isNotEmpty == true)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.helper.copyWith(
                                  color: peerTyping
                                      ? colors.primary
                                      : colors.onSurface.withValues(alpha: .45),
                                  fontWeight: peerTyping
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.ltr,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: colors.surfaceContainerHighest,
                        child: avatar == null
                            ? const AppIcon(AppIcons.profile, size: 23)
                            : ClipOval(
                                child: Image(
                                  image: avatar,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) =>
                                      const AppIcon(AppIcons.profile, size: 23),
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
      actions: [
        if (selectionMode) ...[
          IconButton(
            tooltip: AppStrings.selectAllMessages,
            onPressed: onSelectAll,
            icon: const AppIcon(AppIcons.selectAll),
          ),
          IconButton(
            tooltip: AppStrings.deleteSelectedMessages,
            onPressed: selectedCount > 0 ? onDelete : null,
            icon: const AppIcon(AppIcons.trash),
          ),
        ] else ...[
          IconButton(
            tooltip: AppStrings.audioCall,
            onPressed: blocked || busy ? null : onVoiceCall,
            icon: const AppIcon(AppIcons.phone, size: 23),
          ),
          IconButton(
            tooltip: AppStrings.videoCall,
            onPressed: blocked || busy ? null : onVideoCall,
            icon: const AppIcon(AppIcons.video, size: 25),
          ),
        ],
        PopupMenuButton<ConversationAction>(
          tooltip: AppStrings.chatOptions,
          onSelected: onAction,
          icon: const AppIcon(AppIcons.more, size: 23),
          itemBuilder: (context) => [
            if (canCopy)
              const PopupMenuItem(
                value: ConversationAction.copy,
                child: Text(
                  AppStrings.copyMessage,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            if (!selectionMode)
              PopupMenuItem(
                value: ConversationAction.select,
                enabled: hasMessages && !busy,
                child: const Text(
                  AppStrings.deleteMessages,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            PopupMenuItem(
              value: ConversationAction.clear,
              enabled: hasMessages && !busy,
              child: const Text(
                AppStrings.clearConversation,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
            if (allowBlocking)
              PopupMenuItem(
                value: ConversationAction.block,
                child: Text(
                  blocked ? AppStrings.unblockPerson : AppStrings.blockPerson,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
          ],
        ),

        IconButton(
          tooltip: selectionMode ? AppStrings.cancel : AppStrings.back,
          onPressed: onBack,
          icon: AppIcon(
            selectionMode ? AppIcons.close : AppIcons.backRight,
            size: 25,
          ),
        ),
      ],
    );
  }
}
