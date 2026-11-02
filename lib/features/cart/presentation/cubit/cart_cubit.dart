// dart format width=100
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/demo_cart_items.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_order_status.dart';
import '../../domain/models/payment_method.dart';
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
          items: saved?.items ?? demoCartItems,
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
  bool add(CartItem item) {
    if (!_editable) return false;
    final index = state.items.indexWhere((entry) => entry.id == item.id);
    final items = [...state.items];
    if (index < 0) {
      if (!item.accepts(item.quantity)) return false;
      items.add(item);
    } else {
      final old = items[index];
      if (!old.accepts(old.quantity + item.quantity)) return false;
      items[index] = old.withQuantity(old.quantity + item.quantity);
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
}
