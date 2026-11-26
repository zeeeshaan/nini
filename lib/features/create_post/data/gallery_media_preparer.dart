import 'dart:io';

import 'package:hywork/core/media/media_compressor/media_compressor.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import 'prepared_gallery_file.dart';

/// Gallery selections keep their identity/preview while carrying optimized data.
class GalleryMediaPreparer {
  GalleryMediaPreparer({MediaCompressor? compressor})
    : _compressor = compressor ?? MediaCompressor();
  final MediaCompressor _compressor;

  Future<List<GalleryAttachment>> prepare(
    List<GalleryAttachment> selected, {
    bool forPost = false,
  }) async {
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
        final originalFormat = forPost ? await _imageFormat(target) : null;
        final compressed = await _compressor.compressOwnedFile(
          target,
          kind: originalFormat == 'heic' || asset?.type == AssetType.image
              ? MediaCompressionKind.image
              : asset?.type == AssetType.video
              ? MediaCompressionKind.video
              : null,
          allowLargerImageResult: originalFormat == 'heic',
        );
        final outputFormat = forPost ? await _imageFormat(compressed) : null;
        final uploadExtension = switch (outputFormat) {
          'jpeg' => '.jpg',
          'png' => '.png',
          'webp' => '.webp',
          _ => null,
        };
        result.add(
          attachment.withPreparedFile(
            PreparedGalleryFile(
              compressed,
              name: uploadExtension != null
                  ? p.setExtension(name, uploadExtension)
                  : p.extension(compressed.path) == extension
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

  Future<String?> _imageFormat(File file) async {
    final input = await file.open();
    try {
      final bytes = await input.read(16);
      if (bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255) {
        return 'jpeg';
      }
      if (bytes.length >= 8 &&
          bytes.sublist(0, 8).join(',') == '137,80,78,71,13,10,26,10') {
        return 'png';
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return 'webp';
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp' &&
          const [
            'heic',
            'heix',
            'hevc',
            'hevx',
            'mif1',
            'msf1',
          ].contains(String.fromCharCodes(bytes.sublist(8, 12)))) {
        return 'heic';
      }
      return null;
    } finally {
      await input.close();
    }
  }
}
