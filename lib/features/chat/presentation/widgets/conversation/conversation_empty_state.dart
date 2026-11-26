import 'package:flutter/material.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

class ConversationEmptyState extends StatelessWidget {
  const ConversationEmptyState({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.verticalSpacing,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          AppStrings.noMessages,
          textAlign: TextAlign.right,
          style: AppTextStyles.bodyText.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    ),
  );
}
