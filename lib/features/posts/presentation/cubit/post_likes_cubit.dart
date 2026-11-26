import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/shared/models/post/post_item.dart';

/// One local user's likes, shared by all views of a post for this app session.
class PostLikesCubit extends Cubit<Set<String>> {
  PostLikesCubit([this.repository]) : super(const <String>{});
  final ApiPostsRepository? repository;
  final _backend = <String, ({bool liked, int count})>{};
  final _pending = <String>{};
  final _uncertain = <String>{};
  final _revisions = <String, int>{};

  ({bool liked, int count})? backendState(String id) => _backend[id];

  int beginBackendRead(String id) => _revisions[id] = (_revisions[id] ?? 0) + 1;

  void reconcileBackendRead(PostItem post, int revision) {
    if (isClosed ||
        repository?.isCurrentAccount() != true ||
        post.metadata['backend'] != true ||
        _revisions[post.id] != revision ||
        _pending.contains(post.id) ||
        _uncertain.contains(post.id)) {
      return;
    }
    final liked = post.metadata['isLiked'], count = post.metadata['likes'];
    if (liked is bool && count is int && count >= 0) {
      final value = (liked: liked, count: count);
      if (_backend[post.id] != value) {
        _backend[post.id] = value;
        _notify();
      }
    }
  }

  void seed(PostItem post) {
    if (isClosed ||
        post.metadata['backend'] != true ||
        _backend.containsKey(post.id)) {
      return;
    }
    final liked = post.metadata['isLiked'], count = post.metadata['likes'];
    if (liked is bool && count is int && count >= 0) {
      _backend[post.id] = (liked: liked, count: count);
      _notify();
    }
  }

  void _notify() {
    if (!isClosed) emit(Set<String>.unmodifiable(state));
  }

  Future<bool> toggleBackend(String id) async {
    final repo = repository;
    var current = _backend[id];
    if (isClosed ||
        repo == null ||
        !repo.isCurrentAccount() ||
        _pending.contains(id) ||
        _uncertain.contains(id)) {
      return false;
    }
    _pending.add(id);
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    var mutationStarted = false;
    try {
      if (current == null) {
        final post = await repo.loadDetail(id);
        if (isClosed || !repo.isCurrentAccount()) return false;
        seed(post);
        current = _backend[id];
        if (current == null) return false;
      }
      final liked = !current.liked;
      _backend[id] = (
        liked: liked,
        count: liked
            ? current.count + 1
            : (current.count - 1).clamp(0, current.count),
      );
      _notify();
      mutationStarted = true;
      final result = await repo.setLike(id, liked: liked);
      if (isClosed || !repo.isCurrentAccount()) {
        // Drop optimistic state for a different account; never keep it.
        if (mutationStarted && current != null) {
          _backend[id] = current;
          _notify();
        }
        return false;
      }
      if (_backend[id] != result) {
        _backend[id] = result;
        _notify();
      }
      return true;
    } catch (error) {
      if (mutationStarted && current != null) {
        _backend[id] = current;
        _notify();
      }
      if (isClosed || !repo.isCurrentAccount()) return false;
      if (!mutationStarted || error is PostApiException) return false;
      final status = error is DioException ? error.response?.statusCode : null;
      if (error is! DioException ||
          status == null ||
          status == 408 ||
          status >= 500) {
        _uncertain.add(id);
        try {
          final post = await repo.loadDetail(id);
          final liked = post.metadata['isLiked'],
              count = post.metadata['likes'];
          if (!isClosed &&
              repo.isCurrentAccount() &&
              liked is bool &&
              count is int &&
              count >= 0) {
            _backend[id] = (liked: liked, count: count);
            _uncertain.remove(id);
            _notify();
          }
        } catch (_) {
          // Keep the previous confirmed state; never blindly repeat a mutation.
        }
      }
      return false;
    } finally {
      // Invalidate reads started while this mutation was in flight.
      _revisions[id] = (_revisions[id] ?? 0) + 1;
      _pending.remove(id);
    }
  }

  bool isLiked(String postId) => state.contains(postId);

  void toggleLike(String postId) {
    if (isClosed || postId.isEmpty) return;
    final likedPostIds = Set<String>.of(state);
    if (!likedPostIds.remove(postId)) likedPostIds.add(postId);
    emit(Set<String>.unmodifiable(likedPostIds));
  }
}
