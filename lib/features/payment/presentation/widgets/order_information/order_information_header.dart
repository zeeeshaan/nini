import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/localization/strings/order_information_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class OrderInformationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const OrderInformationHeader({
    super.key,
    required this.amount,
    required this.onBack,
    required this.onCharges,
  });

  final String amount;
  final VoidCallback onBack, onCharges;
  @override
  Size get preferredSize => const Size.fromHeight(190);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.black,
    foregroundColor: AppColors.white,
    surfaceTintColor: AppColors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
    title: Align(
      alignment: Alignment.centerRight,
      child: const Text(
        OrderInformationStrings.title,
        style: AppTextStyles.pageTitle,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      ),
    ),
    centerTitle: false,
    actions: [
      IconButton(
        tooltip: CartStrings.charges,
        onPressed: onCharges,
        icon: const AppIcon(AppIcons.more, size: 22, color: AppColors.white),
      ),

      IconButton(
        tooltip: AppStrings.back,
        onPressed: onBack,
        icon: const AppIcon(
          AppIcons.backRight,
          size: 20,
          color: AppColors.white,
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(134),
      child: SizedBox(
        height: 134,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: AppTextStyles.orderPayable.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                OrderInformationStrings.amountPayable,
                style: AppTextStyles.caption.copyWith(color: AppColors.white70),
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
