import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/features/payment/presentation/helpers/receipt_navigation.dart';
import 'package:nini/features/provider_invoice/presentation/helpers/open_provider_invoice.dart';

import '../cubit/notifications_cubit.dart';
import '../widgets/notification_header/notification_header.dart';
import '../widgets/notification_search_field/notification_search_field.dart';
import '../widgets/notification_list/notification_list.dart';

/// Shared notifications for purchases and provider sales on the same profile.
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
                        onRead: (id) async {
                          final item = state.items.firstWhere(
                            (item) => item.id == id,
                          );
                          await notifications.markRead(id);
                          if (!context.mounted || item.orderId == null) return;
                          if (item.asProvider) {
                            await openProviderInvoice(context, item.orderId!);
                          } else {
                            await openSavedInvoice(context, item.orderId!);
                          }
                        },
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
