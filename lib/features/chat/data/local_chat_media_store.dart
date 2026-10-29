import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/chat/domain/services/chat_media_store.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

/// Copies picker exports into a private chat cache; picker originals are untouched.
class LocalChatMediaStore implements ChatMediaStore {
  LocalChatMediaStore({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? _temporary;
  final Future<Directory> Function() _directoryProvider;
  static Future<Directory> _temporary() async =>
      Platform.isIOS ? Directory.systemTemp : getTemporaryDirectory();
  Future<Directory> _folder() async => Directory(
    p.join(
      (await _directoryProvider()).path,
      'nini_chat_media',
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
    ),
  ).create(recursive: true);

  @override
  Future<List<ChatAttachment>> prepare(List<GalleryAttachment> selected) async {
    if (selected.isEmpty) return [];
    final folder = await _folder();
    final result = <ChatAttachment>[];
    try {
      for (final (index, attachment) in selected.indexed) {
        final asset = attachment.asset, file = attachment.file;
        File? source;
        List<int>? bytes;
        if (asset != null) {
          try {
            source = await asset.file;
            if (source != null && !await source.exists()) source = null;
          } catch (_) {
            /* Try the original image export below. */
          }
          if (source == null && asset.type == AssetType.image) {
            bytes = await asset.originBytes;
          }
          if (source == null && bytes == null) {
            throw const FileSystemException('Media unavailable');
          }
        }
        final name = asset?.title ?? file?.name ?? p.basename(source!.path);
        var extension = p
            .extension(source?.path ?? name)
            .toLowerCase()
            .replaceAll(RegExp(r'[^.a-z0-9]'), '');
        if (extension.isEmpty && asset?.type == AssetType.image) {
          extension = '.jpg';
        }
        final target = File(
          p.join(
            folder.path,
            '$index${extension.length <= 12 ? extension : ''}',
          ),
        );
        if (source != null) {
          await source.copy(target.path);
        } else if (bytes != null) {
          await target.writeAsBytes(bytes, flush: true);
        } else {
          final sink = target.openWrite();
          try {
            await sink.addStream(file!.readAsByteStream());
            await sink.flush();
          } catch (_) {
            try {
              await sink.close();
            } catch (_) {}
            rethrow;
          }
          await sink.close();
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
            ? ChatAttachmentType.video
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
                  ].contains(extension)
            ? ChatAttachmentType.image
            : ChatAttachmentType.file;
        String? thumbnail;
        if (asset?.type == AssetType.video) {
          try {
            final image = await asset!.thumbnailDataWithSize(
              const ThumbnailSize(480, 480),
            );
            if (image != null) {
              final preview = File(p.join(folder.path, '$index-preview.jpg'));
              await preview.writeAsBytes(image, flush: true);
              thumbnail = preview.path;
            }
          } catch (_) {
            /* A video remains usable without a thumbnail. */
          }
        }
        result.add(
          ChatAttachment(
            path: target.path,
            name: name,
            type: type,
            sizeBytes: await target.length(),
            thumbnailPath: thumbnail,
          ),
        );
      }
      return List.unmodifiable(result);
    } catch (_) {
      if (await folder.exists()) await folder.delete(recursive: true);
      rethrow;
    }
  }

  @override
  Future<ChatAttachment> prepareVoice(String path, Duration duration) async {
    final folder = await _folder();
    try {
      final source = File(path),
          target = File(p.join(folder.path, 'voice.m4a'));
      if (duration <= Duration.zero || await source.length() == 0) {
        throw const FileSystemException('Empty voice recording');
      }
      await source.copy(target.path);
      return ChatAttachment(
        path: target.path,
        name: 'voice.m4a',
        type: ChatAttachmentType.voice,
        sizeBytes: await target.length(),
        duration: duration,
      );
    } catch (_) {
      await folder.delete(recursive: true);
      rethrow;
    }
  }

  @override
  Future<void> discard(Iterable<ChatAttachment> attachments) async {
    final root = p.join((await _directoryProvider()).path, 'nini_chat_media');
    for (final attachment in attachments) {
      for (final path in [attachment.path, attachment.thumbnailPath]) {
        if (path == null || !p.isWithin(root, p.normalize(path))) continue;
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      final parent = Directory(p.dirname(attachment.path));
      if (p.isWithin(root, parent.path) &&
          await parent.exists() &&
          await parent.list().isEmpty) {
        await parent.delete();
      }
    }
  }
}
