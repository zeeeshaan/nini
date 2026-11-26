import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';

import '../../data/api_public_profile_repository.dart';
import '../../domain/public_user_profile.dart';

import 'package:hywork/features/posts/domain/models/profile_category.dart';

class FollowListState {
  const FollowListState({
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.limit = 20,
    this.loading = false,
    this.loaded = false,
    this.error = false,
  });
  final List<
    ({PublicUserProfile profile, bool? verified, DateTime? followedAt})
  >
  items;
  final int total, page, limit;
  final bool loading, loaded, error;
  bool get hasMore => page * limit < total;
}

class SellerProfileState {
  const SellerProfileState({
    this.profile,
    this.loading = false,
    this.error,
    this.canRetry = true,
    this.categories,
    this.categoriesLoading = false,
    this.categoriesError,
    this.following = false,
    this.followError,
    this.blocking = false,
    this.blockError,
    this.followers = const FollowListState(),
    this.followedUsers = const FollowListState(),
    this.posts = const BackendPostsState(),
    this.selectedCategoryId,
  });
  final PublicUserProfile? profile;
  final bool loading, canRetry;
  final String? error;
  final ProfileCategoryList? categories;
  final bool categoriesLoading;
  final String? categoriesError;
  final bool following;
  final String? followError;
  final bool blocking;
  final String? blockError;
  final FollowListState followers, followedUsers;
  final BackendPostsState posts;
  final String? selectedCategoryId;

  SellerProfileState copyWith({
    PublicUserProfile? profile,
    bool? following,
    String? followError,
    bool? blocking,
    String? blockError,
    FollowListState? followers,
    FollowListState? followedUsers,
    BackendPostsState? posts,
  }) => SellerProfileState(
    profile: profile ?? this.profile,
    loading: loading,
    error: error,
    canRetry: canRetry,
    categories: categories,
    categoriesLoading: categoriesLoading,
    categoriesError: categoriesError,
    following: following ?? this.following,
    followError: followError,
    blocking: blocking ?? this.blocking,
    blockError: blockError,
    followers: followers ?? this.followers,
    followedUsers: followedUsers ?? this.followedUsers,
    posts: posts ?? this.posts,
    selectedCategoryId: selectedCategoryId,
  );
}

class SellerProfileCubit extends Cubit<SellerProfileState> {
  SellerProfileCubit(this._repository) : super(const SellerProfileState());
  final ApiPublicProfileRepository _repository;
  int _request = 0;
  String? _key;
  Future<void>? _pending;
  final _uncertainFollows = <String>{};
  int _followersRevision = 0, _followingRevision = 0;
  int _postsRevision = 0;

  void selectCategory(String? id) {
    if (id == state.selectedCategoryId ||
        (id != null && !ProfileCategory.isBackendId(id))) {
      return;
    }
    _postsRevision++;
    emit(
      SellerProfileState(
        profile: state.profile,
        categories: state.categories,
        categoriesLoading: state.categoriesLoading,
        categoriesError: state.categoriesError,
        following: state.following,
        followError: state.followError,
        followers: state.followers,
        followedUsers: state.followedUsers,
        selectedCategoryId: id,
      ),
    );
    unawaited(loadPosts());
  }

  Future<void> loadPosts({bool next = false}) async {
    final profile = state.profile;
    final old = state.posts;
    if (isClosed ||
        profile == null ||
        old.loading ||
        (next && (old.page == 0 || !old.hasMore))) {
      return;
    }
    final request = _request, revision = ++_postsRevision;
    final category = state.selectedCategoryId;
    emit(
      state.copyWith(
        posts: BackendPostsState(
          posts: old.posts,
          page: old.page,
          hasMore: old.hasMore,
          loading: true,
        ),
      ),
    );
    try {
      final result = await _repository.loadPosts(
        profile.seller.id,
        categoryId: category,
        page: next ? old.page + 1 : 1,
      );
      if (isClosed ||
          request != _request ||
          revision != _postsRevision ||
          state.profile?.seller.id != profile.seller.id) {
        return;
      }
      final seen = <String>{};
      final items = [
        for (final post in [if (next) ...old.posts, ...result.items])
          if (seen.add(post.id)) post,
      ];
      emit(
        state.copyWith(
          posts: BackendPostsState(
            posts: List.unmodifiable(items),
            page: result.page,
            hasMore: result.page * result.limit < result.total,
          ),
        ),
      );
    } catch (_) {
      if (isClosed || request != _request || revision != _postsRevision) return;
      emit(
        state.copyWith(
          posts: BackendPostsState(
            posts: old.posts,
            page: old.page,
            hasMore: old.hasMore,
            error: true,
            failedRefresh: !next,
          ),
        ),
      );
    }
  }

  Future<void> loadFollowers({bool next = false}) =>
      _loadPeople(true, next: next);
  Future<void> loadFollowing({bool next = false}) =>
      _loadPeople(false, next: next);

  Future<void> _loadPeople(bool followers, {required bool next}) async {
    final profile = state.profile;
    if (isClosed || profile == null) return;
    final old = followers ? state.followers : state.followedUsers;
    if (old.loading || (next && (!old.loaded || !old.hasMore))) return;
    final revision = followers ? ++_followersRevision : ++_followingRevision;
    final profileRevision = _request;
    final page = next ? old.page + 1 : 1;
    void publish(FollowListState value) {
      emit(
        followers
            ? state.copyWith(followers: value)
            : state.copyWith(followedUsers: value),
      );
    }

    publish(
      FollowListState(
        items: old.items,
        total: old.total,
        page: old.page,
        limit: old.limit,
        loaded: old.loaded,
        loading: true,
      ),
    );
    bool current() =>
        !isClosed &&
        profileRevision == _request &&
        state.profile?.seller.id == profile.seller.id &&
        revision == (followers ? _followersRevision : _followingRevision);
    try {
      final result = followers
          ? await _repository.loadFollowers(
              profile.seller.id,
              page: page,
              limit: old.limit,
            )
          : await _repository.loadFollowing(
              profile.seller.id,
              page: page,
              limit: old.limit,
            );
      if (!current()) return;
      publish(
        FollowListState(
          items: List.unmodifiable([if (next) ...old.items, ...result.items]),
          total: result.total,
          page: result.page,
          limit: result.limit,
          loaded: true,
        ),
      );
    } catch (_) {
      if (!current()) return;
      publish(
        FollowListState(
          items: old.items,
          total: old.total,
          page: old.page,
          limit: old.limit,
          loaded: old.loaded,
          error: true,
        ),
      );
    }
  }

  void _refreshFollowersAfterMutation() {
    final old = state.followers;
    if (!old.loaded && !old.loading) return;
    _followersRevision++;
    emit(
      state.copyWith(
        followers: FollowListState(
          items: old.items,
          total: old.total,
          page: old.page,
          limit: old.limit,
          loaded: old.loaded,
        ),
      ),
    );
    unawaited(loadFollowers());
  }

  Future<void> follow({
    required String? accountId,
    required bool Function() isCurrentAccount,
  }) => _changeFollow(
    true,
    accountId: accountId,
    isCurrentAccount: isCurrentAccount,
  );

  Future<void> unfollow({
    required String? accountId,
    required bool Function() isCurrentAccount,
  }) => _changeFollow(
    false,
    accountId: accountId,
    isCurrentAccount: isCurrentAccount,
  );

  Future<void> block({
    required String currentUserId,
    required bool Function() isCurrentAccount,
  }) => _changeBlock(
    true,
    currentUserId: currentUserId,
    isCurrentAccount: isCurrentAccount,
  );

  Future<void> unblock({
    required String currentUserId,
    required bool Function() isCurrentAccount,
  }) => _changeBlock(
    false,
    currentUserId: currentUserId,
    isCurrentAccount: isCurrentAccount,
  );

  Future<void> _changeBlock(
    bool blocked, {
    required String currentUserId,
    required bool Function() isCurrentAccount,
  }) async {
    final profile = state.profile;
    if (isClosed ||
        profile == null ||
        state.blocking ||
        state.following ||
        profile.isBlocked == blocked) {
      return;
    }
    if (currentUserId.isEmpty || !isCurrentAccount()) {
      emit(state.copyWith(blockError: ProfileScreenStrings.signInRequired));
      return;
    }
    if (profile.isMe == true || profile.seller.id == currentUserId) {
      emit(state.copyWith(blockError: ProfileScreenStrings.cannotBlockSelf));
      return;
    }
    final revision = _request;
    bool current() =>
        !isClosed &&
        revision == _request &&
        isCurrentAccount() &&
        state.profile?.seller.id == profile.seller.id;
    emit(state.copyWith(blocking: true));
    try {
      if (blocked) {
        await _repository.block(
          profile.seller.id,
          currentUserId: currentUserId,
          isCurrentAccount: current,
        );
      } else {
        await _repository.unblock(profile.seller.id, isCurrentAccount: current);
      }
      if (!current()) return;
      emit(
        state.copyWith(
          blocking: false,
          profile: profile.copyWith(isBlocked: blocked),
        ),
      );
    } catch (error) {
      if (!current()) return;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(
        state.copyWith(
          blocking: false,
          blockError: error is FormatException
              ? error.message
              : status == 401
              ? ProfileScreenStrings.signInRequired
              : status == 403
              ? ProfileScreenStrings.cannotUpdateBlock
              : status == 404
              ? ProfileScreenStrings.userUnavailable
              : ProfileScreenStrings.blockUpdateFailed,
        ),
      );
    }
  }

  Future<void> _changeFollow(
    bool desired, {
    required String? accountId,
    required bool Function() isCurrentAccount,
  }) async {
    final profile = state.profile;
    if (isClosed ||
        profile == null ||
        state.following ||
        state.blocking ||
        profile.isFollowing == desired) {
      return;
    }
    if (accountId == null || accountId.isEmpty || !isCurrentAccount()) {
      emit(state.copyWith(followError: ProfileScreenStrings.signInToFollow));
      return;
    }
    if (profile.isMe == true || profile.seller.id == accountId) {
      emit(
        state.copyWith(followError: ProfileScreenStrings.cannotFollowSelf),
      );
      return;
    }
    if (profile.isFollowing == null ||
        _uncertainFollows.contains(profile.seller.id)) {
      emit(
        state.copyWith(
          followError: ProfileScreenStrings.followStatusUnconfirmed,
        ),
      );
      return;
    }
    final revision = _request;
    bool current() =>
        !isClosed &&
        revision == _request &&
        isCurrentAccount() &&
        state.profile?.seller.id == profile.seller.id;
    emit(state.copyWith(following: true));
    try {
      PublicUserProfile updated;
      if (desired) {
        updated = await _repository.follow(profile, isCurrentAccount: current);
      } else {
        await _repository.unfollow(profile, isCurrentAccount: current);
        updated = PublicUserProfile(
          seller: profile.seller,
          followingCount: profile.followingCount,
          postsCount: profile.postsCount,
          isMe: profile.isMe,
          isFollowing: false,
        );
      }
      if (updated.followersCount == null && current()) {
        try {
          final refreshed = await _repository.load(
            profile.seller.username,
            expectedUserId: profile.seller.id,
          );
          if (refreshed.isFollowing == desired) updated = refreshed;
        } catch (_) {
          // Keep the confirmed relationship when a count refresh is unavailable.
        }
      }
      if (current()) {
        emit(state.copyWith(profile: updated, following: false));
        _refreshFollowersAfterMutation();
      }
    } catch (error) {
      if (!current()) return;
      final status = error is DioException ? error.response?.statusCode : null;
      final uncertain =
          error is! DioException ||
          status == null ||
          status == 408 ||
          status >= 500;
      if (uncertain) {
        _uncertainFollows.add(profile.seller.id);
        try {
          final refreshed = await _repository.load(
            profile.seller.username,
            expectedUserId: profile.seller.id,
          );
          if (!current()) return;
          if (refreshed.isFollowing == desired) {
            _uncertainFollows.remove(profile.seller.id);
            emit(state.copyWith(profile: refreshed, following: false));
            _refreshFollowersAfterMutation();
            return;
          }
        } catch (_) {
          /* An unavailable read cannot confirm a mutation. */
        }
      }
      if (current()) {
        emit(
          state.copyWith(
            following: false,
            followError: uncertain
                ? ProfileScreenStrings.followStatusCheckProfile
                : status == 403
                ? ProfileScreenStrings.cannotFollowUser
                : status == 401
                ? ProfileScreenStrings.signInToFollow
                : ProfileScreenStrings.followUpdateFailed,
          ),
        );
      }
    }
  }

  Future<void> load(String username, {String? expectedUserId}) {
    if (isClosed) return Future.value();
    final key =
        '${PublicUserProfile.normalizeUsername(username)}:$expectedUserId';
    if (key == _key && _pending != null) return _pending!;
    _key = key;
    final request = ++_request;
    emit(const SellerProfileState(loading: true));
    return _pending = _load(username, expectedUserId, request).whenComplete(() {
      if (request == _request) _pending = null;
    });
  }

  Future<void> _load(String username, String? id, int request) async {
    if (PublicUserProfile.normalizeUsername(username) == null) {
      emit(
        const SellerProfileState(
          error: ProfilePostStrings.publicIdentityMissing,
          canRetry: false,
        ),
      );
      return;
    }
    try {
      final profile = await _repository.load(username, expectedUserId: id);
      if (!isClosed && request == _request) {
        emit(SellerProfileState(profile: profile, categoriesLoading: true));
        unawaited(loadPosts());
        await _loadCategories(profile, request);
      }
    } catch (error) {
      if (isClosed || request != _request) return;
      final status = error is DioException ? error.response?.statusCode : null;
      emit(SellerProfileState(error: _message(error), canRetry: status != 404));
    }
  }

  Future<void> _loadCategories(PublicUserProfile profile, int request) async {
    if (isClosed || request != _request) return;
    try {
      final categories = await _repository.loadCategories(profile.seller.id);
      if (isClosed || request != _request) return;
      emit(
        SellerProfileState(
          profile: state.profile ?? profile,
          categories: categories,
          following: state.following,
          followError: state.followError,
          followers: state.followers,
          followedUsers: state.followedUsers,
          posts: state.posts,
          selectedCategoryId: state.selectedCategoryId,
        ),
      );
    } catch (_) {
      if (isClosed || request != _request) return;
      emit(
        SellerProfileState(
          profile: state.profile ?? profile,
          categoriesError: ProfilePostStrings.publicCategoriesFailed,
          following: state.following,
          followError: state.followError,
          followers: state.followers,
          followedUsers: state.followedUsers,
          posts: state.posts,
          selectedCategoryId: state.selectedCategoryId,
        ),
      );
    }
  }

  Future<void> retryCategories() {
    final profile = state.profile;
    if (isClosed || profile == null || state.categoriesLoading) {
      return Future.value();
    }
    final request = _request;
    emit(
      SellerProfileState(
        profile: profile,
        categoriesLoading: true,
        following: state.following,
        followers: state.followers,
        followedUsers: state.followedUsers,
        posts: state.posts,
        selectedCategoryId: state.selectedCategoryId,
      ),
    );
    return _loadCategories(profile, request);
  }

  String _message(Object error) {
    if (error is TimeoutException) return ProfilePostStrings.publicTimeout;
    if (error is! DioException) return ProfilePostStrings.publicLoadFailed;
    if (error.response?.statusCode == 404) {
      return ProfilePostStrings.publicUnavailable;
    }
    if (error.response?.statusCode == 401) {
      return ProfilePostStrings.publicSessionFailed;
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ProfilePostStrings.publicTimeout,
      DioExceptionType.connectionError =>
        ProfilePostStrings.publicConnectionFailed,
      _ => ProfilePostStrings.publicLoadFailed,
    };
  }

  void invalidate() {
    if (isClosed) return;
    _request++;
    _pending = null;
    emit(
      const SellerProfileState(error: ProfilePostStrings.publicSessionChanged),
    );
  }

  @override
  Future<void> close() {
    _request++;
    return super.close();
  }
}
