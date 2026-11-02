import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/presentation/widgets/home_feed_header/home_feed_header.dart';
import 'package:nini/features/home/presentation/widgets/home_product_card/home_product_card.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/features/notifications/presentation/pages/notifications_screen.dart';

/// UI-only feed. Sample image URLs and text are kept here, not in a repository.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onViewCart});

  final VoidCallback? onViewCart;

  // Google Pixel 9 Wintergreen, matching the phone in the reference.
  // Source: https://www.smarty.sk/google-pixel-9-12gb-128gb-wintergreen-4p159917
  static const phoneImageUrl =
      'https://doc.smarty.sk/pic/0f1e8c73d99d417ea73a3db313bcd924-600-600.webp';
  static const phoneTitle = 'گوشی گوگل پیکسل ۹\nرنگ سبز روشن';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _notifications = NotificationsCubit();
  @override
  void dispose() {
    _notifications.close();
    super.dispose();
  }

  void _openNotifications() {
    _notifications.search('');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _notifications,
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          key: const PageStorageKey('home_feed'),
          padding: EdgeInsets.zero,
          itemCount: 7,
          itemBuilder: (context, index) {
            if (index == 0) {
              return BlocBuilder<NotificationsCubit, NotificationsState>(
                bloc: _notifications,
                builder: (_, state) => HomeFeedHeader(
                  unreadCount: state.unreadCount,
                  onNotificationsPressed: _openNotifications,
                ),
              );
            }
            return HomeProductCard(
              key: ValueKey('home_phone_$index'),
              imageUrl: HomeScreen.phoneImageUrl,
              title: HomeScreen.phoneTitle,
              onViewCart: widget.onViewCart,
            );
          },
        ),
      ),
    );
  }
}
