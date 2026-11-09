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
  Widget _imageError(BuildContext context, Object error, StackTrace? stack) =>
      const Center(child: AppIcon(AppIcons.imageUnavailable, size: 36));
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
              if (media.source == PostMediaSource.asset)
                Image.asset(
                  preview,
                  fit: fit,
                  excludeFromSemantics: true,
                  errorBuilder: _imageError,
                )
              else
                Image.file(
                  File(preview),
                  fit: fit,
                  excludeFromSemantics: true,
                  errorBuilder: _imageError,
                )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AppIcon(
                          media.type == PostMediaType.video
                              ? AppIcons.video
                              : AppIcons.document,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          media.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
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
                  child: const AppIcon(AppIcons.video, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
