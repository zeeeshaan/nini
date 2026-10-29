import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostAuthorHeader extends StatelessWidget {
  const PostAuthorHeader({
    super.key,
    this.name = AppStrings.authorName,
    this.location = AppStrings.authorLocation,
    this.avatarAsset = 'assets/images/profile_avatar.png',
    this.onMorePressed,
  });

  final String name;
  final String location;
  final String avatarAsset;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 12),
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
                border: Border.all(color: const Color(0xFF00CB28), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  semanticLabel: AppStrings.authorImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const AppIcon(AppIcons.profile, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
