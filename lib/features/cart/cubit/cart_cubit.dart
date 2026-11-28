// dart format width=100
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/cart/data/demo_cart_items.dart';
import 'package:hywork/features/cart/data/cart_repository.dart';
import 'package:hywork/features/cart/models/cart_item.dart';
import 'package:hywork/features/cart/models/cart_order.dart';
import 'package:hywork/features/cart/models/cart_snapshot.dart';
import 'package:hywork/features/cart/utils/checkout_order_builder.dart';
import 'package:hywork/features/cart/utils/order_access.dart';
import 'package:hywork/features/home/data/home_post_data.dart';
import 'package:hywork/features/order_cancellation/domain/order_cancellation.dart';
import 'package:hywork/features/payment/domain/models/dispute_attachment.dart';
import 'package:hywork/features/payment/domain/models/order_dispute.dart';
import 'package:hywork/features/payment/domain/models/payment_details.dart';
import 'package:hywork/features/payment/domain/models/payment_method.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this.repository, {this.localUser = localPostSeller})
    : super(CartState(currentUserId: localUser.id));
  final PostSeller localUser;
  final CartRepository repository;
  static const undoDuration = Duration(seconds: 15);
  final Map<String, Timer> _removalTimers = {};
  Future<void> _writes = Future.value();
  bool _loaded = false;
  bool _readFailed = false;
  bool _committingReceipt = false;

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
    if (_committingReceipt) return;
    if (_readFailed) {
      _loaded = false;
      await load();
    } else {
      await _persist();
    }
  }

  Future<void> _persist() async {
    await _saveSnapshot(state.snapshot);
  }

  Future<bool> _saveSnapshot(CartSnapshot snapshot) {
    var saved = false;
    _writes = _writes.then((_) async {
      try {
        await repository.save(snapshot);
        saved = true;
        if (!isClosed) emit(state.copyWith(storageError: false));
      } catch (_) {
        if (!isClosed) emit(state.copyWith(storageError: true));
      }
    });
    return _writes.then((_) => saved);
  }

  bool get _editable => !state.loading && !_readFailed && !_committingReceipt;

  Future<bool> _commitReceiptState(CartState next) async {
    if (!_editable) return false;
    _committingReceipt = true;
    try {
      final saved = await _saveSnapshot(next.snapshot);
      if (!saved || isClosed) return false;
      emit(next.copyWith(storageError: false, removals: state.removals));
      return true;
    } finally {
      _committingReceipt = false;
    }
  }

  /// Explicit local demo completion, separate from verified bank callbacks.
  Future<CartOrder?> completeDemoPayment(PaymentDetails details, PaymentMethod method) async {
    final checkoutId = details.checkoutId;
    if (checkoutId == null || details.customer == null) return null;
    for (final order in state.orders) {
      if (order.isPaidReceipt && order.checkoutId == checkoutId) return order;
    }
    if (!_editable ||
        state.stage != CartStage.checkout ||
        details.items.isEmpty ||
        state.total != details.total ||
        state.checkoutItems.length != details.items.length ||
        !details.items.every(
          (item) => state.checkoutItems.any((entry) => identical(entry, item)),
        )) {
      return null;
    }
    final orders = buildDemoCheckoutOrders(
      details: details,
      method: method,
      buyer: localUser,
      charges: state.charges,
      now: DateTime.now(),
    );
    if (orders.isEmpty) return null;
    final selectedIds = details.items.map((item) => item.id).toSet();
    final next = state.copyWith(
      items: state.items.where((item) => !selectedIds.contains(item.id)).toList(),
      orders: [...orders, ...state.orders],
      stage: CartStage.cart,
      tab: CartTab.cart,
      checkoutIds: {},
      charges: 0,
      clearStatusFilter: true,
    );
    return await _commitReceiptState(next) ? orders.first : null;
  }

  Future<bool> confirmPaidOrder(String id) async {
    final order = findOrder(id);
    if (!_editable || order == null || !OrderAccess.canComplete(order, localUser.id)) {
      return false;
    }
    return _commitReceiptState(
      state.copyWith(
        orders: [
          for (final saved in state.orders)
            if (saved.id == id) saved.withStatus(CartOrderStatus.completed) else saved,
        ],
      ),
    );
  }

  Future<bool> submitOrderDispute(
    String id,
    String description,
    List<DisputeAttachment> attachments,
  ) async {
    final order = findOrder(id);
    if (!_editable ||
        order == null ||
        !OrderAccess.canDispute(order, localUser.id) ||
        description.trim().isEmpty) {
      return false;
    }
    final dispute = OrderDispute(
      id: 'DSP-${DateTime.now().microsecondsSinceEpoch}',
      description: description.trim(),
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    return _commitReceiptState(
      state.copyWith(
        orders: [
          for (final saved in state.orders)
            if (saved.id == id) saved.withDispute(dispute).markRead(asProvider: false) else saved,
        ],
      ),
    );
  }

  Future<bool> acceptProviderOrder(String id) async {
    final order = findOrder(id);
    if (order == null || !OrderAccess.canAccept(order, localUser.id)) return false;
    final status = order.isPaidReceipt ? CartOrderStatus.accepted : CartOrderStatus.pendingPay;
    return _saveOrder(order.withStatus(status).markRead(asProvider: true));
  }

  Future<bool> advanceProviderOrder(String id) async {
    final order = findOrder(id);
    if (order == null) return false;
    final next = OrderAccess.nextProviderStatus(order, localUser.id);
    if (next == null) return false;
    return _saveOrder(order.withStatus(next).markRead(asProvider: true));
  }

  Future<bool> cancelProviderOrder(
    String id,
    String reason,
    List<DisputeAttachment> attachments,
  ) async {
    final order = findOrder(id);
    if (order == null || !OrderAccess.canCancel(order, localUser.id) || reason.trim().isEmpty) {
      return false;
    }
    final cancellation = OrderCancellation(
      providerId: localUser.id,
      reason: reason.trim(),
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    return _saveOrder(order.withCancellation(cancellation));
  }

  Future<bool> markOrderRead(String id, {required bool asProvider}) async {
    final order = findOrder(id);
    if (order == null ||
        !(asProvider
            ? OrderAccess.isProvider(order, localUser.id)
            : OrderAccess.isBuyer(order, localUser.id))) {
      return false;
    }
    final readAt = asProvider ? order.providerReadAt : order.customerReadAt;
    final eventAt = order.timeline[order.status] ?? order.createdAt;
    if (readAt != null && !readAt.isBefore(eventAt)) return true;
    return _saveOrder(order.markRead(asProvider: asProvider));
  }

  Future<bool> _saveOrder(CartOrder order) => _commitReceiptState(
    state.copyWith(
      orders: [
        for (final saved in state.orders)
          if (saved.id == order.id) order else saved,
      ],
    ),
  );

  CartItem _restoreKnownSeller(CartItem item) {
    if (item.seller != null) return item;
    if (demoCartItems.any((sample) => sample.id == item.id)) {
      return item.withQuantity(item.quantity, seller: demoCartSeller);
    }
    return item;
  }

  bool toggleItem(CartItem item) {
    if (!_editable) return false;
    if (!state.items.any((entry) => entry.id == item.id)) return add(item);
    remove(item.id);
    return true;
  }

  bool add(CartItem item) {
    if (!_editable) return false;
    final index = state.items.indexWhere((entry) => entry.id == item.id);
    final items = [...state.items];
    if (index < 0) {
      if (!item.accepts(item.quantity)) return false;
      items.insert(0, item);
    } else {
      final old = items[index];
      if (old.seller != null && item.seller != null && old.seller!.id != item.seller!.id) {
        return false;
      }
      if (!old.accepts(old.quantity + item.quantity)) return false;
      final updated = old.withQuantity(old.quantity + item.quantity, seller: item.seller);
      items.removeAt(index);
      items.insert(0, updated);
    }
    _removalTimers.remove(item.id)?.cancel();
    emit(
      state.copyWith(
        items: items,
        removals: state.removals.where((removal) => removal.item.id != item.id).toList(),
      ),
    );
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

  /// Cart-list deletion offers undo; Home and Details bag toggles stay unchanged.
  void removeWithUndo(String id) {
    if (!_editable) return;
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final originalItems = [...state.items];
    // Include earlier deletions so undoing several items preserves their order.
    for (final removal in state.removals.reversed) {
      _insertRestoredItem(originalItems, removal);
    }
    final removal = CartRemoval(
      item: state.items[index],
      expiresAt: DateTime.now().add(undoDuration),
      itemOrder: originalItems.map((item) => item.id).toList(),
    );
    _removalTimers.remove(id)?.cancel();
    _removalTimers[id] = Timer(undoDuration, () => _forgetRemoval(id));
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        removals: [...state.removals, removal],
      ),
    );
    _persist();
  }

  bool undoRemove(String id) {
    if (!_editable) return false;
    final index = state.removals.indexWhere((removal) => removal.item.id == id);
    if (index < 0) return false;
    final removal = state.removals[index];
    if (!DateTime.now().isBefore(removal.expiresAt) || state.items.any((item) => item.id == id)) {
      _forgetRemoval(id);
      return false;
    }
    final items = [...state.items];
    _insertRestoredItem(items, removal);
    _removalTimers.remove(id)?.cancel();
    emit(
      state.copyWith(
        items: items,
        removals: state.removals.where((removal) => removal.item.id != id).toList(),
      ),
    );
    _persist();
    return true;
  }

  void _insertRestoredItem(List<CartItem> items, CartRemoval removal) {
    if (items.any((item) => item.id == removal.item.id)) return;
    final order = removal.itemOrder;
    final originalIndex = order.indexOf(removal.item.id);
    for (final id in order.skip(originalIndex + 1)) {
      final nextIndex = items.indexWhere((item) => item.id == id);
      if (nextIndex >= 0) {
        items.insert(nextIndex, removal.item);
        return;
      }
    }
    for (final id in order.take(originalIndex).toList().reversed) {
      final previousIndex = items.indexWhere((item) => item.id == id);
      if (previousIndex >= 0) {
        items.insert(previousIndex + 1, removal.item);
        return;
      }
    }
    items.add(removal.item);
  }

  void _forgetRemoval(String id) {
    _removalTimers.remove(id)?.cancel();
    if (isClosed) return;
    emit(state.copyWith(removals: state.removals.where((entry) => entry.item.id != id).toList()));
  }

  void clear() {
    if (!_editable) return;
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
    emit(state.copyWith(items: [], removals: [], charges: 0));
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
          customerId: localUser.id,
          buyer: localUser,
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

  // Called only by a verified payment result; demo completion never calls this.
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

  @override
  Future<void> close() {
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
    return super.close();
  }
}
