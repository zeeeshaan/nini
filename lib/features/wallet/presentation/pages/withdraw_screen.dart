import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/wallet_strings.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

import '../../data/wallet_sample_data.dart';
import '../widgets/overview/wallet_balance_card.dart';
import '../widgets/overview/wallet_bottom_button.dart';
import '../widgets/overview/wallet_page.dart';
import '../widgets/summary/withdraw_success_sheet.dart';
import '../widgets/withdraw/wallet_amount_section.dart';
import '../widgets/withdraw/withdraw_review_notice.dart';
import 'top_up_screen.dart';

/// UI-only form; the confirmation sheet does not reserve or transfer funds.
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amount = TextEditingController(text: WalletSampleData.pendingAmount);
  bool _showingSummary = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _openSummary() async {
    if (_showingSummary) return;
    final amount = AppStrings.latinDigits(_amount.text).trim();
    final value = int.tryParse(amount.replaceAll(',', ''));
    if (value == null || value <= 0) {
      AppToast.error(context, WalletStrings.enterValidAmount);
      return;
    }
    _showingSummary = true;
    try {
      await showPostDialog<void>(context, WithdrawSuccessSheet(amount: amount));
      if (mounted) Navigator.of(context).pop();
    } finally {
      _showingSummary = false;
    }
  }

  @override
  Widget build(BuildContext context) => WalletPage(
    title: WalletStrings.withdraw,
    bottomNote: const WithdrawReviewNotice(),
    footer: WalletBottomButton(onPressed: _openSummary),
    child: Column(
      children: [
        WalletBalanceCard(
          onTopUp: () => Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(builder: (_) => const TopUpScreen()),
          ),
          onWithdraw: () => FocusScope.of(context).unfocus(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 32, 14, 0),
          child: WalletAmountSection(
            label: WalletStrings.withdrawAmountHint,
            controller: _amount,
          ),
        ),
      ],
    ),
  );
}
