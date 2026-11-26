import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class SettingsEmptyState extends StatelessWidget {
  const SettingsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.grid,
    this.onRetry,
    this.textAlign = TextAlign.right,
  });
  final String title, message, icon;
  final VoidCallback? onRetry;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: AppIcon(icon, size: 40)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: textAlign,
              style: AppTextStyles.sectionTitle,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: textAlign,
              style: AppTextStyles.body,
              textDirection: TextDirection.ltr,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(label: AppStrings.retry, onPressed: onRetry),
            ],
          ],
        ),
      ),
    ),
  );
}
