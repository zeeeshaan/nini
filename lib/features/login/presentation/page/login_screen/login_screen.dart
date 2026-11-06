import 'package:flutter/material.dart';
import 'package:nini/core/assets/app_assets.dart';
import 'package:nini/core/localization/auth_strings.dart';
import 'package:nini/features/otp_verification/presentation/page/otp_verification_screen/otp_verification_screen.dart';
import 'package:nini/features/login/presentation/widgets/auth_screen_layout/auth_screen_layout.dart';

import '../../widgets/login_screen_widgets/login_phone_field/login_phone_field.dart';

/// UI-only phone entry. Any nonempty number can continue; no SMS is sent.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _opening = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _openOtp() async {
    if (_opening || !_form.currentState!.validate()) return;
    _opening = true;
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            OtpVerificationScreen(phoneNumber: '+98 ${_phone.text.trim()}'),
      ),
    );
    if (mounted) _opening = false;
  }

  @override
  Widget build(BuildContext context) => AuthScreenLayout(
    illustration: AppAssets.loginIllustration,
    title: AuthStrings.login,
    buttonLabel: AuthStrings.done,
    onContinue: _openOtp,
    content: Form(
      key: _form,
      child: LoginPhoneField(controller: _phone, onSubmitted: _openOtp),
    ),
  );
}
