import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';

import 'seller_message_button.dart';

class SellerProfileActions extends StatelessWidget {
  const SellerProfileActions({
    super.key,
    required this.seller,
    this.isFollowing,
    this.onFollow,
    this.following = false,
  });

  final PostSeller seller;
  final bool? isFollowing;
  final VoidCallback? onFollow;
  final bool following;

  @override
  Widget build(BuildContext context) {
    final following = isFollowing == true;
    final theme = Theme.of(context);
    final buttonStyle = theme.elevatedButtonTheme.style ?? const ButtonStyle();
    final shape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(child: SellerMessageButton(seller: seller)),
        const SizedBox(width: 12),
        Expanded(
          child: Theme(
            data: theme.copyWith(
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: buttonStyle.copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.primary,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.onPrimary,
                  ),
                  shape: shape,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
                    .copyWith(shape: shape),
              ),
            ),
            child: AppButton(
              label: following
                  ? ProfileScreenStrings.unfollow
                  : ProfileScreenStrings.follow,
              height: 44,
              isLoading: this.following,
              variant: following
                  ? AppButtonVariant.outlined
                  : AppButtonVariant.primary,
              onPressed:
                  onFollow ??
                  () => AppToast.show(
                    context,
                    message: ProfilePostStrings.followUnavailable,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
