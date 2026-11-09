import 'dart:convert';
import 'dart:io';

import 'package:nini/shared/models/local_identity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/saved_post.dart';
import '../domain/saved_posts_repository.dart';

/// Device-local bookmarks for the app's existing local profile identity.
class LocalSavedPostsRepository implements SavedPostsRepository {
  LocalSavedPostsRepository({
    Future<Directory> Function()? directoryProvider,
    this.profileId = localProfileId,
  }) : _directoryProvider = directoryProvider ?? _documents;

  final Future<Directory> Function() _directoryProvider;
  final String profileId;
  Future<void> _pending = Future.value();

  static Future<Directory> _documents() async => Platform.isIOS
      ? Directory(p.join(Directory.systemTemp.parent.path, 'Documents'))
      : getApplicationDocumentsDirectory();

  Future<File> _index() async {
    final documents = await _directoryProvider();
    final root = await Directory(p.join(documents.path, 'nini_saved_posts'))
        .create(recursive: true);
    return File(p.join(root.path, '${Uri.encodeComponent(profileId)}.json'));
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<List<SavedPost>> load() => _serialize(() async {
    final index = await _index();
    if (!await index.exists()) return <SavedPost>[];
    final data = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1 || data['profileId'] != profileId) {
      throw const FormatException('Unsupported saved-post storage');
    }
    final posts = (data['posts'] as List)
        .map(
          (item) => SavedPost.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final ids = posts.map((entry) => entry.post.id).toSet();
    if (ids.length != posts.length || ids.any((id) => id.isEmpty)) {
      throw const FormatException('Invalid saved-post IDs');
    }
    return posts;
  });

  @override
  Future<void> save(List<SavedPost> posts) => _serialize(() async {
    final index = await _index();
    final temporary = File('${index.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'profileId': profileId,
          'posts': posts.map((entry) => entry.toJson()).toList(),
        }),
        flush: true,
      );
      await temporary.rename(index.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  });
}
