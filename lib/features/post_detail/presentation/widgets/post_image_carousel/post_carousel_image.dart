import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostCarouselImage extends StatelessWidget {
  const PostCarouselImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ImageProvider image =
        path.startsWith('https://') || path.startsWith('http://')
        ? NetworkImage(
            path,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          )
        : AssetImage(path);
    return Image(
      image: image,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: AppIcon(AppIcons.imageUnavailable, size: 40),
        ),
      ),
    );
  }
}
