import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/theme_mode_menu.dart';
import 'package:nini/features/chat/presentation/pages/chat_inbox_screen.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class HomeHeaderActions extends StatelessWidget {
  const HomeHeaderActions({
    super.key,
    this.onMessagesPressed,
    this.onMenuPressed,
    this.notificationCount = 1,
  });

  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMenuPressed;
  final int notificationCount;

  void _openChatScreen(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ChatInboxScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Theme mode button
        const ThemeModeMenu(),

        const SizedBox(width: 4),

        // Messages button with notification badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onMessagesPressed ?? () => _openChatScreen(context),
              tooltip: AppStrings.messages,
              icon: const AppIcon(AppIcons.chat, size: 27),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),

            if (notificationCount > 0)
              Positioned(
                left: 1,
                top: 5,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF0000),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notificationCount > 9 ? '9+' : notificationCount.toString(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 8),

        // More options button
        IconButton(
          onPressed: onMenuPressed,
          tooltip: AppStrings.moreOptions,
          icon: const AppIcon(AppIcons.more, size: 30),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 42),
        ),
      ],
    );
  }
}
