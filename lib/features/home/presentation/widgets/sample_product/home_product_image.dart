import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_loader/app_loader.dart';

import 'package:hywork/features/home/presentation/widgets/common/home_badge.dart';

class HomeProductImage extends StatelessWidget {
  const HomeProductImage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.attempt,
    required this.onRetry,
  });

  final String imageUrl;
  final String title;

  final int attempt;
  final VoidCallback onRetry;

  Future<void> _retry(BuildContext context) async {
    await NetworkImage(
      imageUrl,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    ).evict();
    if (context.mounted) onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                key: ValueKey(attempt),
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                semanticLabel: title,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: AppLoader(color: AppColors.black));
                },
                errorBuilder: (context, error, stack) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(
                          AppIcons.imageUnavailable,
                          color: AppColors.black,
                          size: 32,
                        ),
                        TextButton(
                          onPressed: () => _retry(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.black,
                          ),
                          child: const Text(
                            HomeStrings.retry,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              left: 10,
              top: 8,
              child: HomeBadge(
                label: HomeStrings.preOrder,
                background: AppColors.black,
                foreground: AppColors.white,
              ),
            ),
            const Positioned(
              right: 14,
              top: 8,
              child: HomeBadge(
                label: '3%',
                background: AppColors.notificationBadge,
                foreground: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
