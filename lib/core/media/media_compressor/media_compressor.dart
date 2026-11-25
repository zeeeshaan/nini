import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress_next/video_compress_next.dart';

import '../document_compressor/document_compressor.dart';

enum MediaCompressionKind { image, video, document }

/// One policy for app-owned upload copies. Picker originals are never modified.
class MediaCompressor {
  static Future<void> _videoQueue = Future.value();
  static const imageQuality = 82;
  static const imageDimension = 1920;

  static MediaCompressionKind kindFor(String name) {
    final extension = p.extension(name).toLowerCase();
    if (const {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
      '.avif',
      '.gif',
    }.contains(extension)) {
      return MediaCompressionKind.image;
    }
    if (const {
      '.mp4',
      '.mov',
      '.mkv',
      '.webm',
      '.avi',
      '.m4v',
    }.contains(extension)) {
      return MediaCompressionKind.video;
    }
    return MediaCompressionKind.document;
  }

  /// Replaces only an app-owned copy, and only with a smaller valid result.
  Future<File> compressOwnedFile(
    File source, {
    MediaCompressionKind? kind,
    bool allowLargerImageResult = false,
  }) async {
    if (await source.length() == 0) {
      throw const FormatException('Empty attachment');
    }
    final type = kind ?? kindFor(source.path);
    var extension = p.extension(source.path).toLowerCase();
    // Preserve animated images rather than flattening them to a still frame.
    if (extension == '.gif') return source;
    // PNG encoding also preserves transparency in still WebP images.
    var png = extension == '.png' || extension == '.webp';
    if (type == MediaCompressionKind.image) {
      final header = await _imageHeader(source);
      if (header.animated) return source;
      png = png || header.preserveAlpha;
      extension = png ? '.png' : '.jpg';
    } else if (type == MediaCompressionKind.video) {
      extension = '.mp4';
    }
    final candidate = File(
      p.join(
        source.parent.path,
        '${p.basenameWithoutExtension(source.path)}_optimized_'
        '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}$extension',
      ),
    );
    var accepted = false;
    try {
      switch (type) {
        case MediaCompressionKind.image:
          await FlutterImageCompress.compressAndGetFile(
            source.path,
            candidate.path,
            minWidth: imageDimension,
            minHeight: imageDimension,
            quality: imageQuality,
            format: png ? CompressFormat.png : CompressFormat.jpeg,
            autoCorrectionAngle: true,
            keepExif: false,
          );
        case MediaCompressionKind.video:
          final operation = _videoQueue.then((_) => _video(source, candidate));
          _videoQueue = operation.then<void>((_) {}, onError: (Object _) {});
          await operation;
        case MediaCompressionKind.document:
          await DocumentCompressor().compress(source, candidate);
      }
      if (await candidate.exists()) {
        final length = await candidate.length();
        var validConversion = false;
        if (allowLargerImageResult &&
            type == MediaCompressionKind.image &&
            length > 0) {
          final input = await candidate.open();
          try {
            final bytes = await input.read(8);
            validConversion = png
                ? bytes.length >= 8 &&
                      bytes.join(',') == '137,80,78,71,13,10,26,10'
                : bytes.length >= 3 &&
                      bytes[0] == 255 &&
                      bytes[1] == 216 &&
                      bytes[2] == 255;
          } finally {
            await input.close();
          }
        }
        if (length > 0 &&
            (allowLargerImageResult && type == MediaCompressionKind.image
                ? validConversion
                : length < await source.length())) {
          await source.delete();
          accepted = true;
          return candidate;
        }
      }
    } catch (error) {
      // A failed or unsupported optimization must not lose a selected upload.
      debugPrint('Media compression kept original (${error.runtimeType}).');
    } finally {
      if (!accepted && await candidate.exists()) await candidate.delete();
    }
    return source;
  }

  Future<({bool animated, bool preserveAlpha})> _imageHeader(
    File source,
  ) async {
    final input = await source.open();
    try {
      final header = String.fromCharCodes(await input.read(65536));
      final png = header.startsWith('\u0089PNG');
      final webp = header.startsWith('RIFF') && header.contains('WEBP');
      return (
        animated:
            header.startsWith('GIF8') ||
            (png && header.contains('acTL')) ||
            (webp && header.contains('ANIM')),
        preserveAlpha: png || webp,
      );
    } finally {
      await input.close();
    }
  }

  Future<void> _video(File source, File target) async {
    final original = await VideoCompressor.getMediaInfo(source.path);
    final result = await VideoCompressor.compress(
      source.path,
      options: CompressOptions(
        maxShortSide: 720,
        maxLongSide: 1280,
        includeAudio: true,
        deleteOrigin: false,
        outputPath: target.path,
      ),
    ).result;
    if (result.width <= 0 ||
        result.height <= 0 ||
        (original.hasAudio && !result.hasAudio)) {
      throw const FormatException('Incomplete compressed video');
    }
  }

  Future<Uint8List> compressProfilePhoto(Uint8List bytes) async {
    if (bytes.isEmpty) throw const FormatException('Empty profile photo');
    final png = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50;
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: imageQuality,
        format: png ? CompressFormat.png : CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (result.isNotEmpty && result.length < bytes.length) return result;
    } catch (error) {
      debugPrint('Profile compression kept original (${error.runtimeType}).');
    }
    return bytes;
  }
}
