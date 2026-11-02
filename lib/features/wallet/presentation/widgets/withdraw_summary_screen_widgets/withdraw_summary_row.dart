import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';

import '../top_up_screen_widgets/wallet_bank_logo.dart';

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
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        if (showBank) ...[
          const WalletBankLogo(bank: 'melli', size: 26),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            AppStrings.persianDigits(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11),
          textDirection: TextDirection.rtl,
        ),
      ],
    ),
  );
}
