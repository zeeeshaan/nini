import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/post_media_changes.dart';
import 'demo_posts.dart';
import 'local_post_media_store.dart';
import 'profile_sample_posts.dart';

/// Local adapter for the post API. Serializes read-modify-write operations and
/// replaces the JSON index atomically. Media and post IDs are independent, so
/// replacing attachments never changes a post's identity or analytics key.
class LocalPostsRepository implements PostsRepository {
  LocalPostsRepository({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? _documentsDirectory;
  final Future<Directory> Function() _directoryProvider;
  final _mediaStore = LocalPostMediaStore();
  Future<void> _pending = Future.value();

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

  Future<({List<PostItem> posts, bool needsMigration})> _read(
    Directory root,
  ) async {
    final index = File(p.join(root.path, 'posts.json'));
    if (!await index.exists()) {
      return (posts: <PostItem>[], needsMigration: false);
    }
    final json = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    final version = json['version'];
    if (version != 1 && version != 2) {
      throw const FormatException('Unsupported post storage version');
    }
    final storedPosts = json['posts'] as List;
    final posts = storedPosts.map((entry) {
      final data = Map<String, dynamic>.from(entry as Map);
      data['media'] = (data['media'] as List? ?? []).map((item) {
        final media = Map<String, dynamic>.from(item as Map);
        for (final key in ['path', 'thumbnailPath']) {
          if (media[key] == null) continue;
          final path = media[key] as String;
          if (p.isAbsolute(path) || p.split(path).contains('..')) {
            throw const FormatException('Invalid media path');
          }
          if (media['source'] == 'asset') {
            if (!path.startsWith('assets/')) {
              throw const FormatException('Invalid asset path');
            }
          } else {
            media[key] = p.join(root.path, path);
          }
        }
        return media;
      }).toList();
      return PostItem.fromJson(data);
    }).toList();
    // Match complete historical records, not just IDs or publication dates.
    // Edited samples and user-created posts must never be discarded here.
    final sampleRecords = {
      for (final sample in [...demoPosts, ...createProfileSamplePosts()])
        jsonEncode(sample.toJson()),
    };
    final retained = [
      for (var index = 0; index < posts.length; index++)
        if (!sampleRecords.contains(jsonEncode(storedPosts[index])))
          posts[index],
    ];
    return (
      posts: retained,
      needsMigration: version == 1 || retained.length != posts.length,
    );
  }

  @override
  Future<List<PostItem>> load() => _serialize(() async {
    final root = await _root();
    final snapshot = await _read(root);
    if (snapshot.needsMigration) await _write(root, snapshot.posts);
    return snapshot.posts;
  });

  @override
  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) => _serialize(
    () => _save(
      draft,
      mediaChanges: PostMediaChanges(
        retainedPaths: const [],
        additions: attachments,
      ),
    ),
  );

  @override
  Future<PostItem> update(
    String postId,
    PostDraft draft, {
    PostMediaChanges? mediaChanges,
  }) => _serialize(
    () => _save(draft, postId: postId, mediaChanges: mediaChanges),
  );

  @override
  Future<void> delete(String postId) => _serialize(() async {
    final root = await _root();
    final posts = (await _read(root)).posts;
    final existing = posts.where((item) => item.id == postId).firstOrNull;
    if (existing == null) return;
    final retained = posts.where((item) => item.id != postId).toList();
    // Commit first: a failed index write leaves both the post and files intact.
    await _write(root, retained);
    await _mediaStore.removeUnused(
      root,
      existing.media,
      retained.expand((item) => item.media),
    );
  });

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<PostItem> _save(
    PostDraft draft, {
    String? postId,
    PostMediaChanges? mediaChanges,
  }) async {
    final root = await _root();
    final previous = (await _read(root)).posts;
    PostItem? existing;
    if (postId != null) {
      for (final item in previous) {
        if (item.id == postId) existing = item;
      }
      if (existing == null) {
        throw const PostPublishException(ProfilePostStrings.postMissing);
      }
    }
    final retainedPaths =
        mediaChanges?.retainedPaths ??
        existing?.media.map((item) => item.path).toList() ??
        const <String>[];
    final canonicalMedia = {
      for (final item in existing?.media ?? const <PostMedia>[])
        item.path: item,
    };
    if (retainedPaths.toSet().length != retainedPaths.length ||
        retainedPaths.any((path) => !canonicalMedia.containsKey(path))) {
      throw const PostPublishException(ProfilePostStrings.mediaUnavailable);
    }
    final additions = mediaChanges?.additions ?? const <GalleryAttachment>[];
    _validate(
      draft,
      hasMedia: retainedPaths.isNotEmpty || additions.isNotEmpty,
    );
    StoredPostMedia? copied;
    var committed = false;
    try {
      if (additions.isNotEmpty) {
        copied = await _mediaStore.copy(root, additions, draft.altTexts);
      }
      final media = [
        for (final path in retainedPaths)
          PostMedia(
            path: path,
            name: canonicalMedia[path]!.name,
            type: canonicalMedia[path]!.type,
            source: canonicalMedia[path]!.source,
            thumbnailPath: canonicalMedia[path]!.thumbnailPath,
            altText:
                draft.altTexts['media:$path'] ?? canonicalMedia[path]!.altText,
          ),
        ...?copied?.items,
      ];
      final price = _number(draft.price);
      final discount = _number(draft.discount) ?? 0;
      final post = PostItem(
        id:
            existing?.id ??
            'local_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
        imageAsset: existing?.imageAsset ?? '',
        title: draft.title.trim(),
        category: draft.postType == CreatePostType.product
            ? AppStrings.product
            : AppStrings.services,
        profileCategoryId: draft.profileCategoryId,
        stockCount: _number(draft.warehouseStock)?.toInt() ?? 0,
        price: price == null ? '' : _money(price * (1 - discount / 100)),
        originalPrice: price != null && discount > 0 ? _money(price) : '',
        media: List.unmodifiable(media),
        details: PostDetails.fromJson({
          ...?existing?.metadata,
          ...jsonDecode(jsonEncode(draft.toJson())) as Map<String, dynamic>,
          'altTexts': {
            for (final item in media) 'media:${item.path}': item.altText,
          },
        }),
        publishedAt: existing == null ? DateTime.now() : existing.publishedAt,
      );
      final all = existing == null
          ? [post, ...previous]
          : [
              for (final item in previous)
                if (item.id == post.id) post else item,
            ];
      await _write(root, all);
      committed = true;
      if (existing != null && mediaChanges != null) {
        await _mediaStore.removeUnused(
          root,
          existing.media,
          all.expand((item) => item.media),
        );
      }
      return post;
    } finally {
      if (!committed && copied != null) await copied.discard();
    }
  }

  void _validate(PostDraft draft, {required bool hasMedia}) {
    if (PostDraftValidator.requiredFields(draft, hasAttachments: hasMedia) !=
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
  }

  Future<void> _write(Directory root, List<PostItem> posts) async {
    final temporary = File(p.join(root.path, 'posts.json.tmp'));
    try {
      final encoded = posts.map((item) {
        final data = item.toJson();
        data['media'] = item.media.map((entry) {
          final value = entry.toJson();
          if (entry.source == PostMediaSource.asset) return value;
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
      await temporary.writeAsString(
        jsonEncode({'version': 2, 'posts': encoded}),
        flush: true,
      );
      await temporary.rename(p.join(root.path, 'posts.json'));
    } finally {
      if (await temporary.exists()) await temporary.delete();
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
