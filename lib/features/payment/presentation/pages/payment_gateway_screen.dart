import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/localization/strings/payment_strings.dart';
import 'package:hywork/core/localization/strings/receipt_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/utils/cart_helpers.dart';
import 'package:hywork/features/payment/domain/models/payment_details.dart';
import 'package:hywork/features/payment/domain/models/payment_method.dart';
import 'package:hywork/features/payment/presentation/pages/payment_success_screen.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

/// Explicit demo handoff. This never calls a bank or confirms a real payment.
class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({
    super.key,
    this.details,
    this.method,
    this.successReturnLabel,
  });
  final PaymentDetails? details;
  final PaymentMethod? method;
  final String? successReturnLabel;

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
        builder: (_) => PaymentSuccessScreen(
          orderId: order.id,
          returnLabel: widget.successReturnLabel ?? ReceiptStrings.backToCart,
        ),
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
            automaticallyImplyLeading: false,
            title: Align(
              alignment: Alignment.centerRight,
              child: const Text(
                PaymentStrings.paymentGateway,
                style: AppTextStyles.pageTitle,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
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
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),

              IconButton(
                tooltip: AppStrings.back,
                icon: const AppIcon(AppIcons.backRight, size: 20),
                onPressed: _processing
                    ? null
                    : () => Navigator.of(context).pop(),
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
                          textDirection: TextDirection.ltr,
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
                            textDirection: TextDirection.ltr,
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
                            textDirection: TextDirection.ltr,
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
                          textDirection: TextDirection.ltr,
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
