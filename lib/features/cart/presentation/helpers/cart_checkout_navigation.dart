import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/cubit/cart_state.dart';
import 'package:nini/features/payment/presentation/pages/order_information_screen/order_information_screen.dart';

Future<void> openCartCheckout(BuildContext context, {String? itemId}) async {
  final cart = context.read<CartCubit>();
  if (cart.state.stage == CartStage.checkout) return;
  cart.checkout(itemId: itemId);
  if (cart.state.stage != CartStage.checkout ||
      cart.state.checkoutItems.isEmpty) {
    return;
  }
  try {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const OrderInformationScreen()),
    );
  } finally {
    if (!cart.isClosed) cart.back();
  }
}
