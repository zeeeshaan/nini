import 'dart:io';

import 'package:nini/core/media/media_compressor.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import 'prepared_gallery_file.dart';

/// Gallery selections keep their identity/preview while carrying optimized data.
class GalleryMediaPreparer {
  GalleryMediaPreparer({MediaCompressor? compressor})
    : _compressor = compressor ?? MediaCompressor();
  final MediaCompressor _compressor;

  Future<List<GalleryAttachment>> prepare(
    List<GalleryAttachment> selected,
  ) async {
    if (selected.every((item) => item.preparedFile != null)) return selected;
    final folder = await Directory.systemTemp.createTemp('hywork_upload_');
    final result = <GalleryAttachment>[];
    try {
      for (final (index, attachment) in selected.indexed) {
        if (attachment.preparedFile != null) {
          result.add(attachment);
          continue;
        }
        final asset = attachment.asset;
        final picked = attachment.file;
        File? source;
        if (asset != null) {
          try {
            source = await asset.file;
            if (source != null && !await source.exists()) source = null;
          } catch (_) {
            // iCloud images can still expose originBytes below.
          }
        }
        final name = asset?.title ?? picked?.name ?? 'photo.jpg';
        var extension = p.extension(source?.path ?? name).toLowerCase();
        extension = extension.replaceAll(RegExp(r'[^.a-z0-9]'), '');
        if (extension.isEmpty && asset?.type == AssetType.image) {
          extension = '.jpg';
        }
        final target = File(p.join(folder.path, '$index$extension'));
        if (source != null) {
          await source.copy(target.path);
        } else if (asset?.type == AssetType.image) {
          final bytes = await asset!.originBytes;
          if (bytes == null) {
            throw const FileSystemException('Image unavailable');
          }
          await target.writeAsBytes(bytes, flush: true);
        } else if (picked != null) {
          final sink = target.openWrite();
          try {
            await sink.addStream(picked.readAsByteStream());
            await sink.flush();
          } finally {
            await sink.close();
          }
        } else {
          throw const FileSystemException('Attachment unavailable');
        }
        final compressed = await _compressor.compressOwnedFile(
          target,
          kind: asset?.type == AssetType.image
              ? MediaCompressionKind.image
              : asset?.type == AssetType.video
              ? MediaCompressionKind.video
              : null,
        );
        result.add(
          attachment.withPreparedFile(
            PreparedGalleryFile(
              compressed,
              name: p.extension(compressed.path) == extension
                  ? name
                  : p.setExtension(name, p.extension(compressed.path)),
              sizeBytes: await compressed.length(),
            ),
          ),
        );
      }
      return List.unmodifiable(result);
    } catch (_) {
      await folder.delete(recursive: true);
      rethrow;
    }
  }
}
