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
    this.backendSaved = const {},
    this.page = 0,
    this.hasMore = false,
  });

  final List<SavedPost> posts;
  final bool loading, saving, loadFailed, storageError;

  /// Only successful user toggles carry an action ID; loading/sync never do.
  final String? actionPostId;
  final int actionRevision;
  final Map<String, bool> backendSaved;
  final int page;
  final bool hasMore;

  bool isSaved(String postId) =>
      backendSaved[postId] ?? posts.any((entry) => entry.post.id == postId);
}
