import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import '../widgets/overview/wallet_actions_row.dart';
import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_header.dart';
import '../widgets/overview/wallet_transactions.dart';
import 'top_up_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Scaffold(
      appBar: const WalletHeader(title: WalletStrings.wallet),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                children: [
                  const WalletBalanceCard(),
                  const SizedBox(height: 26),
                  WalletActionsRow(
                    onTopUp: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TopUpScreen(),
                      ),
                    ),
                    onWithdraw: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WithdrawScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const WalletTransactions(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
