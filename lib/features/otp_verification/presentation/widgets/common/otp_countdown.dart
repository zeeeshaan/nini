import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';
import 'package:nini/shared/cubits/countdown_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class OtpCountdown extends StatefulWidget {
  const OtpCountdown({super.key, this.onResend, this.onExpired});

  // Return true only when the backend accepts the resend.
  final Future<bool> Function()? onResend;
  final VoidCallback? onExpired;

  @override
  State<OtpCountdown> createState() => _OtpCountdownState();
}

class _OtpCountdownState extends State<OtpCountdown> {
  final _expiry = CountdownCubit(300, startImmediately: true);

  final _resend = CountdownCubit(60, startImmediately: true);

  bool _resending = false;

  Future<void> _requestResend() async {
    if (_resending || widget.onResend == null) return;

    _resending = true;

    try {
      final accepted = await widget.onResend!();

      if (!mounted || !accepted) return;

      // Restart both timers after a successful resend.
      _resend.start();
      _expiry.start();
    } catch (_) {
      // The parent screen handles and displays API errors.
    } finally {
      _resending = false;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');

    return AppStrings.persianDigits('$minutes:$remaining');
  }

  @override
  void dispose() {
    _expiry.close();
    _resend.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CountdownCubit, CountdownState>(
      bloc: _expiry,
      listenWhen: (previous, current) =>
          previous.seconds > 0 && current.seconds == 0,
      listener: (context, state) {
        widget.onExpired?.call();
      },
      child: BlocBuilder<CountdownCubit, CountdownState>(
        bloc: _expiry,
        builder: (context, expiryState) {
          return BlocBuilder<CountdownCubit, CountdownState>(
            bloc: _resend,
            builder: (context, resendState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expiryState.seconds == 0
                        ? 'Code expired'
                        : 'Code expires in: ${_formatTime(expiryState.seconds)}',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  if (resendState.seconds == 0)
                    TextButton(
                      onPressed: widget.onResend == null
                          ? null
                          : _requestResend,
                      child: const Text(
                        AuthStrings.resendCode,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    )
                  else
                    Semantics(
                      label: AuthStrings.resendCountdown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatTime(resendState.seconds),
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.label,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
