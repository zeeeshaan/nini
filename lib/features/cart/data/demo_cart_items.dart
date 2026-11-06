// dart format width=100
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/shared/models/post/post_unit.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import '../domain/models/cart_item.dart';
import '../domain/models/cart_order_status.dart';

/// Frontend fixtures matching the reference. No remote orders are implied.
const demoCartSeller = PostSeller(
  id: 'demo-cart-seller',
  name: 'HYWORK Store',
  avatarAsset: 'assets/Mask group.png',
);

const demoCartItems = [
  CartItem(
    id: 'training-1',
    seller: demoCartSeller,
    title: CartStrings.training,
    category: CartStrings.language,
    unit: PostUnit.hour,
    unitPrice: 291000,
    quantity: 200,
  ),
  CartItem(
    id: 'custom-2',
    seller: demoCartSeller,
    title: CartStrings.training,
    category: CartStrings.language,
    unit: PostUnit.kilogram,
    unitPrice: 291000,
    quantity: 200,
    status: CartOrderStatus.completed,
  ),
  CartItem(
    id: 'training-3',
    seller: demoCartSeller,
    title: CartStrings.training,
    category: CartStrings.language,
    unit: PostUnit.hour,
    unitPrice: 952000,
  ),
  CartItem(
    id: 'training-4',
    seller: demoCartSeller,
    title: CartStrings.training,
    category: CartStrings.language,
    unit: PostUnit.session,
    unitPrice: 174000,
    quantity: 300,
  ),
  CartItem(
    id: 'custom-5',
    seller: demoCartSeller,
    title: CartStrings.training,
    category: CartStrings.language,
    unit: PostUnit.piece,
    unitPrice: 305000,
    quantity: 500,
  ),
];
