import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

import 'seller_message_button.dart';

class SellerProfileActions extends StatelessWidget {
  const SellerProfileActions({super.key, required this.seller});

  final PostSeller seller;

  @override
  Widget build(BuildContext context) => BlocBuilder<SellerProfileCubit, bool>(
    builder: (context, following) {
      final theme = Theme.of(context);
      final buttonStyle =
          theme.elevatedButtonTheme.style ?? const ButtonStyle();
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
                  style:
                      (theme.outlinedButtonTheme.style ?? const ButtonStyle())
                          .copyWith(shape: shape),
                ),
              ),
              child: AppButton(
                label: following ? AppStrings.following : AppStrings.follow,
                height: 44,
                variant: following
                    ? AppButtonVariant.outlined
                    : AppButtonVariant.primary,
                onPressed: context.read<SellerProfileCubit>().toggleFollow,
              ),
            ),
          ),
        ],
      );
    },
  );
}
