import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/auth_strings.dart';

/// Resend is a local countdown preview; it never requests or verifies an SMS.
class OtpCountdown extends StatefulWidget {
  const OtpCountdown({super.key});

  @override
  State<OtpCountdown> createState() => _OtpCountdownState();
}

class _OtpCountdownState extends State<OtpCountdown> {
  Timer? _timer;
  int _seconds = 120;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _seconds = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_seconds == 0) {
      return TextButton(
        onPressed: () => setState(_start),
        child: const Text(AuthStrings.resendCode),
      );
    }
    final time =
        '${_seconds ~/ 60}:'
        '${(_seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: AuthStrings.resendCountdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          AppStrings.persianDigits(time),
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
