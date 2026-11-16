import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import 'wallet_action_tile.dart';

class WalletActionsRow extends StatelessWidget {
  const WalletActionsRow({
    super.key,
    required this.onWithdraw,
    required this.onTopUp,
  });
  final VoidCallback? onWithdraw, onTopUp;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Flexible(
        child: WalletActionTile(
          label: WalletStrings.topUp,
          icon: AppIcons.walletTopUp,
          onTap: onTopUp,
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: WalletActionTile(
          label: WalletStrings.withdraw,
          icon: AppIcons.walletWithdraw,
          onTap: onWithdraw,
        ),
      ),
    ],
  );
}
