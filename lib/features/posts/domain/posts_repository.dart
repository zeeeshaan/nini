import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';
import 'package:hywork/shared/models/post/post_item.dart';

import 'models/post_media_changes.dart';

abstract class PostsRepository {
  Future<List<PostItem>> load();

  /// Updates the existing post without changing its ID or publication time.
  /// Null media changes retain all attachments; an explicit request can retain,
  /// remove and add media in the same commit.
  Future<PostItem> update(
    String postId,
    PostDraft draft, {
    PostMediaChanges? mediaChanges,
  });

  /// Delete the stored post before disposing unreferenced media. Unknown IDs
  /// are a no-op. API adapters must enforce ownership for update and delete.
  Future<void> delete(String postId);

  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  );
}

class PostPublishException implements Exception {
  const PostPublishException(this.message);
  final String message;
}
