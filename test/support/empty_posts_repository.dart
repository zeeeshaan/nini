import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// Existing UI tests do not depend on platform storage or asynchronous file IO.
class EmptyPostsRepository implements PostsRepository {
  const EmptyPostsRepository();
  @override
  Future<List<PostItem>> load() async => [];
  @override
  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) => Future.error(UnsupportedError('Use a publishing fixture for this test'));
}
