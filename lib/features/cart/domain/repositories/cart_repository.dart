// dart format width=100
import '../models/cart_snapshot.dart';

abstract class CartRepository {
  /// Null means first launch; an empty snapshot means the cart was emptied.
  Future<CartSnapshot?> load();
  Future<void> save(CartSnapshot snapshot);
}

class MemoryCartRepository implements CartRepository {
  MemoryCartRepository([this.snapshot]);
  CartSnapshot? snapshot;
  @override
  Future<CartSnapshot?> load() async => snapshot;
  @override
  Future<void> save(CartSnapshot snapshot) async => this.snapshot = snapshot;
}
