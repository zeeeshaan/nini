import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/search/data/search_catalog.dart';

import '../../domain/saved_post.dart';
import '../../domain/saved_posts_repository.dart';
import 'saved_posts_state.dart';

export 'saved_posts_state.dart';

class SavedPostsCubit extends Cubit<SavedPostsState> {
  SavedPostsCubit(
    this.repository, {
    PostsCubit? posts,
    ApiPostsRepository? backendPosts,
  }) : _posts = posts,
       _backendPosts = backendPosts,
       super(const SavedPostsState()) {
    _postsSubscription = posts?.stream.listen((value) {
      if (!value.isLoading && !value.loadFailed && !_closing) {
        unawaited(_serialize(() => _syncLocalPosts(value)));
      }
    });
    _deletions = backendPosts?.deletedPosts.listen((id) {
      if (!_closing && !isClosed) {
        _saved[id] = false;
        _publish(
          state.posts.where((e) => e.post.id != id || e.isLocalPost).toList(),
        );
      }
    });
  }

  final SavedPostsRepository repository;
  final PostsCubit? _posts;
  final ApiPostsRepository? _backendPosts;
  StreamSubscription<PostsState>? _postsSubscription;
  StreamSubscription<String>? _deletions;
  Future<void> _pending = Future.value();
  bool _loaded = false, _closing = false;
  final _saved = <String, bool>{};
  final _confirmed = <String, bool>{};
  final _busy = <String>{}, _uncertain = <String>{};
  List<SavedPost> _legacy = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMoreRequested = false;

  void seed(PostItem post) {
    if (_closing ||
        isClosed ||
        post.metadata['backend'] != true ||
        _saved.containsKey(post.id)) {
      return;
    }
    final saved = post.metadata['isSaved'];
    if (saved is bool) {
      _saved[post.id] = saved;
      _publish(
        state.posts,
        loading: state.loading,
        saving: state.saving,
        loadFailed: state.loadFailed,
        storageError: state.storageError,
      );
    }
  }

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
        posts: List.unmodifiable(
          posts.where(
            (entry) =>
                entry.isLocalPost ||
                _backendPosts?.isDeleted(entry.post.id) != true,
          ),
        ),
        loading: loading,
        saving: saving,
        loadFailed: loadFailed,
        storageError: storageError,
        actionPostId: actionPostId,
        actionRevision: actionRevision ?? state.actionRevision,
        backendSaved: Map.unmodifiable(_saved),
        page: _page,
        hasMore: _hasMore,
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
      final stored = await repository.load();
      _legacy = _backendPosts == null
          ? []
          : stored
                .where(
                  (e) => !e.isLocalPost && e.post.metadata['backend'] == true,
                )
                .toList();
      final posts = stored
          .where(
            (entry) =>
                (_backendPosts == null ||
                    entry.isLocalPost ||
                    entry.post.metadata['backend'] != true) &&
                (entry.isLocalPost ||
                    _backendPosts?.isDeleted(entry.post.id) != true),
          )
          .toList();
      if (_backendPosts != null) {
        late final ({
          List<({PostItem post, DateTime? savedAt})> items,
          int total,
          int page,
          int limit,
        })
        page;
        try {
          page = await _backendPosts.loadSaved();
        } catch (_) {
          if (_closing || isClosed || !_backendPosts.isCurrentAccount()) {
            return false;
          }
          _loaded = true;
          final previousRemote = state.posts.where(
            (e) => !e.isLocalPost && e.post.metadata['backend'] == true,
          );
          _publish([...previousRemote, ...posts], loadFailed: true);
          return true;
        }
        if (_closing || isClosed || !_backendPosts.isCurrentAccount()) {
          return false;
        }
        final remote = [
          for (final entry in page.items)
            if (_confirmed[entry.post.id] != false)
              SavedPost(
                post: entry.post,
                seller: SearchCatalog.sellerFor(entry.post),
                savedAt: entry.savedAt,
              ),
        ];
        for (final entry in remote) {
          _saved[entry.post.id] = true;
        }
        _page = page.page;
        _hasMore = page.page * page.limit < page.total;
        posts.insertAll(0, remote);
      }
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
    if (post.metadata['backend'] == true) {
      return _backendPosts == null
          ? Future.value(false)
          : _toggleBackend(post, seller: seller);
    }
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

  Future<bool> _toggleBackend(
    PostItem post, {
    PostSeller? seller,
    bool remove = false,
  }) {
    final repo = _backendPosts;
    if (repo == null ||
        _closing ||
        _uncertain.contains(post.id) ||
        !_busy.add(post.id)) {
      return Future.value(false);
    }
    return _serialize(() async {
      try {
        if (!repo.isCurrentAccount()) return false;
        var current = _saved[post.id];
        if (current == null) {
          final detail = await repo.loadDetail(post.id);
          current = detail.metadata['isSaved'] is bool
              ? detail.metadata['isSaved'] as bool
              : null;
          if (current == null) return false;
          _saved[post.id] = current;
        }
        if (remove && current == false) return true;
        final desired = remove ? false : !current;
        _publish(state.posts, saving: true);
        try {
          await repo.setSaved(post.id, saved: desired);
        } catch (error) {
          if (_closing || isClosed || !repo.isCurrentAccount()) return false;
          final status = error is DioException
              ? error.response?.statusCode
              : null;
          if (error is! PostApiException &&
              (error is! DioException ||
                  status == null ||
                  status == 408 ||
                  status >= 500)) {
            _uncertain.add(post.id);
            try {
              final detail = await repo.loadDetail(post.id);
              final saved = detail.metadata['isSaved'];
              if (saved is bool && repo.isCurrentAccount()) {
                _saved[post.id] = saved;
                _confirmed[post.id] = saved;
                _uncertain.remove(post.id);
              }
            } catch (_) {
              /* Keep the confirmed state until a read succeeds. */
            }
          }
          _publish(state.posts, storageError: true);
          return false;
        }
        if (_closing || isClosed || !repo.isCurrentAccount()) return false;
        _saved[post.id] = desired;
        _confirmed[post.id] = desired;
        final visible = desired
            ? state.posts
            : state.posts
                  .where((e) => e.post.id != post.id || e.isLocalPost)
                  .toList();
        _publish(
          visible,
          actionPostId: post.id,
          actionRevision: state.actionRevision + 1,
        );
        await _load();
        return !_closing && !isClosed && repo.isCurrentAccount();
      } catch (_) {
        if (!_closing && !isClosed && repo.isCurrentAccount()) {
          _publish(state.posts, storageError: true);
        }
        return false;
      } finally {
        _busy.remove(post.id);
      }
    });
  }

  Future<void> loadMore() {
    if (_closing ||
        !_hasMore ||
        _backendPosts == null ||
        _loadingMoreRequested) {
      return Future.value();
    }
    _loadingMoreRequested = true;
    return _serialize(() async {
      if (!_hasMore) return;
      _publish(state.posts, loading: true);
      try {
        final result = await _backendPosts.loadSaved(page: _page + 1);
        if (_closing || isClosed || !_backendPosts.isCurrentAccount()) return;
        final ids = state.posts.map((e) => e.post.id).toSet();
        final posts = [...state.posts];
        for (final entry in result.items) {
          if (_confirmed[entry.post.id] == false || !ids.add(entry.post.id)) {
            continue;
          }
          _saved[entry.post.id] = true;
          final item = SavedPost(
            post: entry.post,
            seller: SearchCatalog.sellerFor(entry.post),
            savedAt: entry.savedAt,
          );
          final firstLocal = posts.indexWhere(
            (e) => e.isLocalPost || e.post.metadata['backend'] != true,
          );
          if (firstLocal < 0) {
            posts.add(item);
          } else {
            posts.insert(firstLocal, item);
          }
        }
        _page = result.page;
        _hasMore = result.page * result.limit < result.total;
        _publish(posts);
      } catch (_) {
        if (!_closing && !isClosed && _backendPosts.isCurrentAccount()) {
          _publish(state.posts, loadFailed: true);
        }
      }
    }).whenComplete(() => _loadingMoreRequested = false);
  }

  Future<bool> remove(String postId) {
    if (_closing || postId.isEmpty) return Future.value(false);
    final entry = state.posts
        .where((e) => e.post.id == postId && e.post.metadata['backend'] == true)
        .firstOrNull;
    if (entry != null) {
      return _backendPosts == null
          ? Future.value(false)
          : _toggleBackend(entry.post, seller: entry.seller, remove: true);
    }
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
      await repository.save(
        _backendPosts == null
            ? posts
            : [
                ..._legacy,
                ...posts.where(
                  (e) => e.isLocalPost || e.post.metadata['backend'] != true,
                ),
              ],
      );
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
      await repository.save(
        _backendPosts == null
            ? posts
            : [
                ..._legacy,
                ...posts.where(
                  (e) => e.isLocalPost || e.post.metadata['backend'] != true,
                ),
              ],
      );
      _publish(posts);
    } catch (_) {
      _publish(state.posts, storageError: true);
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _postsSubscription?.cancel();
    await _deletions?.cancel();
    await _pending;
    await super.close();
  }
}
