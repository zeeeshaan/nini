import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';

import '../cubit/notifications_cubit.dart';
import '../widgets/notification_header/notification_header.dart';
import '../widgets/notification_search_field/notification_search_field.dart';
import '../widgets/notification_list/notification_list.dart';

/// Layout only. The Home screen supplies the shared notification Cubit.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenEntrance(
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                final notifications = context.read<NotificationsCubit>();
                return Column(
                  children: [
                    const NotificationHeader(),
                    NotificationSearchField(
                      query: state.query,
                      onChanged: notifications.search,
                    ),
                    Expanded(
                      child: NotificationList(
                        items: state.visibleItems,
                        searching: state.query.trim().isNotEmpty,
                        onRead: notifications.markRead,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
