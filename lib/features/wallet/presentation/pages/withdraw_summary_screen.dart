import 'package:flutter/material.dart';
import 'package:hywork/core/localization/persian_feature/persian_feature.dart';
import 'package:hywork/core/localization/strings/wallet_strings.dart';

import '../widgets/overview/wallet_bottom_button.dart';
import '../widgets/overview/wallet_header.dart';
import '../widgets/summary/withdraw_illustration.dart';
import '../widgets/summary/withdraw_summary_details.dart';

/// Summary preview only; these sample values do not represent a completed transfer.
class WithdrawSummaryScreen extends StatelessWidget {
  const WithdrawSummaryScreen({super.key});
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
              padding: EdgeInsets.fromLTRB(26, 0, 26, 24),
              child: Column(
                children: [
                  WithdrawIllustration(),
                  SizedBox(height: 72),
                  WithdrawSummaryDetails(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: WalletBottomButton(
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ),
  );
}
