import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/profile/presentation/cubit/seller_profile_cubit.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

import '../seller_message_button/seller_message_button.dart';

class SellerProfileActions extends StatelessWidget {
  const SellerProfileActions({super.key, required this.seller});

  final PostSeller seller;

  @override
  Widget build(BuildContext context) => BlocBuilder<SellerProfileCubit, bool>(
    builder: (context, following) {
      final theme = Theme.of(context);
      final buttonStyle =
          theme.elevatedButtonTheme.style ?? const ButtonStyle();
      return Row(
        children: [
          Expanded(
            child: Theme(
              data: theme.copyWith(
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: buttonStyle.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(
                      AppColors.profileFollow,
                    ),
                    foregroundColor: const WidgetStatePropertyAll(
                      AppColors.white,
                    ),
                  ),
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
          const SizedBox(width: 8),
          Expanded(child: SellerMessageButton(seller: seller)),
        ],
      );
    },
  );
}
