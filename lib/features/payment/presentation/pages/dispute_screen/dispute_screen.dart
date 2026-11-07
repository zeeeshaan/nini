import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/payment/presentation/widgets/order_problem_form/order_problem_form.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

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
        title: const Text(
          ReceiptStrings.dispute,
          style: AppTextStyles.pageTitle,
        ),
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          icon: const AppIcon(AppIcons.back, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: !allowed
          ? const Center(child: Text(ReceiptStrings.unavailable))
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
