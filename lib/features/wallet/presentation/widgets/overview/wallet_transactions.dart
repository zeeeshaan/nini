import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_transaction_tile.dart';

class WalletTransactions extends StatelessWidget {
  const WalletTransactions({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        WalletStrings.transactions,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyEmphasis,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 16),
      const Text(
        WalletStrings.today,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyText,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 6),
      for (final transaction in WalletSampleData.today)
        WalletTransactionTile(transaction: transaction),
      const SizedBox(height: 22),
      const Text(
        WalletStrings.yesterday,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyText,
        textDirection: TextDirection.ltr,
      ),
      const SizedBox(height: 6),
      for (final transaction in WalletSampleData.yesterday)
        WalletTransactionTile(transaction: transaction),
    ],
  );
}
