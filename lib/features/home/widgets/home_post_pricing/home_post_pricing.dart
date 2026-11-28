import 'package:flutter/material.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/shared/models/post/post_item.dart';

import 'package:hywork/features/home/widgets/home_badge/home_badge.dart';

class HomePostPricing extends StatelessWidget {
  const HomePostPricing({super.key, required this.post});

  final PostItem post;

  String _amount(String value) {
    final normalized = AppStrings.latinDigits(value)
        .trim()
        .replaceAll(RegExp(r'[,٬\s]'), '')
        .replaceAll('٫', '.');

    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) {
      return value;
    }

    final parts = normalized.split('.');

    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    return AppStrings.persianDigits(parts.join('.'));
  }

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    final price = post.price.trim();
    final original = post.originalPrice.trim();

    // Prefer the existing typed unit.
    // Fall back to the actual backend unit if necessary.
    final unit = post.details.unit;
    final rawUnit = post.metadata['unit'];

    final unitLabel = unit != null
        ? PostDetailStrings.unit(unit)
        : rawUnit is String && rawUnit.trim().isNotEmpty
        ? rawUnit.trim()
        : null;

    final currencyStyle = AppTextStyles.labelBold.copyWith(
      fontSize: 8,
      height: 1,
      color: foreground,
    );

    final currencyInset =
        MediaQuery.textScalerOf(context).scale(currencyStyle.fontSize!) + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final prices = Column(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (original.isNotEmpty && _amount(original) != _amount(price))
              Padding(
                padding: EdgeInsets.only(left: currencyInset),
                child: Text(
                  _amount(original),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: AppTextStyles.homeOriginalPrice.copyWith(
                    height: 1,
                    color: foreground.withValues(alpha: .3),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: foreground.withValues(alpha: .3),
                  ),
                ),
              ),

            if (price.isNotEmpty)
              Wrap(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          HomeStrings.toman,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: currencyStyle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _amount(price),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.homePostPrice.copyWith(
                            height: 1,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Display the selected product unit.
                  if (unitLabel != null)
                    Text(
                      unitLabel,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: foreground,
                      ),
                    ),
                ],
              ),
          ],
        );

        // Feed PostCard may omit stock quantity; use inStock without inventing a count.
        final count = post.stockCount;
        final String? stockLabel = post.isService
            ? null
            : count != null && count > 0
            ? HomeStrings.inStock(count)
            : post.isExplicitlyOutOfStock
            ? HomeStrings.stockUnavailable
            : post.isConfirmedAvailable
            ? HomeStrings.stockAvailable
            : null;
        final stock = stockLabel == null
            ? null
            : HomeBadge(
                label: stockLabel,
                background: AppColors.stockBadgeBackground,
                foreground: AppColors.notificationBadge,
              );

        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(16) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (price.isNotEmpty || original.isNotEmpty) prices,
              if (stock != null) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: stock),
              ],
            ],
          );
        }

        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: prices),
            if (stock != null) ...[
              const SizedBox(width: 12),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: stock),
            ],
          ],
        );
      },
    );
  }
}
