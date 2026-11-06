import 'package:nini/shared/models/post/post_item.dart';

class PostsState {
  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.isPublishing = false,
    this.loadFailed = false,
    this.publishError,
    this.lastPublished,
    this.deletingPostId,
    this.deleteError,
  });
  final List<PostItem> posts;
  final bool isLoading, isPublishing, loadFailed;
  final String? publishError, deletingPostId, deleteError;
  final PostItem? lastPublished;
  bool get isBusy => isPublishing || deletingPostId != null;
  PostItem? find(String id) => posts.where((item) => item.id == id).firstOrNull;

  /// Records in the local profile dataset can be managed on this device.
  /// Publication time is not an ownership flag. A remote adapter must enforce
  /// owner identity when returning and mutating the profile's records.
  bool canManage(PostItem post) =>
      !isLoading && !loadFailed && find(post.id) != null;

  PostsState copyWith({
    List<PostItem>? posts,
    bool? isLoading,
    bool? isPublishing,
    bool? loadFailed,
    String? publishError,
    String? deletingPostId,
    String? deleteError,
    PostItem? lastPublished,
    bool clearPublishError = false,
    bool clearDeleteError = false,
    bool clearDeletingPostId = false,
    bool clearLastPublished = false,
  }) => PostsState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    isPublishing: isPublishing ?? this.isPublishing,
    loadFailed: loadFailed ?? this.loadFailed,
    publishError: clearPublishError ? null : publishError ?? this.publishError,
    deletingPostId: clearDeletingPostId
        ? null
        : deletingPostId ?? this.deletingPostId,
    deleteError: clearDeleteError ? null : deleteError ?? this.deleteError,
    lastPublished: clearLastPublished
        ? null
        : lastPublished ?? this.lastPublished,
  );
}
