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
  });
  final List<PostItem> posts;
  final bool loading, error, hasMore, failedRefresh;
  final int page;
  final String? searchId;
  final SearchUnderstood? understood;
}

/// Each screen owns its own pagination and never merges private and public data.
class BackendPostsCubit extends Cubit<BackendPostsState> {
  BackendPostsCubit(this._load) : super(const BackendPostsState());
  Future<BackendPostsPage> Function(int page) _load;
  int _revision = 0;

  void invalidate() {
    _revision++;
    emit(const BackendPostsState(loading: true));
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
      emit(
        BackendPostsState(
          posts: List.unmodifiable(items),
          page: result.page,
          hasMore: result.page * result.limit < result.total,
          searchId: page == 1 ? result.searchId : state.searchId,
          understood: page == 1 ? result.understood : state.understood,
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
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _revision++;
    return super.close();
  }
}

class FeedCubit extends BackendPostsCubit {
  FeedCubit(this.repository) : super((page) => repository.loadFeed(page: page));

  final ApiPostsRepository repository;

  Future<void> refreshFromServer() {
    var forceFirstPage = true;
    return refresh(
      preserve: true,
      load: (page) {
        final force = page == 1 && forceFirstPage;
        forceFirstPage = false;
        return repository.loadFeed(page: page, force: force);
      },
    );
  }
}

class OwnPostsCubit extends BackendPostsCubit {
  OwnPostsCubit(ApiPostsRepository repository)
    : super((page) => repository.loadPublishedMine(page: page));

  String? requestedCategoryId;
  bool hasRequestedCategory = false;
}
