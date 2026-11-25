import 'dart:io';

import 'package:flutter/material.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostMediaView extends StatelessWidget {
  const PostMediaView({
    super.key,
    required this.media,
    this.fit = BoxFit.cover,
    this.preferThumbnail = false,
  });
  final PostMedia media;
  final BoxFit fit;
  final bool preferThumbnail;

  bool _networkUrl(String? value) {
    if (value == null ||
        value.trim() != value ||
        !(value.startsWith('http://') || value.startsWith('https://'))) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Widget _imageError(BuildContext context, Object error, StackTrace? stack) =>
      const Center(child: AppIcon(AppIcons.imageUnavailable, size: 36));
  @override
  Widget build(BuildContext context) {
    final original = media.type == PostMediaType.image
        ? media.path
        : media.thumbnailPath;
    final useThumbnail =
        preferThumbnail &&
        media.type == PostMediaType.image &&
        media.source != PostMediaSource.asset &&
        _networkUrl(media.path) &&
        _networkUrl(media.thumbnailPath) &&
        media.thumbnailPath != media.path;
    final preview = useThumbnail ? media.thumbnailPath : original;
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
              else if (preview.startsWith('https://') ||
                  preview.startsWith('http://'))
                Image.network(
                  preview,
                  fit: fit,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) => useThumbnail
                      ? Image.network(
                          media.path,
                          fit: fit,
                          excludeFromSemantics: true,
                          errorBuilder: _imageError,
                        )
                      : _imageError(context, error, stack),
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
                          textDirection: TextDirection.ltr,
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
