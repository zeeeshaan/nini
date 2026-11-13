import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/notification_strings.dart';

import '../../../domain/app_notification.dart';
import 'notification_tile.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({
    super.key,
    required this.items,
    required this.searching,
    required this.onRead,
    this.leading = const [],
  });
  final List<AppNotification> items;
  final bool searching;
  final ValueChanged<String> onRead;
  final List<Widget> leading;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && leading.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              searching
                  ? NotificationStrings.noResults
                  : NotificationStrings.empty,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: leading.length + items.length,
      itemBuilder: (_, index) {
        if (index < leading.length) return leading[index];
        final item = items[index - leading.length];
        return NotificationTile(
          key: ValueKey(item.id),
          notification: item,
          onTap: () => onRead(item.id),
        );
      },
    );
  }
}
