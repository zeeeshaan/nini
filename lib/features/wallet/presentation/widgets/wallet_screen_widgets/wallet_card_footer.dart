import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/wallet_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../data/wallet_sample_data.dart';

class WalletCardFooter extends StatelessWidget {
  const WalletCardFooter({super.key, required this.showWithdrawal});
  final bool showWithdrawal;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        WalletStrings.ownerLabel(WalletSampleData.owner),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      const Spacer(),
      if (showWithdrawal)
        Flexible(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppStrings.persianDigits(WalletSampleData.withdrawalAmount),
                maxLines: 1,
                style: const TextStyle(fontSize: 20),
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
                      style: TextStyle(fontSize: 10),
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
        ),
    ],
  );
}
