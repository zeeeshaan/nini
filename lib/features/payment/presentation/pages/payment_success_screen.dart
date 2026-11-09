import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/receipt_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/payment/presentation/helpers/receipt_navigation.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.orderId});
  final String orderId;
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
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            ReceiptStrings.paymentDone,
            textAlign: TextAlign.right,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.walletCredit,
                size: 72,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  ReceiptStrings.paymentSuccessful,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.pageTitleBold,
                ),
              ),
              if (order != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    cartMoney(
                      receipts.fold(0, (sum, saved) => sum + saved.total),
                    ),
                    style: AppTextStyles.analyticsTotal,
                    textAlign: TextAlign.right,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(order.method.label, textAlign: TextAlign.right),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    order.invoiceId ?? order.id,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  ReceiptStrings.demoNotice,
                  textAlign: TextAlign.right,
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
                label: ReceiptStrings.backToCart,
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
