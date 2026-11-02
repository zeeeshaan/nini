import 'package:flutter/material.dart';
import 'package:nini/core/localization/notification_strings.dart';

import '../../../domain/models/app_notification.dart';
import '../notification_tile/notification_tile.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({
    super.key,
    required this.items,
    required this.searching,
    required this.onRead,
  });
  final List<AppNotification> items;
  final bool searching;
  final ValueChanged<String> onRead;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            searching
                ? NotificationStrings.noResults
                : NotificationStrings.empty,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (_, index) => NotificationTile(
        key: ValueKey(items[index].id),
        notification: items[index],
        onTap: () => onRead(items[index].id),
      ),
    );
  }
}
