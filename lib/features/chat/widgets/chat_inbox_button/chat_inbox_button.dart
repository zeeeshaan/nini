import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/chat/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/screens/chat_inbox_screen.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Shared Home/Profile entry to the existing chat inbox.
class ChatInboxButton extends StatelessWidget {
  const ChatInboxButton({super.key, this.onPressed, this.notificationCount});

  final VoidCallback? onPressed;

  /// When null, uses shared [ChatUnreadCubit] conversation badge count.
  final int? notificationCount;

  @override
  Widget build(BuildContext context) {
    if (notificationCount != null) {
      return _BadgeButton(count: notificationCount!, onPressed: onPressed);
    }
    return BlocBuilder<ChatUnreadCubit, ChatUnreadState>(
      builder: (context, state) =>
          _BadgeButton(count: state.badgeCount, onPressed: onPressed),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({required this.count, this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed:
            onPressed ??
            () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
            ),
        tooltip: AppStrings.messages,
        icon: const AppIcon(AppIcons.send, size: 27),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      ),
      if (count > 0)
        Positioned(
          left: 1,
          top: 5,
          child: IgnorePointer(
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.notificationBadge,
                shape: BoxShape.circle,
              ),
              child: Text(
                AppStrings.persianDigits(count > 9 ? '9+' : count),
                style: AppTextStyles.notificationBadge.copyWith(
                  color: AppColors.white,
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
    ],
  );
}
