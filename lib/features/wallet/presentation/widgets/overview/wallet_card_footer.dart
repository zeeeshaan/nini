import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/wallet_strings.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import '../../../data/wallet_sample_data.dart';
import 'wallet_actions_row.dart';

class WalletCardFooter extends StatelessWidget {
  const WalletCardFooter({
    super.key,
    required this.showWithdrawal,
    this.onTopUp,
    this.onWithdraw,
  });
  final bool showWithdrawal;
  final VoidCallback? onTopUp, onWithdraw;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final actions = SizedBox(
        width: (104 * scale).clamp(0, responsive.width),
        child: WalletActionsRow(onTopUp: onTopUp, onWithdraw: onWithdraw),
      );
      final owner = Text(
        WalletStrings.ownerLabel(WalletSampleData.owner),
        style: AppTextStyles.label,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      if (responsive.width < 220 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: actions),
            const SizedBox(height: 8),
            owner,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          actions,
          const SizedBox(width: 12),
          Expanded(child: owner),
        ],
      );
    },
  );
}
