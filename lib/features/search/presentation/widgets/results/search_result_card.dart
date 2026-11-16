import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.post,
    this.onTap,
    this.contentScale = 1,
    this.detailsHeight,
  });

  final PostItem post;
  final VoidCallback? onTap;
  final double contentScale;
  final double? detailsHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ProfilePostCard(
      post: post,
      onTap: onTap,
      contentScale: contentScale,
      detailsHeight:
          detailsHeight ??
          ProfilePostCard.detailsHeightFor(context, contentScale),
      titleOverride: post.title,
      categoryLabel: AppStrings.services,
      showStock: false,
      impressionSource: 'search',
      statusLabel: post.details.tags.contains(AppStrings.preOrder)
          ? Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5 * contentScale),
                decoration: BoxDecoration(
                  color: colors.onSurface,
                  borderRadius: BorderRadius.circular(10 * contentScale),
                ),
                child: Text(
                  AppStrings.preOrder,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.badgeSmall.copyWith(
                    fontSize: AppTextStyles.badgeSmall.fontSize! * contentScale,
                    color: colors.surface,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            )
          : null,
    );
  }
}
