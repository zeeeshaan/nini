import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';

import 'package:nini/features/home/presentation/widgets/home_badge/home_badge.dart';

class HomeProductImage extends StatefulWidget {
  const HomeProductImage({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  State<HomeProductImage> createState() => _HomeProductImageState();
}

class _HomeProductImageState extends State<HomeProductImage> {
  int _attempt = 0;

  Future<void> _retry() async {
    await NetworkImage(
      widget.imageUrl,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    ).evict();
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(52, 32, 52, 20),
                child: Image.network(
                  widget.imageUrl,
                  key: ValueKey(_attempt),
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  semanticLabel: widget.title,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: AppLoader(color: AppColors.black),
                    );
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
                            onPressed: _retry,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.black,
                            ),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const Positioned(
              left: 10,
              top: 8,
              child: HomeBadge(
                label: AppStrings.preOrder,
                background: AppColors.black,
                foreground: AppColors.white,
              ),
            ),
            const Positioned(
              right: 14,
              top: 8,
              child: HomeBadge(
                label: '۳٪',
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
