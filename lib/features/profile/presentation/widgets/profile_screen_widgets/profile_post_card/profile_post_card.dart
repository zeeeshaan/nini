import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/presentation/widgets/activity_tracking/post_activity_tracking.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/posts/presentation/widgets/post_media_view/post_media_view.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.detailsHeight,
  });

  final PostItem post;
  final VoidCallback onTap;
  final double detailsHeight;

  double? _number(String value) => double.tryParse(
    AppStrings.persianDigits(value).replaceAll(RegExp(r'[,\s%]'), ''),
  );

  String _price(String value) => AppStrings.persianDigits(value)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );

  String? get _discountLabel {
    final saved = _number(post.details.discount);
    final original = _number(post.originalPrice);
    final current = _number(post.price);
    final percent = saved != null && saved > 0
        ? saved
        : original != null &&
              original > 0 &&
              current != null &&
              current < original
        ? (original - current) / original * 100
        : 0.0;
    if (!percent.isFinite || percent <= 0 || percent > 100) return null;
    final value = percent.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '$value%';
  }

  String? get _ratingLabel {
    final value = post.metadata['rating'];
    if (value == null) return null;
    final rating = _number(value.toString());
    if (rating == null || !rating.isFinite || rating < 0 || rating > 5) {
      return null;
    }
    return rating.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .65);
    final discount = _discountLabel;
    final unit = post.details.unit?.label;
    final rating = _ratingLabel;
    final textScaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle style) =>
        textScaler.scale(style.fontSize!) * (style.height ?? 1.2);
    return PostImpressionTracker(
      post: post,
      source: 'profile',
      child: Material(
        color: colors.surface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    post.media.isNotEmpty
                        ? PostMediaView(media: post.media.first)
                        : Image.asset(
                            post.imageAsset,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                  child: const Center(
                                    child: AppIcon(AppIcons.imageUnavailable),
                                  ),
                                ),
                          ),
                    if (discount != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Text(
                              discount,
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.discountBadge.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: detailsHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: lineHeight(AppTextStyles.postCardHeading) * 2,
                        child: Text(
                          post.title,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.postCardHeading,
                        ),
                      ),
                      Text(
                        AppStrings.postCategory(post.category),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.postMetadata.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Visibility(
                        visible:
                            !post.isPublished ||
                            post.details.warehouseStock.isNotEmpty,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: Text(
                          AppStrings.inStock(post.stockCount),
                          textDirection: Directionality.of(context),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.postStock.copyWith(
                            color: AppColors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: lineHeight(AppTextStyles.originalPrice),
                        child: discount != null && post.originalPrice.isNotEmpty
                            ? Text(
                                _price(post.originalPrice),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: AppTextStyles.originalPrice.copyWith(
                                  color: muted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: muted,
                                ),
                              )
                            : null,
                      ),
                      if (post.price.isNotEmpty)
                        Row(
                          textDirection: TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                textDirection: TextDirection.ltr,
                                spacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    _price(post.price),
                                    textDirection: TextDirection.ltr,
                                    style: AppTextStyles.postPrice,
                                  ),
                                  if (unit != null)
                                    Text(
                                      unit,
                                      style: AppTextStyles.pricePrefix,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: lineHeight(AppTextStyles.postPrice),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Semantics(
                                  label: rating == null
                                      ? AppStrings.postUnrated
                                      : AppStrings.postRating(rating),
                                  excludeSemantics: true,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const AppIcon(
                                        AppIcons.starFilled,
                                        size: 16,
                                      ),
                                      if (rating != null)
                                        Text(
                                          AppStrings.persianDigits(rating),
                                          style: AppTextStyles.smallPrint,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
