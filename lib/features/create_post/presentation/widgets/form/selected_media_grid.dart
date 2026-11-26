import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/presentation/widgets/gallery/gallery_preview.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class SelectedMediaGrid extends StatelessWidget {
  const SelectedMediaGrid({super.key, required this.attachments});

  final List<GalleryAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final itemCount = math.max(9, attachments.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index >= attachments.length) {
          return const _EmptyMediaTile();
        }

        return _MediaTile(
          key: ValueKey(attachments[index].id),
          attachment: attachments[index],
        );
      },
    );
  }
}

class _EmptyMediaTile extends StatelessWidget {
  const _EmptyMediaTile();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface,
      child: Center(
        child: Opacity(
          opacity: 0.12,
          child: const AppIcon(AppIcons.imageUnavailable, size: 38),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({super.key, required this.attachment});

  final GalleryAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = attachment.asset;

    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null)
            AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(360),
              fit: BoxFit.cover,
            )
          else if (attachment.remoteUrl != null)
            Image.network(
              attachment.remoteUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.white,
                child: Center(
                  child: AppIcon(AppIcons.imageUnavailable, size: 28),
                ),
              ),
            )
          else if (attachment.file != null)
            GalleryFileTile(file: attachment.file!),

          if (asset?.type == AssetType.video)
            Center(
              child: AppIcon(
                AppIcons.playCircle,
                color: AppColors.white,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}
