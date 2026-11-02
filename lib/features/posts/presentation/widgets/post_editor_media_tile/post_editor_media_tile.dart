import 'package:flutter/material.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:nini/shared/widgets/post_media/post_media_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// A single retained or newly selected attachment with its remove control.
class PostEditorMediaTile extends StatelessWidget {
  const PostEditorMediaTile.existing({
    super.key,
    required PostMedia this.media,
    required this.onRemove,
  }) : attachment = null;
  const PostEditorMediaTile.picked({
    super.key,
    required GalleryAttachment this.attachment,
    required this.onRemove,
  }) : media = null;
  final PostMedia? media;
  final GalleryAttachment? attachment;
  final VoidCallback onRemove;
  Widget _preview() {
    if (media != null) return PostMediaView(media: media!);
    final asset = attachment!.asset;
    if (asset == null) return GalleryFileTile(file: attachment!.file!);
    return Stack(
      fit: StackFit.expand,
      children: [
        AssetEntityImage(
          asset,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize.square(360),
          fit: BoxFit.cover,
        ),
        if (asset.type == AssetType.video)
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: AppColors.white,
              size: 32,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Stack(
      fit: StackFit.expand,
      children: [
        _preview(),
        Positioned(
          top: 2,
          left: 2,
          child: IconButton.filled(
            tooltip: ProfilePostStrings.removeMedia,
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppColors.red,
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(6),
            ),
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
      ],
    ),
  );
}
