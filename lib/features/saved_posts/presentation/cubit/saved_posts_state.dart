import '../../domain/saved_post.dart';

class SavedPostsState {
  const SavedPostsState({
    this.posts = const [],
    this.loading = true,
    this.saving = false,
    this.loadFailed = false,
    this.storageError = false,
    this.actionPostId,
    this.actionRevision = 0,
  });

  final List<SavedPost> posts;
  final bool loading, saving, loadFailed, storageError;

  /// Only successful user toggles carry an action ID; loading/sync never do.
  final String? actionPostId;
  final int actionRevision;

  bool isSaved(String postId) => posts.any((entry) => entry.post.id == postId);
}
