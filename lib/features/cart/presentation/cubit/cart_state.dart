// dart format width=100
import '../../domain/models/cart_item.dart';
import '../../domain/policies/order_access.dart';

import 'package:nini/shared/models/local_identity.dart';

import '../../domain/models/cart_order_status.dart';
import '../../domain/models/cart_order.dart';
import '../../domain/models/cart_snapshot.dart';
import '../../../payment/domain/models/payment_method.dart';

enum CartStage { cart, checkout }

enum CartTab { cart, history, sales }

class CartState {
  CartState({
    List<CartItem> items = const [],
    List<CartOrder> orders = const [],
    this.stage = CartStage.cart,
    this.tab = CartTab.cart,
    this.method = PaymentMethod.mellat,
    Set<String> checkoutIds = const {},
    this.charges = 0,
    this.loading = true,
    this.storageError = false,
    this.statusFilter,
    this.currentUserId = localProfileId,
  }) : items = List.unmodifiable(items),
       orders = List.unmodifiable(orders),
       checkoutIds = Set.unmodifiable(checkoutIds);
  final String currentUserId;
  final List<CartItem> items;
  final List<CartOrder> orders;
  final Set<String> checkoutIds;
  final CartStage stage;
  final CartTab tab;
  final PaymentMethod method;
  final int charges;
  final bool loading, storageError;
  final CartOrderStatus? statusFilter;
  List<CartItem> get visibleItems =>
      items.where((item) => statusFilter == null || item.status == statusFilter).toList();
  List<CartOrder> get visibleOrders =>
      orders.where((order) => statusFilter == null || order.status == statusFilter).toList();
  List<CartOrder> get purchases =>
      visibleOrders.where((order) => OrderAccess.isBuyer(order, currentUserId)).toList();
  List<CartOrder> get sales =>
      visibleOrders.where((order) => OrderAccess.isProvider(order, currentUserId)).toList();
  List<CartItem> get checkoutItems => items.where((item) => checkoutIds.contains(item.id)).toList();
  int get subtotal => checkoutItems.fold(0, (sum, item) => sum + item.subtotal);
  int get discount => checkoutItems.fold(0, (sum, item) => sum + item.discount);
  int get total => subtotal - discount + charges;
  int get visibleTotal => visibleItems.fold(0, (sum, item) => sum + item.total);
  int get cartTotal => items.fold(0, (sum, item) => sum + item.total);
  CartSnapshot get snapshot => CartSnapshot(items: items, orders: orders);

  CartState copyWith({
    List<CartItem>? items,
    List<CartOrder>? orders,
    CartStage? stage,
    CartTab? tab,
    PaymentMethod? method,
    Set<String>? checkoutIds,
    int? charges,
    bool? loading,
    bool? storageError,
    CartOrderStatus? statusFilter,
    bool clearStatusFilter = false,
  }) => CartState(
    currentUserId: currentUserId,
    items: items ?? this.items,
    orders: orders ?? this.orders,
    stage: stage ?? this.stage,
    tab: tab ?? this.tab,
    method: method ?? this.method,
    checkoutIds: checkoutIds ?? this.checkoutIds,
    charges: charges ?? this.charges,
    loading: loading ?? this.loading,
    storageError: storageError ?? this.storageError,
    statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
  );
}
