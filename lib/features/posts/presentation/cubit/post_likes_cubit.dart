import 'package:flutter_bloc/flutter_bloc.dart';

/// One local user's likes, shared by all views of a post for this app session.
class PostLikesCubit extends Cubit<Set<String>> {
  PostLikesCubit() : super(const <String>{});

  bool isLiked(String postId) => state.contains(postId);

  void toggleLike(String postId) {
    if (isClosed || postId.isEmpty) return;
    final likedPostIds = Set<String>.of(state);
    if (!likedPostIds.remove(postId)) likedPostIds.add(postId);
    emit(Set<String>.unmodifiable(likedPostIds));
  }
}
