import 'dart:async';

import 'package:dio/dio.dart';

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
    this.likeCount,
    this.isBookmarked = false,
    this.quantity = 100,
    this.bookmarkAction = 0,
    this.backendPost,
    this.loadingDetail = false,
    this.detailError = false,
    this.comments = const [],
    this.commentsPage = 0,
    this.commentsTotal = 0,
    this.commentsLoading = false,
    this.commentsError = false,
    this.commentSubmitting = false,
    this.commentMutationError,
    this.commentCount,
  });

  final int imageIndex;
  final bool isLiked;
  final int? likeCount;
  final bool isBookmarked;
  final int bookmarkAction;

  /// Hundredths of a unit, matching the Cart quantity format.
  final int quantity;
  final PostItem? backendPost;
  final bool loadingDetail, detailError;
  final List<PostComment> comments;
  final int commentsPage, commentsTotal;
  final bool commentsLoading, commentsError, commentSubmitting;
  final String? commentMutationError;
  final int? commentCount;

  PostDetailState copyWith({
    int? imageIndex,
    bool? isLiked,
    int? likeCount,
    bool? isBookmarked,
    int? quantity,
    int? bookmarkAction,
    PostItem? backendPost,
    bool? loadingDetail,
    bool? detailError,
    List<PostComment>? comments,
    int? commentsPage,
    int? commentsTotal,
    bool? commentsLoading,
    bool? commentsError,
    bool? commentSubmitting,
    String? commentMutationError,
    int? commentCount,
  }) {
    return PostDetailState(
      imageIndex: imageIndex ?? this.imageIndex,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      quantity: quantity ?? this.quantity,
      bookmarkAction: bookmarkAction ?? this.bookmarkAction,
      backendPost: backendPost ?? this.backendPost,
      loadingDetail: loadingDetail ?? this.loadingDetail,
      detailError: detailError ?? this.detailError,
      comments: comments ?? this.comments,
      commentsPage: commentsPage ?? this.commentsPage,
      commentsTotal: commentsTotal ?? this.commentsTotal,
      commentsLoading: commentsLoading ?? this.commentsLoading,
      commentsError: commentsError ?? this.commentsError,
      commentSubmitting: commentSubmitting ?? this.commentSubmitting,
      commentMutationError: commentMutationError,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit({
    String? postId,
    PostLikesCubit? likes,
    SavedPostsCubit? savedPosts,
    PostItem? post,
    ApiPostsRepository? repository,
  }) : _postId = postId,
       _backend = post?.metadata['backend'] == true,
       _repository = repository,
       _likes = likes,
       _savedPosts = savedPosts,
       super(
         PostDetailState(
           isLiked: postId != null && likes?.isLiked(postId) == true,
           isBookmarked: postId != null && savedPosts?.isSaved(postId) == true,
           commentCount:
               (postId == null ? null : repository?.commentCountFor(postId)) ??
               (post?.metadata['commentsCount'] is int
                   ? post!.metadata['commentsCount'] as int
                   : null),
         ),
       ) {
    if (post != null && post.metadata['backend'] == true) {
      likes?.seed(post);
      savedPosts?.seed(post);
      final value = postId == null ? null : likes?.backendState(postId);
      if (value != null) {
        emit(state.copyWith(isLiked: value.liked, likeCount: value.count));
      }
      if (postId != null && savedPosts != null) {
        emit(state.copyWith(isBookmarked: savedPosts.isSaved(postId)));
      }
    }
    if (_backend && repository != null && postId != null) {
      _commentCountSubscription = repository.commentCounts.listen((update) {
        if (!isClosed && update.postId == postId) {
          emit(state.copyWith(commentCount: update.count));
        }
      });
    }
    if (postId != null && likes != null) {
      _likesSubscription = likes.stream.listen((likedPostIds) {
        final value = _backend ? likes.backendState(postId) : null;
        final isLiked = _backend
            ? value?.liked ?? false
            : likedPostIds.contains(postId);
        if (!isClosed &&
            (isLiked != state.isLiked || value?.count != state.likeCount)) {
          emit(state.copyWith(isLiked: isLiked, likeCount: value?.count));
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
  final bool _backend;
  final ApiPostsRepository? _repository;
  StreamSubscription<({String postId, int count})>? _commentCountSubscription;
  int _commentsRevision = 0;
  bool _commentOutcomeUnknown = false;
  final _uncertainDeletes = <String>{};
  final PostLikesCubit? _likes;
  final SavedPostsCubit? _savedPosts;
  StreamSubscription<Set<String>>? _likesSubscription;
  StreamSubscription<SavedPostsState>? _savedSubscription;
  StreamSubscription<String>? _deletionSubscription;
  String? _detailId;
  int _detailRevision = 0;

  Future<void> loadDetail(ApiPostsRepository repository, String id) async {
    _detailId = id;
    _deletionSubscription ??= repository.deletedPosts.listen((deletedId) {
      if (deletedId == _detailId && !isClosed) {
        _detailRevision++;
        emit(state.copyWith(loadingDetail: false, detailError: true));
      }
    });
    final revision = ++_detailRevision;
    emit(state.copyWith(loadingDetail: true, detailError: false));
    try {
      final post = await repository.loadDetail(id);
      if (!isClosed && revision == _detailRevision) {
        _likes?.seed(post);
        _savedPosts?.seed(post);
        emit(
          state.copyWith(
            backendPost: post,
            loadingDetail: false,
            commentCount:
                repository.commentCountFor(id) ??
                (post.metadata['commentsCount'] is int
                    ? post.metadata['commentsCount'] as int
                    : null),
          ),
        );
      }
    } catch (_) {
      if (!isClosed && revision == _detailRevision)
        emit(state.copyWith(loadingDetail: false, detailError: true));
    }
  }

  Future<void> loadComments({bool next = false}) async {
    final repo = _repository, id = _postId;
    if (!_backend ||
        repo == null ||
        id == null ||
        isClosed ||
        state.commentsLoading ||
        (next &&
            (state.commentsPage == 0 ||
                state.commentsPage * 20 >= state.commentsTotal))) {
      return;
    }
    final revision = ++_commentsRevision;
    final previous = state.comments;
    emit(state.copyWith(commentsLoading: true, commentsError: false));
    try {
      final result = await repo.loadComments(
        id,
        page: next ? state.commentsPage + 1 : 1,
      );
      if (isClosed ||
          revision != _commentsRevision ||
          !repo.isCurrentAccount()) {
        return;
      }
      final seen = <String>{};
      final items = [
        for (final item in [if (next) ...previous, ...result.items])
          if (seen.add(item.id)) item,
      ];
      emit(
        state.copyWith(
          comments: List.unmodifiable(items),
          commentsPage: result.page,
          commentsTotal: result.total,
          commentsLoading: false,
        ),
      );
    } catch (_) {
      if (!isClosed &&
          revision == _commentsRevision &&
          repo.isCurrentAccount()) {
        emit(state.copyWith(commentsLoading: false, commentsError: true));
      }
    }
  }

  Future<bool> submitComment(String text, {String? parentId}) async {
    final repo = _repository, id = _postId;
    if (!_backend ||
        repo == null ||
        id == null ||
        isClosed ||
        state.commentSubmitting ||
        _commentOutcomeUnknown) {
      return false;
    }
    emit(state.copyWith(commentSubmitting: true));
    try {
      final comment = await repo.createComment(id, text, parentId: parentId);
      if (isClosed || !repo.isCurrentAccount()) return false;
      if (parentId == null) {
        _commentsRevision++;
        emit(
          state.copyWith(
            comments: [
              comment,
              ...state.comments.where((c) => c.id != comment.id),
            ],
            commentSubmitting: false,
            commentsLoading: false,
            commentsTotal: state.commentsTotal + 1,
          ),
        );
      } else {
        emit(state.copyWith(commentSubmitting: false));
      }
      unawaited(_refreshCommentCount(repo, id));
      return true;
    } catch (error) {
      if (isClosed || !repo.isCurrentAccount()) return false;
      final status = error is DioException ? error.response?.statusCode : null;
      final uncertain =
          error is! DioException && error is! PostApiException ||
          error is DioException &&
              (status == null || status == 408 || status >= 500);
      if (uncertain) _commentOutcomeUnknown = true;
      emit(
        state.copyWith(
          commentSubmitting: false,
          commentMutationError: uncertain
              ? 'Comment could not be confirmed. Check comments before retrying.'
              : 'Unable to post comment.',
        ),
      );
      if (uncertain) unawaited(loadComments());
      return false;
    }
  }

  Future<bool> deleteComment(PostComment comment) async {
    final repo = _repository, id = _postId;
    if (repo == null ||
        id == null ||
        comment.postId != id ||
        !comment.canDelete ||
        state.commentSubmitting ||
        _uncertainDeletes.contains(comment.id)) {
      return false;
    }
    emit(state.copyWith(commentSubmitting: true));
    try {
      final count = await repo.deleteComment(comment);
      if (isClosed || !repo.isCurrentAccount()) return false;
      _commentsRevision++;
      emit(
        state.copyWith(
          comments: state.comments.where((c) => c.id != comment.id).toList(),
          commentSubmitting: false,
          commentsLoading: false,
          commentCount: count,
        ),
      );
      if (count != null) {
        repo.publishCommentCount(id, count);
      } else {
        unawaited(_refreshCommentCount(repo, id));
      }
      return true;
    } catch (error) {
      if (isClosed || !repo.isCurrentAccount()) return false;
      final status = error is DioException ? error.response?.statusCode : null;
      if (error is! DioException ||
          status == null ||
          status == 408 ||
          status >= 500) {
        _uncertainDeletes.add(comment.id);
      }
      emit(
        state.copyWith(
          commentSubmitting: false,
          commentMutationError: 'Unable to confirm comment deletion.',
        ),
      );
      return false;
    }
  }

  Future<void> _refreshCommentCount(ApiPostsRepository repo, String id) async {
    try {
      await repo.refreshCommentCount(id);
    } catch (_) {
      /* Retain the last confirmed count. */
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

  Future<bool> toggleLike() async {
    if (_backend) {
      if (_likes == null || _postId == null) return false;
      return _likes.toggleBackend(_postId);
    }
    if (_likes != null && _postId != null) {
      _likes.toggleLike(_postId);
      return true;
    }
    emit(state.copyWith(isLiked: !state.isLiked));
    return true;
  }

  Future<bool> toggleBookmark({PostItem? post, PostSeller? seller}) async {
    if (_backend && _savedPosts == null) return false;
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
    _commentsRevision++;
    await _commentCountSubscription?.cancel();
    await _likesSubscription?.cancel();
    await _savedSubscription?.cancel();
    await _deletionSubscription?.cancel();
    await super.close();
  }
}
