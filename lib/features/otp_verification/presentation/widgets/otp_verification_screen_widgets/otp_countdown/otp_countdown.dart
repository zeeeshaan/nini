import 'package:nini/core/state/countdown_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _countdown = CountdownCubit(120, startImmediately: true);
  @override
  void dispose() {
    _countdown.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CountdownCubit, CountdownState>(
        bloc: _countdown,
        builder: (context, state) {
          if (_countdown.state.seconds == 0) {
            return TextButton(
              onPressed: _countdown.start,
              child: const Text(AuthStrings.resendCode),
            );
          }
          final time =
              '${_countdown.state.seconds ~/ 60}:'
              '${(_countdown.state.seconds % 60).toString().padLeft(2, '0')}';
          return Semantics(
            label: AuthStrings.resendCountdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppStrings.persianDigits(time),
                textDirection: TextDirection.ltr,
                style: AppTextStyles.label,
              ),
            ),
          );
        },
      );
}
