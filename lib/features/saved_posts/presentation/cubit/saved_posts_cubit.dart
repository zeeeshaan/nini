import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import '../../domain/saved_post.dart';
import '../../domain/saved_posts_repository.dart';
import 'saved_posts_state.dart';

export 'saved_posts_state.dart';

class SavedPostsCubit extends Cubit<SavedPostsState> {
  SavedPostsCubit(this.repository, {PostsCubit? posts})
    : _posts = posts,
      super(const SavedPostsState()) {
    _postsSubscription = posts?.stream.listen((value) {
      if (!value.isLoading && !value.loadFailed && !_closing) {
        unawaited(_serialize(() => _syncLocalPosts(value)));
      }
    });
  }

  final SavedPostsRepository repository;
  final PostsCubit? _posts;
  StreamSubscription<PostsState>? _postsSubscription;
  Future<void> _pending = Future.value();
  bool _loaded = false, _closing = false;

  bool isSaved(String postId) => state.isSaved(postId);

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _publish(
    List<SavedPost> posts, {
    bool loading = false,
    bool saving = false,
    bool loadFailed = false,
    bool storageError = false,
    String? actionPostId,
    int? actionRevision,
  }) {
    if (isClosed) return;
    emit(
      SavedPostsState(
        posts: List.unmodifiable(posts),
        loading: loading,
        saving: saving,
        loadFailed: loadFailed,
        storageError: storageError,
        actionPostId: actionPostId,
        actionRevision: actionRevision ?? state.actionRevision,
      ),
    );
  }

  Future<void> load() => _closing
      ? Future.value()
      : _serialize(() async {
          await _load();
        });

  Future<bool> _load() async {
    _publish(state.posts, loading: true);
    try {
      final posts = await repository.load();
      _loaded = true;
      _publish(posts);
      final local = _posts?.state;
      if (local != null) await _syncLocalPosts(local);
      return true;
    } catch (_) {
      _loaded = false;
      _publish(state.posts, loadFailed: true, storageError: true);
      return false;
    }
  }

  Future<bool> toggle(PostItem post, {PostSeller? seller}) {
    if (_closing || post.id.isEmpty) return Future.value(false);
    return _serialize(() async {
      if (!_loaded && !await _load()) return false;
      final previous = state.posts;
      final posts = previous
          .where((entry) => entry.post.id != post.id)
          .toList();
      if (posts.length == previous.length) {
        final local = _posts?.state.find(post.id);
        posts.insert(
          0,
          SavedPost(
            post: local ?? post,
            seller: seller ?? (local != null ? localPostSeller : null),
            savedAt: DateTime.now(),
            isLocalPost: local != null,
          ),
        );
      }
      return _commit(posts, actionPostId: post.id);
    });
  }

  Future<bool> remove(String postId) {
    if (_closing || postId.isEmpty) return Future.value(false);
    return _serialize(() async {
      if (!_loaded && !await _load()) return false;
      final posts = state.posts
          .where((entry) => entry.post.id != postId)
          .toList();
      if (posts.length == state.posts.length) return true;
      return _commit(posts, actionPostId: postId);
    });
  }

  Future<bool> _commit(
    List<SavedPost> posts, {
    required String actionPostId,
  }) async {
    final previous = state.posts;
    _publish(previous, saving: true);
    try {
      await repository.save(posts);
      _publish(
        posts,
        actionPostId: actionPostId,
        actionRevision: state.actionRevision + 1,
      );
      return true;
    } catch (_) {
      _publish(previous, storageError: true);
      return false;
    }
  }

  Future<void> _syncLocalPosts(PostsState local) async {
    if (!_loaded || local.isLoading || local.loadFailed) return;
    var changed = false;
    final posts = <SavedPost>[];
    for (final entry in state.posts) {
      if (!entry.isLocalPost) {
        posts.add(entry);
        continue;
      }
      final current = local.find(entry.post.id);
      if (current == null) {
        changed = true;
      } else if (jsonEncode(current.toJson()) !=
          jsonEncode(entry.post.toJson())) {
        changed = true;
        posts.add(entry.withPost(current));
      } else {
        posts.add(entry);
      }
    }
    if (!changed) return;
    try {
      await repository.save(posts);
      _publish(posts);
    } catch (_) {
      _publish(state.posts, storageError: true);
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _postsSubscription?.cancel();
    await _pending;
    await super.close();
  }
}
