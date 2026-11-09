import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class HomeCardState {
  const HomeCardState({
    this.liked = false,
    this.bookmarked = false,
    this.imageAttempt = 0,
  });
  final bool liked, bookmarked;
  final int imageAttempt;
}

class HomeCardCubit extends Cubit<HomeCardState> {
  HomeCardCubit({
    String? postId,
    PostLikesCubit? likes,
    SavedPostsCubit? savedPosts,
  }) : _postId = postId,
       _likes = likes,
       _savedPosts = savedPosts,
       super(
         HomeCardState(
           liked: postId != null && likes?.isLiked(postId) == true,
           bookmarked: postId != null && savedPosts?.isSaved(postId) == true,
         ),
       ) {
    if (postId != null && likes != null) {
      _likesSubscription = likes.stream.listen((likedPostIds) {
        final liked = likedPostIds.contains(postId);
        if (!isClosed && liked != state.liked) {
          emit(
            HomeCardState(
              liked: liked,
              bookmarked: state.bookmarked,
              imageAttempt: state.imageAttempt,
            ),
          );
        }
      });
    }
    if (postId != null && savedPosts != null) {
      _savedSubscription = savedPosts.stream.listen((saved) {
        final bookmarked = saved.isSaved(postId);
        if (!isClosed && bookmarked != state.bookmarked) {
          emit(
            HomeCardState(
              liked: state.liked,
              bookmarked: bookmarked,
              imageAttempt: state.imageAttempt,
            ),
          );
        }
      });
    }
  }

  final String? _postId;
  final PostLikesCubit? _likes;
  final SavedPostsCubit? _savedPosts;
  StreamSubscription<Set<String>>? _likesSubscription;
  StreamSubscription<SavedPostsState>? _savedSubscription;

  void toggleLike() {
    if (_likes != null && _postId != null) {
      _likes.toggleLike(_postId);
      return;
    }
    emit(
      HomeCardState(
        liked: !state.liked,
        bookmarked: state.bookmarked,
        imageAttempt: state.imageAttempt,
      ),
    );
  }

  Future<bool> toggleBookmark({PostItem? post, PostSeller? seller}) async {
    if (_savedPosts != null && _postId != null) {
      if (post == null || post.id != _postId) return false;
      return _savedPosts.toggle(post, seller: seller);
    }
    emit(
      HomeCardState(
        liked: state.liked,
        bookmarked: !state.bookmarked,
        imageAttempt: state.imageAttempt,
      ),
    );
    return true;
  }

  void retryImage() => emit(
    HomeCardState(
      liked: state.liked,
      bookmarked: state.bookmarked,
      imageAttempt: state.imageAttempt + 1,
    ),
  );

  @override
  Future<void> close() async {
    await _likesSubscription?.cancel();
    await _savedSubscription?.cancel();
    await super.close();
  }
}
