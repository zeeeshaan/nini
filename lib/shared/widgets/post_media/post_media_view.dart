import 'dart:io';

import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostMediaView extends StatelessWidget {
  const PostMediaView({
    super.key,
    required this.media,
    this.fit = BoxFit.cover,
  });
  final PostMedia media;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final preview = media.type == PostMediaType.image
        ? media.path
        : media.thumbnailPath;
    return Semantics(
      label: media.altText.isEmpty ? media.name : media.altText,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (preview != null)
              Image.file(
                File(preview),
                fit: fit,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const Center(
                  child: AppIcon(AppIcons.imageUnavailable, size: 36),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        media.type == PostMediaType.video
                            ? Icons.videocam_outlined
                            : Icons.description_outlined,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          media.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (media.type == PostMediaType.video && preview != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.videocam_outlined, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
