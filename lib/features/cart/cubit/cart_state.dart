// dart format width=100
import 'package:hywork/features/cart/models/cart_item.dart';
import 'package:hywork/features/cart/models/cart_order.dart';
import 'package:hywork/features/cart/models/cart_snapshot.dart';
import 'package:hywork/features/cart/utils/order_access.dart';
import 'package:hywork/features/payment/domain/models/payment_method.dart';
import 'package:hywork/shared/models/local_identity.dart';

enum CartStage { cart, checkout }

enum CartTab { cart, history, sales }

class CartState {
  CartState({
    List<CartItem> items = const [],
    List<CartOrder> orders = const [],
    List<CartRemoval> removals = const [],
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
       removals = List.unmodifiable(removals),
       checkoutIds = Set.unmodifiable(checkoutIds);
  final String currentUserId;
  final List<CartItem> items;
  final List<CartOrder> orders;
  final List<CartRemoval> removals;
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
    List<CartRemoval>? removals,
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
    removals: removals ?? this.removals,
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
