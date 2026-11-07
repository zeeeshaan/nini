// dart format width=100
import 'package:nini/shared/models/post/post_unit.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import 'cart_order_status.dart';

/// Prices are whole toman; quantities use hundredths (250 means 2.5 units).
/// Totals therefore stay exact integer hundredths of a toman.
class CartItem {
  const CartItem({
    required this.id,
    required this.title,
    required this.category,
    required this.unit,
    required this.unitPrice,
    this.quantity = 100,
    this.discountPerUnit = 0,
    this.maxQuantity = 999900,
    this.imageUrl,
    this.isPreOrder = false,
    this.isService = false,
    this.status = CartOrderStatus.pendingPay,
    this.seller,
  });
  final String id, title, category;
  final PostUnit unit;
  final int unitPrice, quantity, discountPerUnit, maxQuantity;
  final String? imageUrl;
  final bool isPreOrder;
  final bool isService;
  final CartOrderStatus? status;
  final PostSeller? seller;
  bool get wholeUnits =>
      unit != PostUnit.kilogram &&
      unit != PostUnit.hour &&
      unit != PostUnit.meter &&
      unit != PostUnit.centimeter &&
      unit != PostUnit.day;
  int get subtotal => unitPrice * quantity;
  int get discount => discountPerUnit * quantity;
  int get total => subtotal - discount;
  bool accepts(int value) => value > 0 && value <= maxQuantity && (!wholeUnits || value % 100 == 0);

  CartItem withQuantity(int value, {PostSeller? seller}) => CartItem(
    id: id,
    title: title,
    category: category,
    unit: unit,
    unitPrice: unitPrice,
    quantity: value,
    discountPerUnit: discountPerUnit,
    maxQuantity: maxQuantity,
    imageUrl: imageUrl,
    isPreOrder: isPreOrder,
    isService: isService,
    status: status,
    seller: seller ?? this.seller,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'unit': unit.name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'discountPerUnit': discountPerUnit,
    'maxQuantity': maxQuantity,
    'imageUrl': imageUrl,
    'isPreOrder': isPreOrder,
    'isService': isService,
    'status': status?.name,
    if (seller != null) 'seller': seller!.toJson(),
  };
  factory CartItem.fromJson(Map<String, dynamic> json) {
    final unit = PostUnit.fromName(json['unit'] as String?);
    if (unit == null) throw const FormatException('Unknown cart unit');
    final item = CartItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      unit: unit,
      unitPrice: json['unitPrice'] as int,
      quantity: json['quantity'] as int,
      discountPerUnit: json['discountPerUnit'] as int,
      maxQuantity: json['maxQuantity'] as int,
      imageUrl: json['imageUrl'] as String?,
      isPreOrder: json['isPreOrder'] as bool,
      // Older local carts predate the explicit type flag. Only known service
      // categories are migrated; unit labels alone never imply a service.
      isService:
          json['isService'] as bool? ??
          const {
            'services',
            'service',
            'خدمات',
            'خدمات لوله‌کشی',
            'plumbing services',
          }.contains((json['category'] as String).trim().toLowerCase()),
      status: json.containsKey('status')
          ? CartOrderStatus.fromName(json['status'] as String?)
          : CartOrderStatus.pendingPay,
      seller: json['seller'] == null
          ? null
          : PostSeller.fromJson(Map<String, dynamic>.from(json['seller'] as Map)),
    );
    if (!item.accepts(item.quantity) ||
        item.unitPrice < 0 ||
        item.discountPerUnit < 0 ||
        item.discountPerUnit > item.unitPrice) {
      throw const FormatException('Invalid cart item');
    }
    return item;
  }
}
