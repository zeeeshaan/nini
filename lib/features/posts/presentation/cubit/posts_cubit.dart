import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/posts/data/demo_posts.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PostsState {
  const PostsState({
    this.posts = demoPosts,
    this.isLoading = false,
    this.isPublishing = false,
    this.loadFailed = false,
    this.publishError,
    this.lastPublished,
  });
  final List<PostItem> posts;
  final bool isLoading, isPublishing, loadFailed;
  final String? publishError;
  final PostItem? lastPublished;
}

class PostsCubit extends Cubit<PostsState> {
  PostsCubit(this.repository) : super(const PostsState());
  final PostsRepository repository;
  Future<void>? _loading;
  Future<void> load() => state.isPublishing
      ? Future.value()
      : _loading ??= _load().whenComplete(() => _loading = null);
  Future<void> _load() async {
    emit(
      PostsState(
        posts: state.posts,
        isLoading: true,
        lastPublished: state.lastPublished,
      ),
    );
    try {
      final saved = await repository.load();
      if (isClosed) return;
      emit(
        PostsState(
          posts: List.unmodifiable([...saved, ...demoPosts]),
          isPublishing: state.isPublishing,
          lastPublished: state.lastPublished,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          PostsState(
            posts: state.posts,
            loadFailed: true,
            isPublishing: state.isPublishing,
            lastPublished: state.lastPublished,
          ),
        );
      }
    }
  }

  Future<PostItem?> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) async {
    if (state.isPublishing) return null;
    // Mark busy before awaiting a startup load, so a rapid second tap cannot publish twice.
    final loading = _loading;
    emit(
      PostsState(
        posts: state.posts,
        isPublishing: true,
        loadFailed: state.loadFailed,
        lastPublished: state.lastPublished,
      ),
    );
    if (loading != null) await loading;
    if (isClosed) return null;
    emit(
      PostsState(
        posts: state.posts,
        isPublishing: true,
        loadFailed: state.loadFailed,
        lastPublished: state.lastPublished,
      ),
    );
    try {
      final post = await repository.publish(
        draft,
        List.unmodifiable(attachments),
      );
      if (isClosed) return post;
      emit(
        PostsState(
          posts: List.unmodifiable([
            post,
            ...state.posts.where((entry) => entry.id != post.id),
          ]),
          lastPublished: post,
          loadFailed: state.loadFailed,
        ),
      );
      return post;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Post publish failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!isClosed) {
        emit(
          PostsState(
            posts: state.posts,
            loadFailed: state.loadFailed,
            lastPublished: state.lastPublished,
            publishError: error is PostPublishException
                ? error.message
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
}
