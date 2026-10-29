import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';

class GalleryPreview extends StatelessWidget {
  const GalleryPreview({super.key, required this.selected});

  final List<GalleryAttachment> selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (selected.isEmpty) {
      return ColoredBox(
        color: colors.surface,
        child: Center(
          child: AppIcon(
            AppIcons.image,
            size: 180,
            color: colors.onSurface.withValues(alpha: 0.11),
          ),
        ),
      );
    }

    // Show one photo or video in the large preview.
    if (selected.length == 1 && selected.first.asset != null) {
      final asset = selected.first.asset!;

      return ColoredBox(
        color: colors.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize(1000, 1000),
              fit: BoxFit.contain,
            ),
            if (asset.type == AssetType.video)
              Center(
                child: AppIcon(
                  AppIcons.playCircle,
                  size: 56,
                  color: colors.onSurface,
                ),
              ),
          ],
        ),
      );
    }

    // Multiple selected items become a preview grid.
    return _SelectedMediaGrid(selected: selected);
  }
}

class _SelectedMediaGrid extends StatelessWidget {
  const _SelectedMediaGrid({required this.selected});

  final List<GalleryAttachment> selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Figma shows 3 rows of 3 tiles by default.
    final itemCount = selected.length < 9 ? 9 : selected.length;

    return ColoredBox(
      color: colors.surface,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          if (index >= selected.length) {
            return const _EmptyMediaTile();
          }

          final attachment = selected[index];

          return _SelectedMediaTile(
            key: ValueKey(attachment.id),
            attachment: attachment,
          );
        },
      ),
    );
  }
}

class _EmptyMediaTile extends StatelessWidget {
  const _EmptyMediaTile();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Center(
        child: AppIcon(
          AppIcons.image,
          size: 38,
          color: colors.onSurface.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}

class _SelectedMediaTile extends StatelessWidget {
  const _SelectedMediaTile({super.key, required this.attachment});

  final GalleryAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = attachment.asset;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: () {
          context.read<GalleryCubit>().removeAttachment(attachment);
        },
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
            else
              GalleryFileTile(file: attachment.file!),

            if (asset?.type == AssetType.video)
              Center(
                child: AppIcon(
                  AppIcons.playCircle,
                  size: 30,
                  color: colors.surface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable file tile for both the selected-preview
/// grid and the File tab's attachment list.
class GalleryFileTile extends StatelessWidget {
  const GalleryFileTile({super.key, required this.file, this.showName = false});

  final PlatformFile file;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final parts = file.name.split('.');
    final extension = parts.length > 1
        ? parts.last.toUpperCase()
        : AppStrings.genericFile;

    final Color badgeColor;

    switch (extension) {
      case 'PDF':
        badgeColor = const Color(0xFFEE5969);
      case 'MKV':
      case 'MP4':
      case 'MOV':
        badgeColor = const Color(0xFFA64CE6);
      default:
        badgeColor = colors.onSurface;
    }

    return ColoredBox(
      color: colors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 54,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              AppStrings.fileTypeLabel(extension),
              style: TextStyle(
                color:
                    extension == 'PDF' ||
                        extension == 'MKV' ||
                        extension == 'MP4' ||
                        extension == 'MOV'
                    ? Colors.white
                    : colors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurface, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
