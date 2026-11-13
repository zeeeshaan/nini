import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class WalletHeader extends StatelessWidget implements PreferredSizeWidget {
  const WalletHeader({super.key, required this.title});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    titleSpacing: 16,
    title: Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: AppTextStyles.dialogTitle,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
    ),

    actions: [
      IconButton(
        tooltip: AppStrings.back,
        onPressed: () => Navigator.of(context).pop(),
        icon: const AppIcon(AppIcons.backRight, size: 20),
      ),
    ],
  );
}
