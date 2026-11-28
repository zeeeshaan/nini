import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/cubit/chat_inbox_cubit.dart';
import 'package:hywork/features/chat/widgets/chat_conversation_tile/chat_conversation_tile.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';

/// Conversation list with loading, error, empty, refresh, and pagination.
class ChatInboxList extends StatelessWidget {
  const ChatInboxList({super.key, required this.onOpenConversation});

  final ValueChanged<ChatConversation> onOpenConversation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatInboxCubit, ChatInboxState>(
      builder: (context, state) {
        final inbox = context.read<ChatInboxCubit>();

        if (state.loading && state.conversations.isEmpty) {
          return const _InboxLoadingSkeleton();
        }

        return RefreshIndicator(
          onRefresh: inbox.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 400 &&
                  state.hasMore &&
                  !state.loadingMore &&
                  state.error == null) {
                inbox.loadMore();
              }
              return false;
            },
            child: _InboxScrollBody(
              state: state,
              onRetry: inbox.retry,
              onOpenConversation: onOpenConversation,
            ),
          ),
        );
      },
    );
  }
}

class _InboxScrollBody extends StatelessWidget {
  const _InboxScrollBody({
    required this.state,
    required this.onRetry,
    required this.onOpenConversation,
  });

  final ChatInboxState state;
  final VoidCallback onRetry;
  final ValueChanged<ChatConversation> onOpenConversation;

  @override
  Widget build(BuildContext context) {
    if (state.error != null && state.conversations.isEmpty) {
      return _InboxErrorView(message: state.error!, onRetry: onRetry);
    }

    final chats = state.filteredConversations;
    if (chats.isEmpty) {
      return _InboxEmptyView(unreadOnly: state.unreadOnly);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      itemCount: chats.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= chats.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final conversation = chats[index];
        return ChatConversationTile(
          key: ValueKey(conversation.id),
          conversation: conversation,
          onTap: () => onOpenConversation(conversation),
        );
      },
    );
  }
}

class _InboxLoadingSkeleton extends StatelessWidget {
  const _InboxLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, index) => const ListTileSkeleton(animated: false),
      ),
    );
  }
}

class _InboxErrorView extends StatelessWidget {
  const _InboxErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Text(
          message.isEmpty ? ChatStrings.loadFailed : message,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
      ],
    );
  }
}

class _InboxEmptyView extends StatelessWidget {
  const _InboxEmptyView({required this.unreadOnly});

  final bool unreadOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const AppIcon(AppIcons.search, size: 32),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            unreadOnly ? AppStrings.noUnreadChats : AppStrings.noChatsFound,
            textAlign: TextAlign.right,
            style: AppTextStyles.comfortableBody.copyWith(
              color: colors.onSurface,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}
