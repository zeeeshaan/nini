// dart format width=100
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/demo_cart_items.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_order.dart';

import 'package:nini/features/home/data/home_post_data.dart';

import '../../domain/models/cart_order_status.dart';
import '../../../payment/domain/models/payment_method.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this.repository) : super(CartState());
  final CartRepository repository;
  Future<void> _writes = Future.value();
  bool _loaded = false;
  bool _readFailed = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final saved = await repository.load();
      if (isClosed) return;
      _readFailed = false;
      emit(
        state.copyWith(
          items: (saved?.items ?? demoCartItems).map(_restoreKnownSeller).toList(),
          orders: saved?.orders ?? [],
          loading: false,
          storageError: false,
        ),
      );
      if (saved == null) await _persist();
    } catch (_) {
      if (isClosed) return;
      _readFailed = true;
      emit(state.copyWith(loading: false, storageError: true));
    }
  }

  Future<void> retryStorage() async {
    if (_readFailed) {
      _loaded = false;
      await load();
    } else {
      await _persist();
    }
  }

  Future<void> _persist() {
    final snapshot = state.snapshot;
    _writes = _writes.then((_) async {
      try {
        await repository.save(snapshot);
        if (!isClosed) emit(state.copyWith(storageError: false));
      } catch (_) {
        if (!isClosed) emit(state.copyWith(storageError: true));
      }
    });
    return _writes;
  }

  bool get _editable => !state.loading && !_readFailed;

  CartItem _restoreKnownSeller(CartItem item) {
    if (item.seller != null) return item;
    if (item.id == 'home-pixel9') {
      return item.withQuantity(item.quantity, seller: homeSeller);
    }
    if (demoCartItems.any((sample) => sample.id == item.id)) {
      return item.withQuantity(item.quantity, seller: demoCartSeller);
    }
    return item;
  }

  bool add(CartItem item) {
    if (!_editable) return false;
    final index = state.items.indexWhere((entry) => entry.id == item.id);
    final items = [...state.items];
    if (index < 0) {
      if (!item.accepts(item.quantity)) return false;
      items.add(item);
    } else {
      final old = items[index];
      if (old.seller != null && item.seller != null && old.seller!.id != item.seller!.id) {
        return false;
      }
      if (!old.accepts(old.quantity + item.quantity)) return false;
      items[index] = old.withQuantity(old.quantity + item.quantity, seller: item.seller);
    }
    emit(state.copyWith(items: items));
    _persist();
    return true;
  }

  bool updateQuantity(String id, int quantity) {
    if (!_editable) return false;
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0 || !state.items[index].accepts(quantity)) return false;
    final items = [...state.items];
    items[index] = items[index].withQuantity(quantity);
    emit(state.copyWith(items: items));
    _persist();
    return true;
  }

  void remove(String id) {
    if (!_editable) return;
    emit(state.copyWith(items: state.items.where((item) => item.id != id).toList()));
    _persist();
  }

  void clear() {
    if (!_editable) return;
    emit(state.copyWith(items: [], charges: 0));
    _persist();
  }

  void filterByStatus(CartOrderStatus? status) =>
      emit(state.copyWith(statusFilter: status, clearStatusFilter: status == null));

  void selectTab(CartTab tab) => emit(state.copyWith(tab: tab));
  void checkout({String? itemId}) {
    if (!_editable || state.items.isEmpty) return;
    final candidates = itemId == null ? state.visibleItems : state.items;
    final ids = candidates
        .where((item) => itemId == null || item.id == itemId)
        .map((item) => item.id)
        .toSet();
    if (ids.isEmpty) return;
    emit(state.copyWith(stage: CartStage.checkout, checkoutIds: ids, charges: 0));
  }

  void setMethod(PaymentMethod method) => emit(state.copyWith(method: method));
  void setCharges(int amount) {
    if (_editable && amount >= 0 && amount <= 99999999900) {
      emit(state.copyWith(charges: amount));
    }
  }

  void back() => emit(state.copyWith(stage: CartStage.cart));

  CartOrder? findOrder(String id) {
    for (final order in state.orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  List<CartOrder> requestProducts({required String address, required String phone}) {
    if (!_editable || state.checkoutItems.isEmpty) return [];
    if (address.trim().isEmpty || !RegExp(r'^\+?\d{7,15}$').hasMatch(phone.trim())) return [];
    final groups = <String, List<CartItem>>{};
    for (final item in state.checkoutItems) {
      final seller = item.seller;
      if (seller == null || seller.id.isEmpty) return [];
      groups.putIfAbsent(seller.id, () => []).add(item);
    }
    final now = DateTime.now();
    final orders = <CartOrder>[];
    var remainingCharges = state.charges;
    final total = state.checkoutItems.fold(0, (sum, item) => sum + item.total);
    for (final items in groups.values) {
      final last = orders.length == groups.length - 1;
      final groupTotal = items.fold(0, (sum, item) => sum + item.total);
      final charges = last
          ? remainingCharges
          : (total == 0 ? 0 : state.charges * groupTotal ~/ total);
      remainingCharges -= charges;
      orders.add(
        CartOrder(
          id: 'PO-${now.microsecondsSinceEpoch}-${orders.length + 1}',
          createdAt: now,
          items: items,
          method: state.method,
          charges: charges,
          status: CartOrderStatus.pendingApproval,
          seller: items.first.seller,
          customerId: 'local-customer',
          address: address.trim(),
          phone: phone.trim(),
          timeline: {CartOrderStatus.pendingApproval: now},
        ),
      );
    }
    final remaining = state.items.where((item) => !state.checkoutIds.contains(item.id)).toList();
    emit(
      state.copyWith(
        items: remaining,
        orders: [...state.orders, ...orders],
        stage: CartStage.cart,
        tab: CartTab.cart,
        checkoutIds: {},
        charges: 0,
        clearStatusFilter: true,
      ),
    );
    _persist();
    return orders;
  }

  void respondToProductRequest(String id, {required bool accept}) => _transitionOrder(
    id,
    CartOrderStatus.pendingApproval,
    accept ? CartOrderStatus.pendingPay : CartOrderStatus.unsuccessful,
  );

  void cancelProductOrder(String id) {
    final order = findOrder(id);
    if (order?.status == CartOrderStatus.pendingApproval ||
        order?.status == CartOrderStatus.pendingPay) {
      _transitionOrder(id, order!.status!, CartOrderStatus.canceled);
    }
  }

  // Called only by a verified payment result; the placeholder gateway never calls this.
  void confirmProductPayment(String id) =>
      _transitionOrder(id, CartOrderStatus.pendingPay, CartOrderStatus.accepted);
  void prepareProductOrder(String id) =>
      _transitionOrder(id, CartOrderStatus.accepted, CartOrderStatus.preparing);
  void shipProductOrder(String id) =>
      _transitionOrder(id, CartOrderStatus.preparing, CartOrderStatus.shipped);
  void receiveProductOrder(String id) =>
      _transitionOrder(id, CartOrderStatus.shipped, CartOrderStatus.completed);

  void _transitionOrder(String id, CartOrderStatus from, CartOrderStatus to) {
    if (!_editable) return;
    final order = findOrder(id);
    if (order == null || !order.isProductRequest || order.status != from) return;
    emit(
      state.copyWith(
        orders: [
          for (final saved in state.orders)
            if (saved.id == id) saved.withStatus(to) else saved,
        ],
      ),
    );
    _persist();
  }
}
