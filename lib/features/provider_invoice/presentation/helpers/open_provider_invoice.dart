import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/cart/domain/policies/order_access.dart';
import 'package:hywork/features/cart/presentation/cubit/cart_cubit.dart';

import '../pages/provider_invoice_screen.dart';

Future<void> openProviderInvoice(BuildContext context, String orderId) async {
  final cart = context.read<CartCubit>();
  final order = cart.findOrder(orderId);
  if (order == null || !OrderAccess.isProvider(order, cart.localUser.id)) {
    return;
  }
  await cart.markOrderRead(orderId, asProvider: true);
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => ProviderInvoiceScreen(orderId: orderId)),
  );
}
