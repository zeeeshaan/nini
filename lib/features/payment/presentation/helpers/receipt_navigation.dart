import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/payment/presentation/pages/invoice_screen/invoice_screen.dart';

Future<void> openSavedInvoice(BuildContext context, String orderId) async {
  final cart = context.read<CartCubit>();
  final order = cart.findOrder(orderId);
  if (order == null || !OrderAccess.isBuyer(order, cart.localUser.id)) return;
  await cart.markOrderRead(orderId, asProvider: false);
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => InvoiceScreen(orderId: orderId)),
  );
}
