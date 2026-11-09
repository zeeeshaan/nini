import 'package:flutter/material.dart';
import 'package:nini/features/notifications/presentation/widgets/common/notifications_button.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });
  final int unreadCount;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      NotificationsButton(unreadCount: unreadCount, onPressed: onPressed);
}
