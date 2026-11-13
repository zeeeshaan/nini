import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import '../../../data/wallet_sample_data.dart';
import 'withdraw_summary_row.dart';

class WithdrawSummaryDetails extends StatelessWidget {
  const WithdrawSummaryDetails({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      WithdrawSummaryRow(
        label: WalletStrings.balance,
        value: WalletSampleData.balance,
      ),
      WithdrawSummaryRow(
        label: WalletStrings.withdrawalAmount,
        value: WalletSampleData.withdrawalAmount,
      ),
      WithdrawSummaryRow(
        label: WalletStrings.pendingAmount,
        value: WalletSampleData.pendingAmount,
      ),
      WithdrawSummaryRow(
        label: WalletStrings.accountNumber,
        value: WalletStrings.accountHint,
        showBank: true,
      ),
    ],
  );
}
