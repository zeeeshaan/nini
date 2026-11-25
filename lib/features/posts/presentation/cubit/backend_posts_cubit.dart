import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

class BackendPostsState {
  const BackendPostsState({
    this.posts = const [],
    this.loading = false,
    this.error = false,
    this.page = 0,
    this.hasMore = true,
    this.failedRefresh = false,
    this.searchId,
    this.understood,
    this.searchPositions = const {},
  });
  final List<PostItem> posts;
  final bool loading, error, hasMore, failedRefresh;
  final int page;
  final String? searchId;
  final SearchUnderstood? understood;
  final Map<String, int> searchPositions;
}

/// Each screen owns its own pagination and never merges private and public data.
class BackendPostsCubit extends Cubit<BackendPostsState> {
  BackendPostsCubit(this._load, {ApiPostsRepository? repository})
    : super(const BackendPostsState()) {
    _deletions = repository?.deletedPosts.listen(removePost);
  }
  StreamSubscription<String>? _deletions;
  Future<BackendPostsPage> Function(int page) _load;
  int _revision = 0;

  void invalidate() {
    _revision++;
    emit(const BackendPostsState(loading: true));
  }

  void removePost(String id) {
    _revision++;
    final previous = state;
    emit(
      BackendPostsState(
        posts: List.unmodifiable(previous.posts.where((post) => post.id != id)),
        page: previous.page,
        hasMore: previous.hasMore,
        searchId: previous.searchId,
        understood: previous.understood,
        searchPositions: previous.searchPositions,
      ),
    );
  }

  Future<void> refresh({
    Future<BackendPostsPage> Function(int page)? load,
    bool preserve = false,
  }) async {
    if (load == null && state.loading) return;
    if (load != null) _load = load;
    final revision = ++_revision;
    final previous = state;
    final keep = load == null || preserve;
    emit(
      BackendPostsState(
        posts: keep ? previous.posts : const [],
        page: keep ? previous.page : 0,
        hasMore: keep ? previous.hasMore : true,
        loading: true,
        searchId: keep ? previous.searchId : null,
        understood: keep ? previous.understood : null,
        searchPositions: keep ? previous.searchPositions : const {},
      ),
    );
    await _request(1, revision);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final revision = _revision;
    final previous = state;
    emit(
      BackendPostsState(
        posts: previous.posts,
        loading: true,
        page: previous.page,
        hasMore: previous.hasMore,
        searchId: previous.searchId,
        understood: previous.understood,
        searchPositions: previous.searchPositions,
      ),
    );
    await _request(previous.page + 1, revision);
  }

  Future<void> _request(int page, int revision) async {
    try {
      final result = await _load(page);
      if (isClosed || revision != _revision) return;
      if (result.page != page) throw const FormatException('Unexpected page.');
      final seen = <String>{};
      final items = [
        for (final post in [if (page > 1) ...state.posts, ...result.items])
          if (seen.add(post.id)) post,
      ];
      final positions = <String, int>{if (page > 1) ...state.searchPositions};
      result.searchPositions.forEach(
        (id, position) => positions.putIfAbsent(id, () => position),
      );
      emit(
        BackendPostsState(
          posts: List.unmodifiable(items),
          page: result.page,
          hasMore: result.page * result.limit < result.total,
          searchId: page == 1 ? result.searchId : state.searchId,
          understood: page == 1 ? result.understood : state.understood,
          searchPositions: Map.unmodifiable(positions),
        ),
      );
    } catch (_) {
      if (!isClosed && revision == _revision) {
        emit(
          BackendPostsState(
            posts: state.posts,
            page: state.page,
            hasMore: state.hasMore,
            error: true,
            failedRefresh: page == 1,
            searchId: state.searchId,
            understood: state.understood,
            searchPositions: state.searchPositions,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _revision++;
    _deletions?.cancel();
    return super.close();
  }
}

class FeedCubit extends BackendPostsCubit {
  FeedCubit(this.repository)
    : super((page) => repository.loadFeed(page: page), repository: repository);

  final ApiPostsRepository repository;
  int _enrichRevision = 0;

  @override
  Future<void> refresh({
    Future<BackendPostsPage> Function(int page)? load,
    bool preserve = false,
  }) async {
    await super.refresh(load: load, preserve: preserve);
    // Feed cards are already emitted; stock/unit fill in after first paint.
    await _enrichInventory();
  }

  @override
  Future<void> loadMore() async {
    await super.loadMore();
    await _enrichInventory();
  }

  Future<void> refreshFromServer() {
    var forceFirstPage = true;
    return refresh(
      preserve: true,
      load: (page) {
        final force = page == 1 && forceFirstPage;
        forceFirstPage = false;
        if (force) repository.clearInventoryCache();
        return repository.loadFeed(page: page, force: force);
      },
    );
  }

  Future<void> _enrichInventory() async {
    if (isClosed || state.error || state.posts.isEmpty) return;
    final revision = ++_enrichRevision;
    final cached = [
      for (final post in state.posts) repository.applyCachedInventory(post),
    ];
    if (!_sameInventory(state.posts, cached)) {
      _emitPosts(cached);
    }
    final snapshot = List<PostItem>.of(state.posts);
    await repository.enrichInventoryProgressive(
      snapshot,
      onUpdated: (updated) {
        if (isClosed || revision != _enrichRevision) return;
        _replacePost(updated);
      },
    );
  }

  bool _sameInventory(List<PostItem> a, List<PostItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].stockCount != b[i].stockCount ||
          a[i].metadata['unit'] != b[i].metadata['unit'] ||
          a[i].metadata['inventoryStatus'] !=
              b[i].metadata['inventoryStatus'] ||
          a[i].metadata['inStock'] != b[i].metadata['inStock']) {
        return false;
      }
    }
    return true;
  }

  void _replacePost(PostItem updated) {
    final posts = state.posts;
    final index = posts.indexWhere((post) => post.id == updated.id);
    if (index < 0) return;
    final next = List<PostItem>.of(posts);
    next[index] = updated;
    _emitPosts(next);
  }

  void _emitPosts(List<PostItem> posts) {
    final previous = state;
    emit(
      BackendPostsState(
        posts: List.unmodifiable(posts),
        page: previous.page,
        hasMore: previous.hasMore,
        searchId: previous.searchId,
        understood: previous.understood,
        searchPositions: previous.searchPositions,
      ),
    );
  }
}

class OwnPostsCubit extends BackendPostsCubit {
  OwnPostsCubit(ApiPostsRepository repository)
    : super(
        (page) => repository.loadOwnProfilePosts(page: page),
        repository: repository,
      );

  String? requestedCategoryId;
  bool hasRequestedCategory = false;
}
