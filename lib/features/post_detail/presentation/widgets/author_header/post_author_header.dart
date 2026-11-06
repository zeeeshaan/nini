import 'package:nini/features/posts/presentation/widgets/seller_avatar/seller_avatar.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostAuthorHeader extends StatelessWidget {
  const PostAuthorHeader({
    super.key,
    this.name = AppStrings.authorName,
    this.location = AppStrings.authorLocation,
    this.avatarAsset = 'assets/images/profile_avatar.png',
    this.onMorePressed,
    this.onProfilePressed,
  });

  final String name;
  final String location;
  final String avatarAsset;
  final VoidCallback? onMorePressed, onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (onMorePressed != null)
              IconButton(
                onPressed: onMorePressed,
                tooltip: AppStrings.morePostOptions,
                icon: const AppIcon(AppIcons.more, size: 24),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.authorName,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 43,
              height: 43,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.authorOnline, width: 2),
              ),
              child: SellerAvatar(
                asset: avatarAsset,
                name: name,
                onPressed: onProfilePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
