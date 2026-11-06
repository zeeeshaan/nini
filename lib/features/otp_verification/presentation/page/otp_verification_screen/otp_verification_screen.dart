import 'package:nini/features/otp_verification/presentation/cubit/otp_verification_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/assets/app_assets.dart';
import 'package:nini/core/localization/auth_strings.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nini/features/locations/presentation/widgets/location_permission_gate/location_permission_gate.dart';
import 'package:nini/features/login/presentation/widgets/auth_screen_layout/auth_screen_layout.dart';

import '../../widgets/otp_verification_screen_widgets/otp_code_input/otp_code_input.dart';
import '../../widgets/otp_verification_screen_widgets/otp_countdown/otp_countdown.dart';

/// UI preview: Continue accepts any four digits; no SMS validation is performed.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _verification = OtpVerificationCubit();

  void _openHome() {
    if (!_verification.complete()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LocationPermissionGate(
          child: DashboardScreen(
            initialTab: DashboardTab.home,
            profileImage: AssetImage('assets/Mask group.png'),
          ),
        ),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _verification.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OtpVerificationCubit, String>(
        bloc: _verification,
        builder: (context, state) => AuthScreenLayout(
          illustration: AppAssets.otpIllustration,
          illustrationScale: .72,
          title: AuthStrings.enterOtp,
          buttonLabel: AuthStrings.continueLabel,
          onContinue: _verification.state.length == 4 ? _openHome : null,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OtpCodeInput(
                phoneNumber: widget.phoneNumber,
                onChanged: (code) => _verification.changeCode(code),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: OtpCountdown(),
              ),
            ],
          ),
        ),
      );
}
