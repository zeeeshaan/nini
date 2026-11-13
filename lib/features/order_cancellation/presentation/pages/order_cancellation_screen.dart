import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/provider_order_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/payment/presentation/widgets/dispute/order_problem_form.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class OrderCancellationScreen extends StatelessWidget {
  const OrderCancellationScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>();
    final order = cart.findOrder(orderId);
    final allowed =
        order != null && OrderAccess.isProvider(order, cart.localUser.id);
    final cancellation = allowed ? order.cancellation : null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: const Text(
            ProviderOrderStrings.cancellation,
            style: AppTextStyles.pageTitle,
            textAlign: TextAlign.right,
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
                  ProviderOrderStrings.unavailable,
                  textAlign: TextAlign.right,
                ),
              ),
            )
          : OrderProblemForm(
              heading: ProviderOrderStrings.cancellationHeading,
              hint: ProviderOrderStrings.cancellationHint,
              requiredMessage: ProviderOrderStrings.reasonRequired,
              actionLabel: ProviderOrderStrings.cancelOrder,
              successMessage: ProviderOrderStrings.cancelled,
              localNotice: ProviderOrderStrings.localNotice,
              initialText: cancellation?.reason,
              initialAttachments: cancellation?.attachments ?? const [],
              readOnly: !OrderAccess.canCancel(order, cart.localUser.id),
              onSubmit: (text, attachments) =>
                  cart.cancelProviderOrder(orderId, text, attachments),
            ),
    );
  }
}
