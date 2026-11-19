import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';

class PostDetailState {
  const PostDetailState({
    this.imageIndex = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.quantity = 100,
    this.bookmarkAction = 0,
    this.backendPost,
    this.loadingDetail = false,
    this.detailError = false,
  });

  final int imageIndex;
  final bool isLiked;
  final bool isBookmarked;
  final int bookmarkAction;

  /// Hundredths of a unit, matching the Cart quantity format.
  final int quantity;
  final PostItem? backendPost;
  final bool loadingDetail, detailError;

  PostDetailState copyWith({
    int? imageIndex,
    bool? isLiked,
    bool? isBookmarked,
    int? quantity,
    int? bookmarkAction,
    PostItem? backendPost,
    bool? loadingDetail,
    bool? detailError,
  }) {
    return PostDetailState(
      imageIndex: imageIndex ?? this.imageIndex,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      quantity: quantity ?? this.quantity,
      bookmarkAction: bookmarkAction ?? this.bookmarkAction,
      backendPost: backendPost ?? this.backendPost,
      loadingDetail: loadingDetail ?? this.loadingDetail,
      detailError: detailError ?? this.detailError,
    );
  }
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit({
    String? postId,
    PostLikesCubit? likes,
    SavedPostsCubit? savedPosts,
  }) : _postId = postId,
       _likes = likes,
       _savedPosts = savedPosts,
       super(
         PostDetailState(
           isLiked: postId != null && likes?.isLiked(postId) == true,
           isBookmarked: postId != null && savedPosts?.isSaved(postId) == true,
         ),
       ) {
    if (postId != null && likes != null) {
      _likesSubscription = likes.stream.listen((likedPostIds) {
        final isLiked = likedPostIds.contains(postId);
        if (!isClosed && isLiked != state.isLiked) {
          emit(state.copyWith(isLiked: isLiked));
        }
      });
    }
    if (postId != null && savedPosts != null) {
      _savedSubscription = savedPosts.stream.listen((saved) {
        final bookmarked = saved.isSaved(postId);
        if (!isClosed && bookmarked != state.isBookmarked) {
          emit(
            state.copyWith(
              isBookmarked: bookmarked,
              bookmarkAction: saved.actionPostId == postId
                  ? state.bookmarkAction + 1
                  : state.bookmarkAction,
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
  int _detailRevision = 0;

  Future<void> loadDetail(ApiPostsRepository repository, String id) async {
    final revision = ++_detailRevision;
    emit(state.copyWith(loadingDetail: true, detailError: false));
    try {
      final post = await repository.loadDetail(id);
      if (!isClosed && revision == _detailRevision)
        emit(state.copyWith(backendPost: post, loadingDetail: false));
    } catch (_) {
      if (!isClosed && revision == _detailRevision)
        emit(state.copyWith(loadingDetail: false, detailError: true));
    }
  }

  void selectQuantity(int quantity) {
    if (quantity < 0 || quantity == state.quantity) return;
    emit(state.copyWith(quantity: quantity));
  }

  void changeImage(int index) {
    if (index < 0 || state.imageIndex == index) return;

    emit(state.copyWith(imageIndex: index));
  }

  void toggleLike() {
    if (_likes != null && _postId != null) {
      _likes.toggleLike(_postId);
      return;
    }
    emit(state.copyWith(isLiked: !state.isLiked));
  }

  Future<bool> toggleBookmark({PostItem? post, PostSeller? seller}) async {
    if (_savedPosts != null && _postId != null) {
      if (post == null || post.id != _postId) return false;
      return _savedPosts.toggle(post, seller: seller);
    }
    emit(
      state.copyWith(
        isBookmarked: !state.isBookmarked,
        bookmarkAction: state.bookmarkAction + 1,
      ),
    );
    return true;
  }

  @override
  Future<void> close() async {
    _detailRevision++;
    await _likesSubscription?.cancel();
    await _savedSubscription?.cancel();
    await super.close();
  }
}
