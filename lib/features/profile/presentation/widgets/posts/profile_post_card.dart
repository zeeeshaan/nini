import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/features/post_analytics/presentation/widgets/metrics/post_activity_tracking.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/features/posts/presentation/widgets/media/post_media_view.dart';

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

  // Reference width used only by grids that still pass a contentScale.
  static const referenceWidth = 200.0;

  /// Phone columns are narrower than [referenceWidth]. Keep type at the
  /// designed size there, and only grow it when the card is wider.
  static double textScaleFor(double contentScale) =>
      contentScale < 1 ? 1 : contentScale;

  static double lineHeightFor(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: AppTextStyles.profileCardText.merge(style),
      ),
      textDirection: TextDirection.rtl,
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height.ceilToDouble();
    painter.dispose();
    return height;
  }

  static double detailsHeightFor(BuildContext context, double scale) {
    final textScale = textScaleFor(scale);
    double lineHeight(TextStyle style) => lineHeightFor(
      context,
      style.copyWith(fontSize: style.fontSize! * textScale),
    );
    // Fixed slots so 1-line and 2-line titles keep the same card geometry.
    return (10 * textScale + // top + bottom padding
            lineHeight(AppTextStyles.postCardHeading) * 2 +
            2 * textScale +
            lineHeight(AppTextStyles.profileCardMetadata) +
            2 * textScale +
            lineHeight(AppTextStyles.profileCardStock) +
            8 * textScale +
            lineHeight(AppTextStyles.profileCardOriginalPrice) +
            2 * textScale +
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

  int? get _resolvedStock {
    final counted = post.stockCount;
    if (counted != null) return counted;
    final raw = post.details.warehouseStock.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(
      AppStrings.latinDigits(raw).replaceAll(RegExp(r'[^\d-]'), ''),
    );
  }

  String get _stockLabel {
    final count = _resolvedStock;
    if (count != null && count > 0) {
      return ProfileScreenStrings.inStock(count);
    }
    if (count == 0 || post.isExplicitlyOutOfStock) {
      return ProfileScreenStrings.stockUnavailable;
    }
    return ProfileScreenStrings.stockAvailable;
  }

  /// Figma always shows a unit beside price. Prefer the post unit; products
  /// fall back to piece so the slot is never empty.
  String? get _unitLabel {
    final unit = post.details.unit;
    if (unit != null) return PostDetailStrings.unit(unit);
    final raw = post.metadata['unit'];
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = PostUnit.fromName(raw);
      if (parsed != null) return PostDetailStrings.unit(parsed);
      return raw.trim();
    }
    if (!post.isService) return PostDetailStrings.unit(PostUnit.piece);
    return null;
  }

  String? get _ratingLabel {
    final value = post.metadata['rating'] ?? post.metadata['averageRating'];
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
    final unit = _unitLabel;
    final rating = _ratingLabel;
    // Figma keeps a rating digit beside the star even when the API has none.
    final ratingText = rating ?? '۰';
    final textScale = textScaleFor(contentScale);
    TextStyle scaled(TextStyle style) =>
        style.copyWith(fontSize: style.fontSize! * textScale);
    final headingStyle = scaled(AppTextStyles.postCardHeading);
    final metadataStyle = scaled(AppTextStyles.profileCardMetadata);
    final stockStyle = scaled(AppTextStyles.profileCardStock);
    final originalPriceStyle = scaled(AppTextStyles.profileCardOriginalPrice);
    final priceStyle = scaled(AppTextStyles.profileCardPrice);
    final unitStyle = scaled(AppTextStyles.profileCardUnit);
    final ratingStyle = scaled(AppTextStyles.profileCardRating);
    double lineHeight(TextStyle style) => lineHeightFor(context, style);

    final titleHeight = lineHeight(headingStyle) * 2;
    final metadataHeight = lineHeight(metadataStyle);
    final stockHeight = lineHeight(stockStyle);
    final originalPriceHeight = lineHeight(originalPriceStyle);
    final priceHeight = lineHeight(priceStyle);

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
                  child: imageOverride ??
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
                ),
                SizedBox(
                  height: detailsHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      6 * textScale,
                      4 * textScale,
                      6 * textScale,
                      6 * textScale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: titleHeight,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              titleOverride ?? post.title,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: headingStyle,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                        SizedBox(height: 2 * textScale),
                        SizedBox(
                          height: metadataHeight,
                          child: Text(
                            categoryLabel ??
                                ProfileScreenStrings.postCategory(
                                  post.category,
                                ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metadataStyle.copyWith(
                              color: colors.onSurface.withValues(alpha: .45),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        SizedBox(height: 2 * textScale),
                        SizedBox(
                          height: stockHeight,
                          child: statusLabel ??
                              (showStock && !post.isService
                                  ? Text(
                                      _stockLabel,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: stockStyle.copyWith(
                                        color: AppColors.red,
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: originalPriceHeight,
                          child:
                              discount != null && post.originalPrice.isNotEmpty
                              ? Text(
                                  _price(post.originalPrice),
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                  style: originalPriceStyle.copyWith(
                                    color: colors.onSurface.withValues(
                                      alpha: .45,
                                    ),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: colors.onSurface
                                        .withValues(alpha: .45),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 2 * textScale),
                        SizedBox(
                          height: priceHeight,
                          child: post.price.isEmpty
                              ? const SizedBox.shrink()
                              : Row(
                                  textDirection: TextDirection.ltr,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        textDirection: TextDirection.ltr,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _price(post.price),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.left,
                                              style: priceStyle,
                                            ),
                                          ),
                                          if (unit != null) ...[
                                            SizedBox(width: 4 * textScale),
                                            Text(
                                              unit,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: unitStyle.copyWith(
                                                color: colors.onSurface
                                                    .withValues(alpha: .55),
                                              ),
                                              textAlign: TextAlign.left,
                                              textDirection: TextDirection.ltr,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4 * textScale),
                                    Semantics(
                                      label: rating == null
                                          ? ProfileScreenStrings.postUnrated
                                          : ProfileScreenStrings.postRating(
                                              rating,
                                            ),
                                      excludeSemantics: true,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        textDirection: TextDirection.ltr,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          AppIcon(
                                            AppIcons.starFilled,
                                            size: 14 * textScale,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 2 * textScale,
                                            ),
                                            child: Text(
                                              rating == null
                                                  ? ratingText
                                                  : AppStrings.persianDigits(
                                                      rating,
                                                    ),
                                              style: ratingStyle,
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.right,
                                            ),
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
