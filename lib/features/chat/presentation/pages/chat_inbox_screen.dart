import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/features/chat/presentation/widgets/chat_conversation_tile/chat_conversation_tile.dart';
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
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 72,
          centerTitle: false,
          titleSpacing: 6,
          leadingWidth: 64,
          leading: IconButton(
            tooltip: AppStrings.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const AppIcon(AppIcons.back, size: 26),
          ),
          title: Text(
            AppStrings.chat,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
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
                      ),
                    ),
                    PopupMenuItem(
                      value: _InboxMenuAction.markAllRead,
                      enabled: state.hasUnread,
                      child: const Text(AppStrings.markAllRead),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    context.read<ChatInboxCubit>().search(value);
                  },
                  style: TextStyle(color: colors.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    hintStyle: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.38),
                      fontSize: 15,
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.search, size: 32),
                            const SizedBox(height: 14),
                            Text(
                              state.unreadOnly
                                  ? AppStrings.noUnreadChats
                                  : AppStrings.noChatsFound,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.onSurface,
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
