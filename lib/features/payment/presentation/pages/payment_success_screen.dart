import 'package:hywork/shared/widgets/app_back_button/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/receipt_strings.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/models/cart_order.dart';
import 'package:hywork/features/cart/utils/cart_helpers.dart';
import 'package:hywork/features/payment/presentation/helpers/receipt_navigation.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/features/payment/presentation/widgets/success/payment_success_card.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    this.returnLabel = ReceiptStrings.backToCart,
  });
  final String orderId;
  final String returnLabel;
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final order = cart.findOrder(orderId);
    final receipts = order == null
        ? <CartOrder>[]
        : cart.state.orders
              .where(
                (saved) => order.checkoutId == null
                    ? saved.id == order.id
                    : saved.checkoutId == order.checkoutId,
              )
              .toList();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            ReceiptStrings.paymentDone,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),

        actions: [const AppBackButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentSuccessCard(
                  amount: order == null
                      ? null
                      : cartMoney(
                          receipts.fold(
                            0,
                            (sum, receipt) => sum + receipt.total,
                          ),
                        ),
                  method: order?.method.label,
                  reference: order?.invoiceId ?? order?.id,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: const Text(
                    ReceiptStrings.demoNotice,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: 24),
                for (final receipt in receipts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppButton(
                      label: receipts.length == 1
                          ? ReceiptStrings.viewInvoice
                          : '${ReceiptStrings.viewInvoice} · ${receipt.seller?.name ?? receipt.id}',
                      onPressed: () => openSavedInvoice(context, receipt.id),
                    ),
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: returnLabel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
