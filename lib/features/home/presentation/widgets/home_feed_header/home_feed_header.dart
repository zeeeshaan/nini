import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/chat/presentation/widgets/chat_inbox_button/chat_inbox_button.dart';

import '../home_notification_button/home_notification_button.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({
    super.key,
    required this.onNotificationsPressed,
    this.unreadCount = 0,
  });
  final VoidCallback onNotificationsPressed;
  final int unreadCount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
    child: Row(
      children: [
        const SizedBox(width: 98),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'HYWORK',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeBrand,
            ),
          ),
        ),
        const ChatInboxButton(),
        const SizedBox(width: 8),
        HomeNotificationButton(
          unreadCount: unreadCount,
          onPressed: onNotificationsPressed,
        ),
      ],
    ),
  );
}
