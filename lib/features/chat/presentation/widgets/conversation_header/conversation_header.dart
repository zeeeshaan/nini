import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

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
  });
  final ChatConversation conversation;
  final String? subtitle;
  final bool selectionMode, blocked, hasMessages, busy, canCopy;
  final int selectedCount;
  final VoidCallback onBack, onDelete, onSelectAll, onVoiceCall, onVideoCall;
  final ValueChanged<ConversationAction> onAction;
  @override
  Size get preferredSize => const Size.fromHeight(70);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 48,
      leading: IconButton(
        tooltip: selectionMode ? AppStrings.cancel : AppStrings.back,
        onPressed: onBack,
        icon: AppIcon(selectionMode ? AppIcons.close : AppIcons.back, size: 25),
      ),
      title: selectionMode
          ? Text(
              AppStrings.selectedMessages(selectedCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle?.isNotEmpty == true)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurface.withValues(alpha: .45),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 19,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: conversation.avatarAsset == null
                      ? const AppIcon(AppIcons.profile, size: 23)
                      : ClipOval(
                          child: Image.asset(
                            conversation.avatarAsset!,
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
      actions: [
        if (selectionMode) ...[
          IconButton(
            tooltip: AppStrings.selectAllMessages,
            onPressed: onSelectAll,
            icon: const Icon(Icons.select_all),
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
            icon: const Icon(Icons.call_outlined, size: 23),
          ),
          IconButton(
            tooltip: AppStrings.videoCall,
            onPressed: blocked || busy ? null : onVideoCall,
            icon: const Icon(Icons.videocam_outlined, size: 25),
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
                child: Text(AppStrings.copyMessage),
              ),
            if (!selectionMode)
              PopupMenuItem(
                value: ConversationAction.select,
                enabled: hasMessages && !busy,
                child: const Text(AppStrings.deleteMessages),
              ),
            PopupMenuItem(
              value: ConversationAction.clear,
              enabled: hasMessages && !busy,
              child: const Text(AppStrings.clearConversation),
            ),
            PopupMenuItem(
              value: ConversationAction.block,
              child: Text(
                blocked ? AppStrings.unblockPerson : AppStrings.blockPerson,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
