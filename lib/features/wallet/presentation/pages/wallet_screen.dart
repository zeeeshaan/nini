import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_page.dart';
import '../widgets/overview/wallet_transactions.dart';
import 'top_up_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => WalletPage(
    title: WalletStrings.wallet,
    child: Column(
      children: [
        WalletBalanceCard(
          onTopUp: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const TopUpScreen())),
          onWithdraw: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const WithdrawScreen()),
          ),
        ),
        const SizedBox(height: 16),
        const WalletTransactions(),
      ],
    ),
  );
}
