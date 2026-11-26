import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/splash_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/theme/app_theme/app_theme.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';

class SplashSessionError extends StatelessWidget {
  const SplashSessionError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            SplashStrings.sessionRestoreFailed,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(label: SplashStrings.retrySession, onPressed: onRetry),
        ],
      ),
    ),
  );
}
