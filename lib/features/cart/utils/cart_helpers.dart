// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/cubit/cart_state.dart';
import 'package:hywork/features/cart/models/cart_item.dart';
import 'package:hywork/features/payment/presentation/pages/order_information_screen.dart';
import 'package:hywork/shared/models/post/post_unit.dart';

/// Parse Persian, Arabic or Latin numbers without floating point rounding.
int? parseCartAmount(String input) {
  var value = input.trim().replaceAll('٫', '.');
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  for (var digit = 0; digit < 10; digit++) {
    value = value.replaceAll(persian[digit], '$digit').replaceAll(arabic[digit], '$digit');
  }
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  return int.parse(parts[0]) * 100 + (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

String cartAmountInput(int hundredths) {
  final fraction = hundredths % 100;
  final suffix = fraction.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
  return '${hundredths ~/ 100}${fraction == 0 ? '' : '.$suffix'}';
}

String cartMoney(int hundredths) {
  final parts = cartAmountInput(hundredths).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return AppStrings.persianDigits('$whole${parts.length == 1 ? '' : '.${parts[1]}'}');
}

String cartQuantity(int hundredths) => AppStrings.persianDigits(cartAmountInput(hundredths));

/// Resolve known sample IDs in the display language without rewriting stored data.
const _demoIds = {'training-1', 'custom-2', 'training-3', 'training-4', 'custom-5'};

String cartItemTitle(CartItem item) {
  if (_demoIds.contains(item.id)) return CartStrings.training;
  return item.title;
}

String cartItemCategory(CartItem item) {
  if (_demoIds.contains(item.id)) return CartStrings.language;
  return AppStrings.postCategory(item.category);
}

String cartUnit(PostUnit unit, int quantity) => unit.label;

String? cartItemBadgeLabel(CartItem item) {
  if (item.status != null && item.status != CartOrderStatus.pendingPay) {
    return item.status!.label;
  }
  return item.isPreOrder ? CartStrings.preOrder : null;
}

Future<void> openCartCheckout(BuildContext context, {String? itemId}) async {
  final cart = context.read<CartCubit>();
  if (cart.state.stage == CartStage.checkout) return;
  cart.checkout(itemId: itemId);
  if (cart.state.stage != CartStage.checkout || cart.state.checkoutItems.isEmpty) {
    return;
  }
  try {
    await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const OrderInformationScreen()));
  } finally {
    if (!cart.isClosed) cart.back();
  }
}
