import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// One local user's likes, shared by all views of a post for this app session.
class PostLikesCubit extends Cubit<Set<String>> {
  PostLikesCubit([this.repository]) : super(const <String>{});
  final ApiPostsRepository? repository;
  final _backend = <String, ({bool liked, int count})>{};
  final _pending = <String>{};
  final _uncertain = <String>{};

  ({bool liked, int count})? backendState(String id) => _backend[id];

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
        _pending.contains(id) ||
        _uncertain.contains(id)) {
      return false;
    }
    _pending.add(id);
    try {
      if (current == null) {
        final post = await repo.loadDetail(id);
        if (isClosed || !repo.isCurrentAccount()) return false;
        seed(post);
        current = _backend[id];
        if (current == null) return false;
      }
      final result = await repo.setLike(id, liked: !current.liked);
      if (isClosed || !repo.isCurrentAccount()) return false;
      _backend[id] = result;
      _notify();
      return true;
    } catch (error) {
      if (isClosed || !repo.isCurrentAccount() || error is PostApiException) {
        return false;
      }
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
          if (!isClosed && liked is bool && count is int && count >= 0) {
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
