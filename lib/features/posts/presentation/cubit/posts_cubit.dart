import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../../domain/models/post_media_changes.dart';
import '../../domain/posts_repository.dart';
import 'posts_state.dart';

export 'posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  PostsCubit(this.repository) : super(const PostsState());
  final PostsRepository repository;
  Future<void>? _loading;
  Future<void> load() => state.isBusy
      ? Future.value()
      : _loading ??= _load().whenComplete(() => _loading = null);
  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final saved = await repository.load();
      if (!isClosed) {
        emit(
          state.copyWith(
            posts: List.unmodifiable(saved),
            isLoading: false,
            loadFailed: false,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isLoading: false, loadFailed: true));
    }
  }

  Future<PostItem?> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) => _persist(
    () => repository.publish(draft, List.unmodifiable(attachments)),
    publishing: true,
  );
  Future<PostItem?> update(
    String postId,
    PostDraft draft, {
    PostMediaChanges? mediaChanges,
  }) => _persist(
    () => repository.update(postId, draft, mediaChanges: mediaChanges),
    publishing: false,
  );

  Future<PostItem?> _persist(
    Future<PostItem> Function() operation, {
    required bool publishing,
  }) async {
    if (state.isBusy) return null;
    final loading = _loading;
    emit(state.copyWith(isPublishing: true, clearPublishError: true));
    if (loading != null) await loading;
    if (isClosed) return null;
    try {
      final post = await operation();
      if (isClosed) return post;
      emit(
        state.copyWith(
          posts: List.unmodifiable(
            publishing
                ? [post, ...state.posts.where((item) => item.id != post.id)]
                : [
                    for (final item in state.posts)
                      if (item.id == post.id) post else item,
                  ],
          ),
          isPublishing: false,
          lastPublished: publishing || state.lastPublished?.id == post.id
              ? post
              : state.lastPublished,
        ),
      );
      return post;
    } catch (error, stackTrace) {
      _logFailure(error, stackTrace);
      if (!isClosed) {
        emit(
          state.copyWith(
            isPublishing: false,
            publishError: error is PostPublishException
                ? error.message
                : !publishing
                ? ProfilePostStrings.saveFailed
                : error is MissingPluginException
                ? AppStrings.storagePluginUnavailable
                : error is PlatformException
                ? AppStrings.mediaExportFailed
                : AppStrings.savePostFailed,
          ),
        );
      }
      return null;
    }
  }

  void clearDeleteError() {
    if (state.deleteError != null) emit(state.copyWith(clearDeleteError: true));
  }

  Future<bool> delete(String postId) async {
    if (state.isBusy) return false;
    final loading = _loading;
    emit(state.copyWith(deletingPostId: postId, clearDeleteError: true));
    if (loading != null) await loading;
    if (isClosed) return false;
    try {
      await repository.delete(postId);
      if (isClosed) return true;
      emit(
        state.copyWith(
          posts: List.unmodifiable(
            state.posts.where((item) => item.id != postId),
          ),
          clearDeletingPostId: true,
          clearLastPublished: state.lastPublished?.id == postId,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      _logFailure(error, stackTrace);
      if (!isClosed) {
        emit(
          state.copyWith(
            clearDeletingPostId: true,
            deleteError: ProfilePostStrings.deleteFailed,
          ),
        );
      }
      return false;
    }
  }

  void _logFailure(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('Post operation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
