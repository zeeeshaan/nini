import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/features/chat/presentation/widgets/inbox/chat_conversation_tile.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

enum _InboxMenuAction { toggleUnread, markAllRead }

class ChatInboxScreen extends StatelessWidget {
  const ChatInboxScreen({super.key, this.onOpenConversation});

  final ValueChanged<ChatConversation>? onOpenConversation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatInboxCubit(),
      child: _ChatInboxView(onOpenConversation: onOpenConversation),
    );
  }
}

class _ChatInboxView extends StatefulWidget {
  const _ChatInboxView({required this.onOpenConversation});

  final ValueChanged<ChatConversation>? onOpenConversation;

  @override
  State<_ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<_ChatInboxView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(ChatConversation conversation) {
    final inboxCubit = context.read<ChatInboxCubit>();

    inboxCubit.markAsRead(conversation.id);

    final selectedConversation = conversation.copyWith(unreadCount: 0);

    if (widget.onOpenConversation != null) {
      widget.onOpenConversation!(selectedConversation);
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(
              conversation: selectedConversation,
              onLatestMessageChanged: (message) {
                if (inboxCubit.isClosed) return;
                inboxCubit.updateConversationPreview(conversation.id, message);
              },
            ),
          ),
        )
        .then((_) {
          if (mounted && !inboxCubit.isClosed) inboxCubit.refresh();
        });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: (MediaQuery.textScalerOf(context).scale(27) * 1.4 + 8)
              .clamp(72, double.infinity),
          centerTitle: false,
          titleSpacing: 6,
          title: Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppStrings.chat,
              style: AppTextStyles.inboxTitle.copyWith(color: colors.onSurface),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
          actions: [
            BlocBuilder<ChatInboxCubit, ChatInboxState>(
              builder: (context, state) {
                return PopupMenuButton<_InboxMenuAction>(
                  tooltip: AppStrings.chatOptions,
                  icon: const AppIcon(AppIcons.more, size: 24),
                  onSelected: (action) {
                    final cubit = context.read<ChatInboxCubit>();

                    switch (action) {
                      case _InboxMenuAction.toggleUnread:
                        cubit.toggleUnreadFilter();
                        break;
                      case _InboxMenuAction.markAllRead:
                        cubit.markAllAsRead();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _InboxMenuAction.toggleUnread,
                      child: Text(
                        state.unreadOnly
                            ? AppStrings.showAllChats
                            : AppStrings.unreadChats,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    PopupMenuItem(
                      value: _InboxMenuAction.markAllRead,
                      enabled: state.hasUnread,
                      child: const Text(
                        AppStrings.markAllRead,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),

            IconButton(
              tooltip: AppStrings.back,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const AppIcon(AppIcons.backRight, size: 26),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    context.read<ChatInboxCubit>().search(value);
                  },
                  style: AppTextStyles.comfortableBody.copyWith(
                    color: colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    hintStyle: AppTextStyles.comfortableBody.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.38),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 13),
                      child: AppIcon(AppIcons.search, size: 24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: colors.onSurface, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: colors.onSurface,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<ChatInboxCubit, ChatInboxState>(
                builder: (context, state) {
                  final chats = state.filteredConversations;

                  if (chats.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.search, size: 32),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                state.unreadOnly
                                    ? AppStrings.noUnreadChats
                                    : AppStrings.noChatsFound,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.comfortableBody.copyWith(
                                  color: colors.onSurface,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(top: 10, bottom: 24),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final conversation = chats[index];

                      return ChatConversationTile(
                        key: ValueKey(conversation.id),
                        conversation: conversation,
                        onTap: () => _openConversation(conversation),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
