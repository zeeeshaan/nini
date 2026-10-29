import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/shared/models/post/post_item.dart';

abstract class PostsRepository {
  Future<List<PostItem>> load();
  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  );
}

class PostPublishException implements Exception {
  const PostPublishException(this.message);
  final String message;
}
