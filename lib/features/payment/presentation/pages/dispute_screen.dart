import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/receipt_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/utils/order_access.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/payment/presentation/widgets/dispute/order_problem_form.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class DisputeScreen extends StatelessWidget {
  const DisputeScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final order = cart.findOrder(orderId);
    final allowed =
        order != null && OrderAccess.isBuyer(order, cart.localUser.id);
    final dispute = allowed ? order.dispute : null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            ReceiptStrings.dispute,
            style: AppTextStyles.pageTitle,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        centerTitle: false,

        actions: [
          IconButton(
            tooltip: AppStrings.back,
            icon: const AppIcon(AppIcons.backRight, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: !allowed
          ? const Center(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ReceiptStrings.unavailable,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            )
          : OrderProblemForm(
              heading: ReceiptStrings.problemHeading,
              hint: ReceiptStrings.describeProblem,
              requiredMessage: ReceiptStrings.descriptionRequired,
              actionLabel: ReceiptStrings.dispute,
              successMessage: ReceiptStrings.disputeSaved,
              localNotice: ReceiptStrings.disputeLocalNotice,
              initialText: dispute?.description,
              initialAttachments: dispute?.attachments ?? const [],
              readOnly: !OrderAccess.canDispute(order, cart.localUser.id),
              onSubmit: (text, attachments) =>
                  cart.submitOrderDispute(orderId, text, attachments),
            ),
    );
  }
}
