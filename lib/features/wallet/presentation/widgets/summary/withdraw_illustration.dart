import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

class WithdrawIllustration extends StatelessWidget {
  const WithdrawIllustration({super.key});
  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) => SizedBox(
      height: (responsive.width * .4).clamp(96, 150),
      width: double.infinity,
      child: Image.asset(
        'assets/wallet/withdrawal.png',
        fit: BoxFit.contain,
        semanticLabel: WalletStrings.illustration,
      ),
    ),
  );
}
