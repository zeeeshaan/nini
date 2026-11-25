import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/constants/app_assets/app_assets.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/login/presentation/pages/login_screen.dart';
import 'package:nini/features/login/presentation/widgets/common/auth_screen_layout.dart';
import 'package:nini/features/otp_verification/presentation/cubit/otp_verification_cubit.dart';

import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';

import '../../../login/data/auth_repo.dart';
import '../../data/otp_verification_repo.dart';
import '../widgets/common/otp_code_input.dart';
import '../widgets/common/otp_countdown.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber})
    : email = null;

  const OtpVerificationScreen.forEmail({super.key, required String this.email})
    : phoneNumber = '';

  final String phoneNumber;
  final String? email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final AuthRepository _authRepository = context.read<AuthRepository>();

  late final OtpVerificationCubit _verification = OtpVerificationCubit(
    context.read<OtpVerificationRepository>(),
  );

  bool _expired = false;
  int _inputVersion = 0;
  bool _navigated = false;

  void _verifyOtp() {
    if (_expired || !_verification.state.canVerify) return;

    FocusScope.of(context).unfocus();

    if (widget.email != null) {
      _verification.verifyEmailOtp(widget.email!);
    } else {
      _verification.verifyOtp(widget.phoneNumber);
    }
  }

  void _onExpired() {
    if (_expired || !mounted) return;

    _expired = true;
    _inputVersion++;

    _verification.changeCode('');
  }

  Future<bool> _resendOtp() async {
    if (_verification.state.isLoading || _verification.state.isVerified) {
      return false;
    }

    try {
      if (widget.email != null) {
        await _authRepository.requestEmailOtp(widget.email!);
      } else {
        await _authRepository.requestOtp(widget.phoneNumber);
      }

      if (!mounted) return false;

      _expired = false;
      _inputVersion++;

      _verification.changeCode('');

      return true;
    } on DioException catch (error) {
      if (!mounted) return false;

      final message = error.response?.statusCode == 429
          ? 'Too many requests. Please try again later.'
          : 'Could not resend OTP. Please try again.';

      _showError(message);
      return false;
    } catch (_) {
      if (!mounted) return false;

      _showError('Could not resend OTP. Please try again.');
      return false;
    }
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  void _openHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    FocusScope.of(context).unfocus();

    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(initialTab: DashboardTab.home),
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
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listener: (context, session) {
        if (!_verification.state.isVerified || _navigated) return;
        if (session.status == SessionStatus.authenticated) {
          _openHome();
        } else if (session.status == SessionStatus.failure) {
          _showError(AuthStrings.sessionRestoreFailed);
        } else if (session.status == SessionStatus.unauthenticated) {
          _navigated = true;
          Navigator.of(context).pushAndRemoveUntil<void>(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      },
      child: BlocConsumer<OtpVerificationCubit, OtpVerificationState>(
        bloc: _verification,
        listener: (context, state) {
          if (state.isVerified) {
            context.read<SessionCubit>().restore();
          } else if (state.errorMessage != null) {
            _showError(state.errorMessage!);
          }
        },
        builder: (context, state) {
          final session = context.watch<SessionCubit>().state;
          final checking = session.status == SessionStatus.checking;
          return PopScope(
            canPop: !state.isLoading && !checking,
            child: AuthScreenLayout(
              illustration: AppAssets.otpIllustration,
              illustrationScale: .72,
              title: AuthStrings.enterOtp,
              buttonLabel: state.isVerified
                  ? AuthStrings.retrySession
                  : AuthStrings.continueLabel,
              onContinue: checking
                  ? null
                  : state.isVerified
                  ? () => context.read<SessionCubit>().restore()
                  : state.canVerify && !_expired
                  ? _verifyOtp
                  : null,
              actions: state.isLoading || checking
                  ? Semantics(
                      label: AuthStrings.loading,
                      liveRegion: true,
                      child: const SizedBox(
                        height: 56,
                        child: Center(child: AppLoader(size: 24)),
                      ),
                    )
                  : null,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.email != null) ...[
                    Text(
                      AuthStrings.codeSentTo(widget.email!),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 16),
                  ],
                  OtpCodeInput(
                    key: ValueKey(_inputVersion),
                    phoneNumber: widget.email ?? widget.phoneNumber,
                    onChanged: _verification.changeCode,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OtpCountdown(
                      onResend: _resendOtp,
                      onExpired: _onExpired,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
