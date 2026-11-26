import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/wallet_strings.dart';

import '../widgets/top_up/wallet_payment_methods.dart';
import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_bottom_button.dart';
import '../widgets/overview/wallet_page.dart';
import '../widgets/withdraw/wallet_amount_section.dart';
import 'withdraw_screen.dart';

/// Payment remains a UI preview; choosing a bank does not move funds.
class TopUpScreen extends StatelessWidget {
  const TopUpScreen({super.key});
  @override
  Widget build(BuildContext context) => WalletPage(
    title: WalletStrings.topUpTitle,
    footer: WalletBottomButton(
      label: WalletStrings.payment,
      onPressed: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      },
    ),
    child: Column(
      children: [
        WalletBalanceCard(
          onTopUp: () => FocusScope.of(context).unfocus(),
          onWithdraw: () => Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const WithdrawScreen()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: WalletAmountSection(label: WalletStrings.chargeAmount),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 28, 6, 0),
          child: WalletPaymentMethods(),
        ),
      ],
    ),
  );
}
