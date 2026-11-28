import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/chat/cubit/chat_inbox_cubit.dart';
import 'package:hywork/features/chat/cubit/chat_unread_cubit.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

enum ChatInboxMenuAction { toggleUnread, markAllRead }

double chatInboxToolbarHeight(BuildContext context) {
  return (MediaQuery.textScalerOf(context).scale(27) * 1.4 + 8).clamp(
    72,
    double.infinity,
  );
}

/// Inbox AppBar: title, unread filter / mark-all-read menu, and back.
class ChatInboxHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatInboxHeader({super.key, required this.toolbarHeight});

  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
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
          buildWhen: (before, after) =>
              before.unreadOnly != after.unreadOnly ||
              before.hasUnread != after.hasUnread,
          builder: (context, state) {
            return PopupMenuButton<ChatInboxMenuAction>(
              tooltip: AppStrings.chatOptions,
              icon: const AppIcon(AppIcons.more, size: 24),
              onSelected: (action) {
                final cubit = context.read<ChatInboxCubit>();
                switch (action) {
                  case ChatInboxMenuAction.toggleUnread:
                    cubit.toggleUnreadFilter();
                  case ChatInboxMenuAction.markAllRead:
                    unawaited(_markAllRead(context, cubit));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ChatInboxMenuAction.toggleUnread,
                  child: Text(
                    state.unreadOnly
                        ? AppStrings.showAllChats
                        : AppStrings.unreadChats,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                PopupMenuItem(
                  value: ChatInboxMenuAction.markAllRead,
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
    );
  }
}

Future<void> _markAllRead(BuildContext context, ChatInboxCubit cubit) async {
  final ok = await cubit.markAllAsRead();
  if (!context.mounted) return;
  await context.read<ChatUnreadCubit?>()?.refresh();
  if (!context.mounted) return;
  if (!ok) {
    AppToast.error(
      context,
      cubit.state.error ?? ChatStrings.markAllReadPartial,
    );
  }
}
