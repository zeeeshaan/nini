import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/core/localization/payment_strings.dart';
import 'package:nini/core/localization/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/domain/models/payment_method.dart';
import 'package:nini/features/payment/presentation/pages/payment_success_screen.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

/// Explicit demo handoff. This never calls a bank or confirms a real payment.
class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key, this.details, this.method});
  final PaymentDetails? details;
  final PaymentMethod? method;

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  bool _processing = false;

  Future<void> _complete() async {
    final details = widget.details;
    final method = widget.method;
    if (_processing || details == null || method == null) return;
    setState(() => _processing = true);
    final order = await context.read<CartCubit>().completeDemoPayment(
      details,
      method,
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _processing = false);
      AppToast.warning(context, ReceiptStrings.paymentNotSaved);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(orderId: order.id),
      ),
    );
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.of(context).pop(order.id);
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
        canPop: !_processing,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: AppStrings.back,
              icon: const AppIcon(AppIcons.back, size: 20),
              onPressed: _processing ? null : () => Navigator.of(context).pop(),
            ),
            title: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                PaymentStrings.paymentGateway,
                style: AppTextStyles.pageTitle,
                textAlign: TextAlign.right,
              ),
            ),
            centerTitle: false,
            actions: [
              PopupMenuButton<String>(
                tooltip: AppStrings.moreOptions,
                enabled: !_processing,
                icon: const AppIcon(AppIcons.more, size: 20),
                onSelected: (_) => Navigator.of(context).pop(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'checkout',
                    child: Text(
                      PaymentStrings.backToCheckout,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          ReceiptStrings.demoPayment,
                          style: AppTextStyles.pageTitleBold,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (widget.method != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            widget.method!.label,
                            style: AppTextStyles.bodyBold,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      if (widget.details != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${cartMoney(widget.details!.total)} ${CartStrings.toman}',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.analyticsTotal,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          ReceiptStrings.demoNotice,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.body,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        label: ReceiptStrings.completeDemoPayment,
                        isLoading: _processing,
                        onPressed:
                            widget.details?.checkoutId == null ||
                                widget.method == null
                            ? null
                            : _complete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
