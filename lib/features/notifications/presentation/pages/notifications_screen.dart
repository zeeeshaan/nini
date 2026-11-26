import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';

import '../cubit/notifications_cubit.dart';
import '../helpers/open_notification_target.dart';
import '../widgets/common/notification_header.dart';
import '../widgets/common/notification_list.dart';
import '../widgets/common/notification_search_field.dart';

/// Shared notifications inbox backed by the authenticated notification APIs.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationsCubit>().refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) => ScreenEntrance(
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: BlocListener<NotificationsCubit, NotificationsState>(
              listenWhen: (previous, current) =>
                  previous.actionError != current.actionError &&
                  current.actionError != null,
              listener: (context, state) {
                if (state.actionError != null) {
                  AppToast.error(context, state.actionError!);
                }
              },
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  final notifications = context.read<NotificationsCubit>();
                  final loading = state.loading && state.items.isEmpty;
                  return Column(
                    children: [
                      const NotificationHeader(),
                      NotificationSearchField(
                        query: state.query,
                        onChanged: notifications.search,
                      ),
                      Expanded(
                        child: loading
                            ? AppShimmer(
                                child: ListView.builder(
                                  itemCount: 6,
                                  itemBuilder: (_, index) =>
                                      const ListTileSkeleton(animated: false),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: notifications.refresh,
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics.axis ==
                                            Axis.vertical &&
                                        notification.metrics.extentAfter <
                                            400 &&
                                        state.hasMore &&
                                        !state.loadingMore &&
                                        state.error == null) {
                                      notifications.loadMore();
                                    }
                                    return false;
                                  },
                                  child:
                                      state.error != null && state.items.isEmpty
                                      ? ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(24),
                                          children: [
                                            const SizedBox(height: 80),
                                            Text(
                                              state.error!,
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            TextButton(
                                              onPressed: notifications.retry,
                                              child: const Text(
                                                AppStrings.retry,
                                              ),
                                            ),
                                          ],
                                        )
                                      : NotificationList(
                                          items: state.visibleItems,
                                          searching: state.query
                                              .trim()
                                              .isNotEmpty,
                                          onRead: (id) async {
                                            final match = state.items
                                                .where(
                                                  (entry) => entry.id == id,
                                                )
                                                .firstOrNull;
                                            if (match == null) return;
                                            await notifications.markRead(id);
                                            if (!context.mounted) return;
                                            await openNotificationTarget(
                                              context,
                                              match,
                                            );
                                          },
                                        ),
                                ),
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
    ),
  );
}
