import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/wallet_strings.dart';

import 'wallet_text_field.dart';

/// Local countdown preview only. No OTP is generated, sent, or verified.
class WithdrawOtpFields extends StatefulWidget {
  const WithdrawOtpFields({super.key});
  @override
  State<WithdrawOtpFields> createState() => _WithdrawOtpFieldsState();
}

class _WithdrawOtpFieldsState extends State<WithdrawOtpFields> {
  Timer? _timer;
  int _seconds = 59;
  bool get _running => _timer?.isActive ?? false;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPreview() {
    _timer?.cancel();
    setState(() => _seconds = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        WalletStrings.password,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Expanded(child: WalletTextField()),
          const SizedBox(width: 6),
          SizedBox(
            width: 88,
            height: 40,
            child: OutlinedButton(
              onPressed: _running ? null : _startPreview,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .65),
                  width: .7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                WalletStrings.otp,
                style: TextStyle(fontSize: 11),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        WalletStrings.securityHelp,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3),
        ),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(child: WalletTextField()),
          const SizedBox(width: 6),
          Container(
            width: 88,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .65),
                width: .7,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppStrings.persianDigits(
                '00:${_seconds.toString().padLeft(2, '0')}',
              ),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    ],
  );
}
