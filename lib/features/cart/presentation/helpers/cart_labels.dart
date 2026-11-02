import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/shared/models/post/post_unit.dart';

import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_order_status.dart';

/// Resolve known sample IDs in the display language without rewriting stored data.
const _demoIds = {
  'training-1',
  'custom-2',
  'training-3',
  'training-4',
  'custom-5',
};
String cartItemTitle(CartItem item) {
  if (_demoIds.contains(item.id)) return CartStrings.training;
  if (item.id == 'home-pixel9') return CartStrings.phone;
  return item.title;
}

String cartItemCategory(CartItem item) {
  if (_demoIds.contains(item.id)) return CartStrings.language;
  if (item.id == 'home-pixel9') return CartStrings.mobile;
  return AppStrings.postCategory(item.category);
}

String cartUnit(PostUnit unit, int quantity) => unit.label;
String? cartItemBadgeLabel(CartItem item) {
  if (item.status != null && item.status != CartOrderStatus.pendingPay) {
    return item.status!.label;
  }
  return item.isPreOrder ? CartStrings.preOrder : null;
}
