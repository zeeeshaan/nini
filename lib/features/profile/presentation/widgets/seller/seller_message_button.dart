import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class SellerMessageButton extends StatelessWidget {
  const SellerMessageButton({super.key, required this.seller});

  final PostSeller seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = theme.outlinedButtonTheme.style ?? const ButtonStyle();
    return Theme(
      data: theme.copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(
              theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest
                  : AppColors.profileMessageBackground,
            ),
            foregroundColor: WidgetStatePropertyAll(
              theme.colorScheme.onSurface,
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            textStyle: WidgetStatePropertyAll(
              AppTextStyles.button.copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
        ),
      ),
      child: AppButton(
        label: AppStrings.message,
        height: 44,
        variant: AppButtonVariant.outlined,
        onPressed: () => openSellerConversation(context, seller),
      ),
    );
  }
}
