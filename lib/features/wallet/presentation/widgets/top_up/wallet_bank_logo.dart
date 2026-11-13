import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

/// Reuses the same bundled bank artwork throughout the wallet flow.
class WalletBankLogo extends StatelessWidget {
  const WalletBankLogo({super.key, required this.bank, this.size = 40});
  final String bank;
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/banks/$bank.svg',
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticsLabel: WalletStrings.bankName(bank),
  );
}
