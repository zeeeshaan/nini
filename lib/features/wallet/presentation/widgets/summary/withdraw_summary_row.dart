import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';

import '../top_up/wallet_bank_logo.dart';

class WithdrawSummaryRow extends StatelessWidget {
  const WithdrawSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.showBank = false,
  });
  final String label, value;
  final bool showBank;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        if (showBank) ...[
          const WalletBankLogo(bank: 'melli', size: 26),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            AppStrings.persianDigits(value),
            style: AppTextStyles.helper,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: AppTextStyles.helper,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    ),
  );
}
