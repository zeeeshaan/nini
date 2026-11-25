import 'package:nini/shared/cubits/countdown_cubit.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/wallet_strings.dart';

import 'wallet_text_field.dart';

/// Local countdown preview only. No OTP is generated, sent, or verified.
class WithdrawOtpFields extends StatefulWidget {
  const WithdrawOtpFields({super.key});
  @override
  State<WithdrawOtpFields> createState() => _WithdrawOtpFieldsState();
}

class _WithdrawOtpFieldsState extends State<WithdrawOtpFields> {
  final _countdown = CountdownCubit(59);
  @override
  void dispose() {
    _countdown.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CountdownCubit, CountdownState>(
    bloc: _countdown,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          WalletStrings.password,
          textAlign: TextAlign.right,
          style: AppTextStyles.helper,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: WalletTextField()),
            const SizedBox(width: 6),
            Container(
              width: 88,
              constraints: const BoxConstraints(minHeight: 40),
              child: OutlinedButton(
                onPressed: _countdown.state.running ? null : _countdown.start,
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
                  style: AppTextStyles.helper,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          WalletStrings.securityHelp,
          textAlign: TextAlign.right,
          style: AppTextStyles.smallPrint.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .3),
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: WalletTextField()),
            const SizedBox(width: 6),
            Container(
              width: 88,
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                  '00:${_countdown.state.seconds.toString().padLeft(2, '0')}',
                ),
                style: AppTextStyles.helper,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
