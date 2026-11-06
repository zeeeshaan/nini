import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/wallet_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../data/wallet_sample_data.dart';

class WalletCardFooter extends StatelessWidget {
  const WalletCardFooter({super.key, required this.showWithdrawal});
  final bool showWithdrawal;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 12,
    runSpacing: 12,
    children: [
      Text(
        WalletStrings.ownerLabel(WalletSampleData.owner),
        style: AppTextStyles.label,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      if (showWithdrawal)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppStrings.persianDigits(WalletSampleData.withdrawalAmount),
              style: AppTextStyles.amount,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    WalletStrings.withdrawalAmount,
                    style: AppTextStyles.smallPrint,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 6),
                AppIcon(
                  AppIcons.walletPayment,
                  size: 18,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ],
            ),
          ],
        ),
    ],
  );
}
