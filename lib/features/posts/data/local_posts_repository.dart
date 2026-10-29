import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// Stores only user-created posts. Demo content is merged by PostsCubit.
/// Media is copied before an atomic index replacement; a failed publish never
/// inserts a partial post or overwrites an unreadable index.
class LocalPostsRepository implements PostsRepository {
  LocalPostsRepository({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? _documentsDirectory;
  final Future<Directory> Function() _directoryProvider;

  static Future<Directory> _documentsDirectory() async {
    if (Platform.isIOS) {
      // iOS's process temporary directory is <app sandbox>/tmp. Resolve the
      // sibling Documents directory without requiring newly added FFI assets
      // from path_provider_foundation to be present in an already-running app.
      return iosDocumentsDirectory(Directory.systemTemp);
    }
    return getApplicationDocumentsDirectory();
  }

  static Directory iosDocumentsDirectory(Directory temporaryDirectory) =>
      Directory(p.join(temporaryDirectory.parent.path, 'Documents'));
  Future<Directory> _root() async {
    // Also repair repository instances created before a hot reload, which
    // still hold the old path_provider function as their directory provider.
    final documents =
        Platform.isIOS && _directoryProvider == getApplicationDocumentsDirectory
        ? iosDocumentsDirectory(Directory.systemTemp)
        : await _directoryProvider();
    return Directory(p.join(documents.path, 'nini_posts'))
        .create(recursive: true);
  }

  Future<List<PostItem>> _read(Directory root) async {
    final index = File(p.join(root.path, 'posts.json'));
    if (!await index.exists()) return [];
    final json = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported post storage version');
    }
    return (json['posts'] as List).map((entry) {
      final data = Map<String, dynamic>.from(entry as Map);
      data['media'] = (data['media'] as List).map((item) {
        final media = Map<String, dynamic>.from(item as Map);
        for (final key in ['path', 'thumbnailPath']) {
          if (media[key] != null) {
            final path = media[key] as String;
            if (p.isAbsolute(path) || p.split(path).contains('..')) {
              throw const FormatException('Invalid media path');
            }
            media[key] = p.join(root.path, path);
          }
        }
        return media;
      }).toList();
      return PostItem.fromJson(data);
    }).toList();
  }

  @override
  Future<List<PostItem>> load() async => _read(await _root());

  @override
  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) async {
    if (PostDraftValidator.requiredFields(
          draft,
          hasAttachments: attachments.isNotEmpty,
        ) !=
        null) {
      throw const PostPublishException(AppStrings.publishDetailsRequired);
    }
    final price = _number(draft.price),
        discount = _number(draft.discount),
        stock = _number(draft.warehouseStock);
    if (draft.price.trim().isNotEmpty && (price == null || price < 0)) {
      throw const PostPublishException(AppStrings.invalidPrice);
    }
    if (draft.discount.trim().isNotEmpty &&
        (discount == null || discount < 0 || discount > 100)) {
      throw const PostPublishException(AppStrings.invalidDiscount);
    }
    if (draft.warehouseStock.trim().isNotEmpty &&
        (stock == null || stock < 0 || stock != stock.truncateToDouble())) {
      throw const PostPublishException(AppStrings.invalidStock);
    }
    final root = await _root();
    final previous = await _read(root);
    final id =
        'local_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    var folder = Directory(p.join(root.path, '.pending-$id'));
    final finalFolder = Directory(p.join(root.path, id));
    final pendingIndex = File(p.join(root.path, '$id.json.tmp'));
    var committed = false;
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
            altText: draft.altTexts[attachment.id] ?? '',
          ),
        );
      }
      folder = await folder.rename(finalFolder.path);
      final original = price ?? 0;
      final sale = original * (1 - (discount ?? 0) / 100);
      final post = PostItem(
        id: id,
        imageAsset: '',
        title: draft.title.trim(),
        category: draft.postType == CreatePostType.product
            ? AppStrings.product
            : AppStrings.services,
        stockCount: stock?.toInt() ?? 0,
        price: price == null ? '' : _money(sale),
        originalPrice: price != null && (discount ?? 0) > 0
            ? _money(original)
            : '',
        media: List.unmodifiable(media),
        details: PostDetails.fromJson(
          jsonDecode(jsonEncode(draft.toJson())) as Map<String, dynamic>,
        ),
        publishedAt: DateTime.now(),
      );
      final all = [post, ...previous];
      final encoded = all.map((item) {
        final data = item.toJson();
        data['media'] = item.media.map((entry) {
          final value = entry.toJson();
          value['path'] = p.relative(entry.path, from: root.path);
          if (entry.thumbnailPath != null) {
            value['thumbnailPath'] = p.relative(
              entry.thumbnailPath!,
              from: root.path,
            );
          }
          return value;
        }).toList();
        return data;
      }).toList();
      await pendingIndex.writeAsString(
        jsonEncode({'version': 1, 'posts': encoded}),
        flush: true,
      );
      await pendingIndex.rename(p.join(root.path, 'posts.json'));
      committed = true;
      return post;
    } finally {
      if (!committed) {
        if (await folder.exists()) await folder.delete(recursive: true);
        if (await pendingIndex.exists()) await pendingIndex.delete();
      }
    }
  }

  static double? _number(String value) {
    var normalized = value.trim();
    const digits = '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩';
    for (var index = 0; index < digits.length; index++) {
      normalized = normalized.replaceAll(digits[index], '${index % 10}');
    }
    normalized = normalized
        .replaceAll(RegExp('[,٬ ]'), '')
        .replaceAll('٫', '.')
        .replaceAll('%', '')
        .replaceAll('٪', '');
    final number = double.tryParse(normalized);
    return number != null && number.isFinite ? number : null;
  }

  static String _money(double number) => number == number.truncateToDouble()
      ? number.toStringAsFixed(0)
      : number.toStringAsFixed(2);
}
