import 'package:nini/features/payment/domain/models/payment_method.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/presentation/cubit/payment_selection_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import 'wallet_bank_tile.dart';

class WalletPaymentMethods extends StatefulWidget {
  const WalletPaymentMethods({super.key});
  @override
  State<WalletPaymentMethods> createState() => _WalletPaymentMethodsState();
}

class _WalletPaymentMethodsState extends State<WalletPaymentMethods> {
  final _payment = PaymentSelectionCubit();
  @override
  void dispose() {
    _payment.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PaymentSelectionCubit, PaymentMethod>(
        bloc: _payment,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              WalletStrings.paymentMethod,
              textAlign: TextAlign.right,
              style: AppTextStyles.helper,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 14),
            for (final bank in ['melli', 'mellat', 'saman'])
              WalletBankTile(
                bank: bank,
                selected: _payment.state.name == bank,
                onTap: () => _payment.select(PaymentMethod.values.byName(bank)),
              ),
          ],
        ),
      );
}
