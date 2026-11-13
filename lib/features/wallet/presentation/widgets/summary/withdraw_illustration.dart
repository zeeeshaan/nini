import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

class WithdrawIllustration extends StatelessWidget {
  const WithdrawIllustration({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260,
    width: double.infinity,
    child: Image.asset(
      'assets/wallet/withdrawal.png',
      fit: BoxFit.contain,
      semanticLabel: WalletStrings.illustration,
    ),
  );
}
