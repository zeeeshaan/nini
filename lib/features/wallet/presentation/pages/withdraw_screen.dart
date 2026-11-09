import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/wallet_strings.dart';

import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_bottom_button.dart';
import '../widgets/overview/wallet_header.dart';
import '../widgets/withdraw/wallet_amount_section.dart';
import '../widgets/withdraw/withdraw_account_section.dart';
import '../widgets/withdraw/withdraw_otp_fields.dart';
import 'withdraw_summary_screen.dart';

/// UI-only form. Done opens a summary preview without moving funds.
class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});
  Future<void> _openSummary(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WithdrawSummaryScreen()),
    );
    if (context.mounted && done == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: const WalletHeader(title: WalletStrings.withdraw),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: const SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(22, 14, 22, 20),
              child: Column(
                children: [
                  WalletBalanceCard(showWithdrawal: true),
                  SizedBox(height: 30),
                  WalletAmountSection(),
                  SizedBox(height: 36),
                  WithdrawAccountSection(),
                  SizedBox(height: 20),
                  WithdrawOtpFields(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: WalletBottomButton(
        onPressed: () => _openSummary(context),
      ),
    ),
  );
}
