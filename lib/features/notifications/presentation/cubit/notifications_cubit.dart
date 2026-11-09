import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';

import '../../domain/order_notifications.dart';
import 'notifications_state.dart';
export 'notifications_state.dart';

/// Projects saved orders into notifications; read timestamps live with each order.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this.cart) : super(const NotificationsState(items: [])) {
    _sync();
    _subscription = cart.stream.listen((_) => _sync());
  }
  final CartCubit cart;
  late final StreamSubscription _subscription;
  void _sync() => emit(
    NotificationsState(
      items: orderNotifications(cart.state.orders, cart.localUser.id),
      query: state.query,
    ),
  );
  void search(String query) => emit(
    NotificationsState(
      items: orderNotifications(cart.state.orders, cart.localUser.id),
      query: query,
    ),
  );
  Future<void> markRead(String id) async {
    for (final notification in state.items) {
      if (notification.id == id && notification.orderId != null) {
        await cart.markOrderRead(
          notification.orderId!,
          asProvider: notification.asProvider,
        );
        return;
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
