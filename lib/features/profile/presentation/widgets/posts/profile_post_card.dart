import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/post_analytics/presentation/widgets/metrics/post_activity_tracking.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.detailsHeight,
    this.contentScale = 1,
    this.titleOverride,
    this.categoryLabel,
    this.showStock = true,
    this.statusLabel,
    this.imageOverride,
    this.impressionSource = 'profile',
  });

  final PostItem post;
  final VoidCallback? onTap;
  final double detailsHeight;
  final double contentScale;
  final String? titleOverride, categoryLabel;
  final bool showStock;
  final Widget? statusLabel;
  final Widget? imageOverride;
  final String impressionSource;

  // A reference card is 200 units wide with a square image and ~100 of details.
  static const referenceWidth = 200.0;

  static double lineHeightFor(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: AppTextStyles.profileCardText.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    // Round the measured line up so font-metric fractions cannot overflow a row.
    final height = painter.height.ceilToDouble();
    painter.dispose();
    return height;
  }

  static double detailsHeightFor(BuildContext context, double scale) {
    double lineHeight(TextStyle style) => lineHeightFor(
      context,
      style.copyWith(fontSize: style.fontSize! * scale),
    );
    return (20 * scale +
            lineHeight(AppTextStyles.postCardHeading) * 2 +
            lineHeight(AppTextStyles.profileCardMetadata) +
            lineHeight(AppTextStyles.profileCardStock) +
            lineHeight(AppTextStyles.profileCardOriginalPrice) +
            lineHeight(AppTextStyles.profileCardPrice))
        .ceilToDouble();
  }

  double? _number(String value) => double.tryParse(
    AppStrings.latinDigits(value).replaceAll(RegExp(r'[,\s%]'), ''),
  );

  String _price(String value) => AppStrings.persianDigits(
    AppStrings.latinDigits(value).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    ),
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
    return AppStrings.persianDigits('$value%');
  }

  String get _stockLabel {
    final count = post.stockCount;
    if (count != null && count > 0) return AppStrings.inStock(count);
    if (post.isExplicitlyOutOfStock) return AppStrings.stockUnavailable;
    return AppStrings.stockAvailable;
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
    final discount = _discountLabel;
    final unit = post.details.unit?.label;
    final rating = _ratingLabel;
    TextStyle scaled(TextStyle style) =>
        style.copyWith(fontSize: style.fontSize! * contentScale);
    final headingStyle = scaled(AppTextStyles.postCardHeading);
    final metadataStyle = scaled(AppTextStyles.profileCardMetadata);
    final stockStyle = scaled(AppTextStyles.profileCardStock);
    final originalPriceStyle = scaled(AppTextStyles.profileCardOriginalPrice);
    final priceStyle = scaled(AppTextStyles.profileCardPrice);
    final unitStyle = scaled(AppTextStyles.profileCardUnit);
    final ratingStyle = scaled(AppTextStyles.profileCardRating);
    double lineHeight(TextStyle style) => lineHeightFor(context, style);
    return PostImpressionTracker(
      post: post,
      source: impressionSource,
      child: Material(
        color: colors.surface,
        child: DefaultTextStyle.merge(
          style: AppTextStyles.profileCardText,
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
                      imageOverride ??
                          (post.media.isNotEmpty
                              ? PostMediaView(
                                  media: post.media.first,
                                  preferThumbnail: true,
                                )
                              : Image.asset(
                                  post.imageAsset,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (context, error, stackTrace) =>
                                      ColoredBox(
                                        color: colors.surfaceContainerHighest,
                                        child: const Center(
                                          child: AppIcon(
                                            AppIcons.imageUnavailable,
                                          ),
                                        ),
                                      ),
                                )),
                      if (discount != null)
                        Positioned(
                          top: 3 * contentScale,
                          right: 3 * contentScale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(
                                10 * contentScale,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * contentScale,
                                vertical: 3 * contentScale,
                              ),
                              child: Text(
                                discount,
                                textDirection: TextDirection.ltr,
                                style: scaled(AppTextStyles.discountBadge)
                                    .copyWith(color: AppColors.white),
                                textAlign: TextAlign.right,
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
                    padding: EdgeInsets.fromLTRB(
                      4 * contentScale,
                      4 * contentScale,
                      6 * contentScale,
                      6 * contentScale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titleOverride ?? post.title,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: headingStyle,
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(
                          height: lineHeight(metadataStyle),
                          child: Text(
                            categoryLabel ??
                                AppStrings.postCategory(post.category),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metadataStyle.copyWith(
                              color: colors.onSurface.withValues(alpha: .4),
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        Visibility(
                          visible:
                              statusLabel != null ||
                              (showStock &&
                                  !post.isService &&
                                  (!post.isPublished ||
                                      post.details.warehouseStock.isNotEmpty ||
                                      post.isConfirmedAvailable ||
                                      post.isExplicitlyOutOfStock)),
                          maintainState: true,
                          maintainAnimation: true,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4 * contentScale),
                            child: SizedBox(
                              height: lineHeight(stockStyle),
                              child:
                                  statusLabel ??
                                  Text(
                                    _stockLabel,
                                    textDirection: Directionality.of(context),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: stockStyle.copyWith(
                                      color: AppColors.red,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6 * contentScale),
                        if (discount != null && post.originalPrice.isNotEmpty)
                          SizedBox(
                            height: lineHeight(originalPriceStyle),
                            child: Text(
                              _price(post.originalPrice),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: originalPriceStyle.copyWith(
                                color: colors.onSurface.withValues(alpha: .25),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: colors.onSurface.withValues(
                                  alpha: .25,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: lineHeight(priceStyle),
                          child: post.price.isEmpty
                              ? null
                              : Row(
                                  textDirection: TextDirection.ltr,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.bottomLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          textDirection: TextDirection.ltr,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              _price(post.price),
                                              textDirection: TextDirection.ltr,
                                              style: priceStyle,
                                              textAlign: TextAlign.left,
                                            ),
                                            if (unit != null) ...[
                                              SizedBox(width: 4 * contentScale),
                                              Text(
                                                unit,
                                                style: unitStyle,
                                                textAlign: TextAlign.right,
                                                textDirection:
                                                    TextDirection.ltr,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4 * contentScale),
                                    Semantics(
                                      label: rating == null
                                          ? AppStrings.postUnrated
                                          : AppStrings.postRating(rating),
                                      excludeSemantics: true,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        textDirection: TextDirection.ltr,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          AppIcon(
                                            AppIcons.starFilled,
                                            size: 10 * contentScale,
                                          ),
                                          if (rating != null)
                                            Text(
                                              AppStrings.persianDigits(rating),
                                              style: ratingStyle,
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.right,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
