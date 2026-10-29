import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/post_media/post_media_view.dart';

class AnalyticsPostHeader extends StatelessWidget {
  const AnalyticsPostHeader({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) {
    final location = post.isPublished
        ? (post.details.address?.address ?? '')
        : AppStrings.authorLocation;
    return Column(
      children: [
        Row(
          children: [
            Text(
              post.isPublished
                  ? AppStrings.onThisDevice
                  : AppStrings.sampleData,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .5),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    post.isPublished
                        ? AppStrings.sellerName
                        : AppStrings.authorName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: .38),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00C83C), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset('assets/Mask group.png', fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SizedBox.square(
              dimension: constraints.maxWidth * .56,
              child: post.media.isNotEmpty
                  ? PostMediaView(media: post.media.first)
                  : Image.asset(
                      post.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Center(
                        child: AppIcon(AppIcons.imageUnavailable),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
