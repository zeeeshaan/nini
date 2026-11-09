import 'saved_post.dart';

abstract class SavedPostsRepository {
  Future<List<SavedPost>> load();
  Future<void> save(List<SavedPost> posts);
}
