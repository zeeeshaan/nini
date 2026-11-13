import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import '../widgets/top_up/wallet_payment_methods.dart';
import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_bottom_button.dart';
import '../widgets/overview/wallet_header.dart';
import '../widgets/withdraw/wallet_amount_section.dart';

/// Payment is a UI preview: choosing a bank never calls a payment gateway.
class TopUpScreen extends StatelessWidget {
  const TopUpScreen({super.key});
  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: const WalletHeader(title: WalletStrings.topUpTitle),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: const SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: Column(
                children: [
                  WalletBalanceCard(),
                  SizedBox(height: 54),
                  WalletAmountSection(label: WalletStrings.chargeAmount),
                  SizedBox(height: 34),
                  WalletPaymentMethods(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: WalletBottomButton(
        label: WalletStrings.payment,
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
