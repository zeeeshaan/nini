import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/wallet_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../top_up/wallet_bank_logo.dart';
import 'wallet_text_field.dart';

class WithdrawAccountSection extends StatelessWidget {
  const WithdrawAccountSection({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        WalletStrings.accountNumber,
        textAlign: TextAlign.right,
        style: AppTextStyles.helper,
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 8),
      WalletTextField(
        hint: WalletStrings.accountHint,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(7),
          child: WalletBankLogo(bank: 'melli', size: 26),
        ),
        suffixIcon: const Padding(
          padding: EdgeInsets.all(10),
          child: AppIcon(AppIcons.bank, size: 20),
        ),
      ),
    ],
  );
}
