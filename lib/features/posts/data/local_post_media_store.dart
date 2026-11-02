import 'dart:io';
import 'dart:math';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

/// Copies gallery/cache files into private storage before the post index is
/// committed. A failed save can discard only its newly copied media folder.
class StoredPostMedia {
  const StoredPostMedia(this.folder, this.items);
  final Directory folder;
  final List<PostMedia> items;
  Future<void> discard() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  }
}

class LocalPostMediaStore {
  Future<StoredPostMedia> copy(
    Directory root,
    List<GalleryAttachment> attachments,
    Map<String, String> altTexts,
  ) async {
    final id =
        'media_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    var folder = Directory(p.join(root.path, '.pending-$id'));
    final finalFolder = Directory(p.join(root.path, id));
    try {
      await folder.create();
      final media = <PostMedia>[];
      for (final (index, attachment) in attachments.indexed) {
        final asset = attachment.asset;
        final pickedFile = attachment.file;
        File? source;
        List<int>? originalBytes;
        if (asset != null) {
          try {
            source = await asset.file;
            if (source != null && !await source.exists()) source = null;
          } catch (_) {
            // Some iOS library assets can export original bytes even when
            // photo_manager cannot provide a readable temporary file path.
          }
          if (source == null && asset.type == AssetType.image) {
            originalBytes = await asset.originBytes;
          }
        }
        if (asset != null && source == null && originalBytes == null) {
          throw const PostPublishException(AppStrings.mediaUnavailable);
        }
        final name =
            asset?.title ??
            (source == null
                ? pickedFile?.name ?? 'photo.jpg'
                : p.basename(source.path));
        final extension = p
            .extension(source?.path ?? name)
            .toLowerCase()
            .replaceAll(RegExp(r'[^.a-z0-9]'), '');
        final fileName = '$index${extension.length <= 12 ? extension : ''}';
        final target = File(p.join(folder.path, fileName));
        if (source != null) {
          await source.copy(target.path);
        } else if (originalBytes != null) {
          await target.writeAsBytes(originalBytes, flush: true);
        } else {
          final sink = target.openWrite();
          try {
            await sink.addStream(pickedFile!.readAsByteStream());
            await sink.flush();
          } finally {
            await sink.close();
          }
        }
        final type =
            asset?.type == AssetType.video ||
                const [
                  '.mp4',
                  '.mov',
                  '.mkv',
                  '.webm',
                  '.avi',
                ].contains(extension)
            ? PostMediaType.video
            : asset?.type == AssetType.image ||
                  const [
                    '.jpg',
                    '.jpeg',
                    '.png',
                    '.webp',
                    '.gif',
                    '.bmp',
                    '.heic',
                    '.heif',
                    '.avif',
                  ].contains(extension)
            ? PostMediaType.image
            : PostMediaType.document;
        String? thumbnailName;
        if (asset != null && type == PostMediaType.video) {
          try {
            final thumbnail = await asset.thumbnailDataWithSize(
              const ThumbnailSize.square(600),
            );
            if (thumbnail != null) {
              thumbnailName = '$index-thumbnail.jpg';
              await File(p.join(folder.path, thumbnailName))
                  .writeAsBytes(thumbnail, flush: true);
            }
          } catch (_) {
            /* The original video is retained even without a thumbnail. */
          }
        }
        media.add(
          PostMedia(
            path: p.join(finalFolder.path, fileName),
            name: name,
            type: type,
            thumbnailPath: thumbnailName == null
                ? null
                : p.join(finalFolder.path, thumbnailName),
            altText: altTexts[attachment.id] ?? '',
          ),
        );
      }
      folder = await folder.rename(finalFolder.path);
      return StoredPostMedia(folder, List.unmodifiable(media));
    } catch (_) {
      if (await folder.exists()) await folder.delete(recursive: true);
      rethrow;
    }
  }

  /// Called only after the replacement index is safely committed.
  Future<void> removeUnused(
    Directory root,
    List<PostMedia> previous,
    Iterable<PostMedia> retained,
  ) async {
    final usedFiles = {
      for (final item in retained) ...[
        item.path,
        if (item.thumbnailPath != null) item.thumbnailPath!,
      ],
    };
    final candidates = {
      for (final item in previous.where(
        (item) => item.source == PostMediaSource.local,
      )) ...[item.path, if (item.thumbnailPath != null) item.thumbnailPath!],
    };
    for (final path in candidates.difference(usedFiles)) {
      final folder = p.dirname(path);
      // Only files in repository-owned direct child folders may be removed.
      if (!p.isWithin(root.path, path) || p.dirname(folder) != root.path) {
        continue;
      }
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
        final directory = Directory(folder);
        if (await directory.exists() && await directory.list().isEmpty) {
          await directory.delete();
        }
      } catch (_) {
        // Cleanup failure must never turn a committed change into a failed save.
      }
    }
  }
}
