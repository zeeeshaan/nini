import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/payment_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/payment/domain/models/payment_details.dart';
import 'package:hywork/features/payment/domain/models/payment_method.dart';
import 'package:hywork/features/payment/presentation/cubit/payment_selection_cubit.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_actions.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_delivery.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_escrow.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_methods.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_order_details.dart';
import 'package:hywork/features/payment/presentation/widgets/checkout/payment_summary.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Checkout review between customer information and the payment gateway.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.details,
    this.initialMethod = PaymentMethod.mellat,
    this.onMethodChanged,
    this.onConfirm,
  });
  final PaymentDetails details;
  final PaymentMethod initialMethod;
  final ValueChanged<PaymentMethod>? onMethodChanged;
  final Future<String?> Function()? onConfirm;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final _payment = PaymentSelectionCubit(widget.initialMethod);
  bool _paying = false;

  Future<void> _pay() async {
    if (_paying || widget.onConfirm == null) return;
    setState(() => _paying = true);
    try {
      final orderId = await widget.onConfirm!();
      if (mounted && orderId != null) Navigator.of(context).pop(orderId);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  void dispose() {
    _payment.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PaymentSelectionCubit, PaymentMethod>(
        bloc: _payment,
        builder: (context, method) => Localizations.override(
          context: context,
          locale: const Locale('en'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ScreenEntrance(
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      PaymentStrings.checkout,
                      style: AppTextStyles.screenTitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    PopupMenuButton<String>(
                      tooltip: AppStrings.moreOptions,
                      icon: const AppIcon(AppIcons.more, size: 20),
                      onSelected: (_) => Navigator.of(context).pop(),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            PaymentStrings.editInformation,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),

                    IconButton(
                      tooltip: AppStrings.back,
                      icon: const AppIcon(AppIcons.backRight, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                body: SafeArea(
                  top: false,
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.details.items.isNotEmpty) ...[
                              PaymentOrderDetails(details: widget.details),
                              const SizedBox(height: 12),
                            ],
                            PaymentDelivery(details: widget.details),
                            const SizedBox(height: 18),
                            PaymentSummary(details: widget.details),
                            const SizedBox(height: 20),
                            const Text(
                              PaymentStrings.paymentMethod,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.sectionTitle,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 10),
                            PaymentMethods(
                              selected: method,
                              labelBuilder: (method) => method.label,
                              onSelected: (selected) {
                                _payment.select(selected);
                                widget.onMethodChanged?.call(selected);
                              },
                            ),
                            const SizedBox(height: 12),
                            const PaymentEscrow(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: PaymentActions(
                        onConfirm: widget.onConfirm == null ? null : _pay,
                        isProcessing: _paying,
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
