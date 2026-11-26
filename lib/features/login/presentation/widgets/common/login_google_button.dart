import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hywork/core/constants/app_assets/app_assets.dart';
import 'package:hywork/core/localization/strings/auth_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

class LoginGoogleButton extends StatelessWidget {
  const LoginGoogleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    label: const Text(
      AuthStrings.loginWithGoogle,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    ),
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 48),
      textStyle: AppTextStyles.button.copyWith(
        fontFamily: AppTextStyles.fontFamily,
      ),
    ),
    icon: SvgPicture.asset(
      AppAssets.googleLogo,
      width: 22,
      height: 22,
      excludeFromSemantics: true,
    ),
    onPressed: onPressed,
  );
}
