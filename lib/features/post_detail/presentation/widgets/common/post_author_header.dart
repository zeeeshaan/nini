import 'package:hywork/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class PostAuthorHeader extends StatelessWidget {
  const PostAuthorHeader({
    super.key,
    this.name = PostDetailStrings.authorName,
    this.location = PostDetailStrings.authorLocation,
    this.avatarAsset = '',
    this.onMorePressed,
    this.onProfilePressed,
    this.onMessagePressed,
  });

  final String name;
  final String location;
  final String avatarAsset;
  final VoidCallback? onMorePressed, onProfilePressed;
  final VoidCallback? onMessagePressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (onMessagePressed != null)
              IconButton(
                onPressed: onMessagePressed,
                tooltip: PostDetailStrings.message,
                icon: const AppIcon(AppIcons.chat, size: 22),
              ),
            if (onMorePressed != null)
              IconButton(
                onPressed: onMorePressed,
                tooltip: PostDetailStrings.morePostOptions,
                icon: const AppIcon(AppIcons.more, size: 24),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Semantics(
                    button: onProfilePressed != null,
                    label: onProfilePressed == null
                        ? null
                        : PostDetailStrings.viewSellerProfile(name),
                    child: InkWell(
                      onTap: onProfilePressed,
                      child: Text(
                        name,
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.authorName,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.right,
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
