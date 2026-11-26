import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_assets/app_assets.dart';
import 'package:hywork/core/localization/strings/auth_strings.dart';
import 'package:hywork/features/otp_verification/presentation/pages/otp_verification_screen.dart';
import 'package:hywork/features/login/presentation/widgets/common/auth_screen_layout.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:hywork/shared/widgets/app_loader/app_loader.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';

import '../../data/auth_repo.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/common/login_phone_field.dart';
import '../widgets/common/login_email_field.dart';
import '../widgets/common/login_google_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}) : useEmail = false;

  const LoginScreen.email({super.key}) : useEmail = true;

  final bool useEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _requestOtp(BuildContext context) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (_form.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      widget.useEmail
          ? EmailOtpRequested(_identifier.text.trim())
          : OtpRequested(_identifier.text.trim()),
    );
  }

  void _openEmail(BuildContext context) {
    FocusScope.of(context).unfocus();
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const LoginScreen.email()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(context.read<AuthRepository>()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpRequestAccepted) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  phoneNumber: '+98 ${state.phone.substring(1)}',
                ),
              ),
            );
          }

          if (state is EmailOtpRequestAccepted) {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    OtpVerificationScreen.forEmail(email: state.email),
              ),
            );
            AppToast.success(context, AuthStrings.emailOtpSent);
          }

          if (state is AuthFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          return AuthScreenLayout(
            illustration: AppAssets.loginIllustration,
            title: widget.useEmail
                ? AuthStrings.loginWithEmail
                : AuthStrings.login,
            buttonLabel: AuthStrings.done,
            onContinue: state is AuthLoading
                ? null
                : () => _requestOtp(context),
            actionsBelowContent: !widget.useEmail,
            actions: !widget.useEmail
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: AuthStrings.done,
                        height: 56,
                        onPressed: state is AuthLoading
                            ? null
                            : () => _requestOtp(context),
                      ),
                      const SizedBox(height: 12),
                      LoginGoogleButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () => _openEmail(context),
                      ),
                    ],
                  )
                : state is AuthLoading
                ? Semantics(
                    label: AuthStrings.loading,
                    liveRegion: true,
                    child: const SizedBox(
                      height: 56,
                      child: Center(child: AppLoader(size: 24)),
                    ),
                  )
                : null,
            content: Form(
              key: _form,
              child: widget.useEmail
                  ? LoginEmailField(
                      controller: _identifier,
                      onSubmitted: () => _requestOtp(context),
                    )
                  : LoginPhoneField(
                      controller: _identifier,
                      onSubmitted: () => _requestOtp(context),
                    ),
            ),
          );
        },
      ),
    );
  }
}
