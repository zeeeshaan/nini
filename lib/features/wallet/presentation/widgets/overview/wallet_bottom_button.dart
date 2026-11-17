import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

class WalletBottomButton extends StatelessWidget {
  const WalletBottomButton({
    super.key,
    this.label = WalletStrings.done,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 406),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            child: FilledButton(
              onPressed: onPressed,
              child: Text(
                label,
                style: AppTextStyles.pageTitle,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
