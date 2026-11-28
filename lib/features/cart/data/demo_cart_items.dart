// dart format width=100
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/shared/models/post/post_unit.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

import '../models/cart_item.dart';

/// Frontend fixtures matching the reference. No remote orders are implied.
const demoCartSeller = PostSeller(id: 'demo-cart-seller', name: 'HYWORK Store', avatarAsset: '');

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
