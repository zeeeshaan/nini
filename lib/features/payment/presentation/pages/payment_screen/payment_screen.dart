import 'package:nini/features/payment/presentation/cubit/payment_selection_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/features/payment/domain/models/payment_method.dart';
import 'package:nini/features/payment/presentation/widgets/payment_screen_widgets/payment_methods/payment_methods.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/presentation/widgets/payment_screen_widgets/payment_actions/payment_actions.dart';
import 'package:nini/features/payment/presentation/widgets/payment_screen_widgets/payment_delivery/payment_delivery.dart';
import 'package:nini/features/payment/presentation/widgets/payment_screen_widgets/payment_summary/payment_summary.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

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
  final VoidCallback? onConfirm;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final _payment = PaymentSelectionCubit(widget.initialMethod);

  @override
  void dispose() {
    _payment.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PaymentSelectionCubit, PaymentMethod>(
        bloc: _payment,
        builder: (context, state) => Localizations.override(
          context: context,
          locale: const Locale('en'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ScreenEntrance(
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: const AppIcon(AppIcons.back, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Payment method'),
                  ),
                ),
                body: SafeArea(
                  top: false,
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: PaymentMethods(
                                selected: _payment.state,
                                labelBuilder: (method) => switch (method) {
                                  PaymentMethod.melli => 'Bank Melli',
                                  PaymentMethod.mellat => 'Bank Mellat',
                                  PaymentMethod.saman => 'Saman Bank',
                                },
                                onSelected: (method) {
                                  _payment.select(method);
                                  widget.onMethodChanged?.call(method);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            PaymentDelivery(details: widget.details),
                            const SizedBox(height: 32),
                            PaymentSummary(details: widget.details),
                            const SizedBox(height: 32),
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
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: PaymentActions(onConfirm: widget.onConfirm),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
