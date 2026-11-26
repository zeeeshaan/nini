import 'package:flutter/material.dart';

import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/widgets/app_images/profile_image_provider.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.size, this.asset = ''});

  final double size;

  final String asset;

  @override
  Widget build(BuildContext context) {
    final image = profileImageProvider(asset);
    final placeholder = Center(
      child: AppIcon(
        AppIcons.profile,
        size: size * .5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: image == null
              ? placeholder
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  semanticLabel: ProfileScreenStrings.profileImage,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
