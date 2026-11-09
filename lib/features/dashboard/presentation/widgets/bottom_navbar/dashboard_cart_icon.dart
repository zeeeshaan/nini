import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/cubit/cart_state.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

// dart format width=100

class DashboardCartIcon extends StatelessWidget {
  const DashboardCartIcon({super.key, required this.selected, this.count});

  final bool selected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartCubit?>();

    if (count != null || cart == null) {
      return _buildIcon(count ?? 0);
    }

    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.items.length,
      builder: (context, itemCount) {
        return _buildIcon(itemCount);
      },
    );
  }

  Widget _buildIcon(int itemCount) {
    final badgeCount = itemCount > 99 ? '99+' : '$itemCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const AppIcon(AppIcons.cart, size: 32),
        if (itemCount > 0)
          Positioned(
            top: -5,
            right: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.cartBadge,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                selected
                    ? badgeCount
                    : AppStrings.persianDigits(
                        itemCount > 99 ? '99+' : itemCount,
                      ),
                style: AppTextStyles.notificationBadge.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
