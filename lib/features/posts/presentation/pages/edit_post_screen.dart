import 'dart:async';

import 'package:nini/features/posts/presentation/cubit/post_editor_fields_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/presentation/cubit/post_operation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/helpers/post_caption_synchronizer.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/features/create_post/data/api_categories_repository.dart';
import 'package:nini/features/create_post/presentation/cubit/post_categories_cubit.dart';

import '../cubit/post_editor_media_cubit.dart';
import '../cubit/posts_cubit.dart';
import '../cubit/profile_categories_cubit.dart';
import '../helpers/confirm_discard_post_changes.dart';
import '../helpers/post_draft_mapper.dart';
import '../widgets/editor/edit_post_form.dart';
import '../widgets/editor/post_editor_actions.dart';

/// Loads the owner's canonical post before constructing the existing editor.
class BackendEditPostScreen extends StatefulWidget {
  const BackendEditPostScreen({super.key, required this.postId});
  final String postId;

  @override
  State<BackendEditPostScreen> createState() => _BackendEditPostScreenState();
}

class _BackendEditPostScreenState extends State<BackendEditPostScreen> {
  late final Future<MyServerPost> _post;

  @override
  void initState() {
    super.initState();
    _post = context.read<ApiPostsRepository>().loadEditablePost(widget.postId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MyServerPost>(
    future: _post,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('Unable to load this post for editing.'),
          ),
        );
      }
      try {
        final post = snapshot.data!;
        return EditPostScreen(
          post: backendPostFromJson(post.data),
          backendPost: post,
        );
      } catch (_) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('Unable to load this post for editing.'),
          ),
        );
      }
    },
  );
}

class EditPostScreen extends StatelessWidget {
  const EditPostScreen({super.key, required this.post, this.backendPost});
  final PostItem post;
  final MyServerPost? backendPost;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => CreatePostCubit(
          initial: backendPost == null
              ? postDraftFromPost(post)
              : postDraftFromBackend(post, backendPost!.data),
        ),
      ),
      BlocProvider(create: (_) => PostEditorMediaCubit(post.media)),
      BlocProvider(
        create: (_) => PostEditorFieldsCubit(
          backendPost == null
              ? postDraftFromPost(post)
              : postDraftFromBackend(post, backendPost!.data),
        ),
      ),
      if (backendPost != null)
        BlocProvider(
          create: (context) => PostCategoriesCubit(
            ApiCategoriesRepository(context.read<ApiPostsRepository>().client),
          )..load(),
        ),
    ],
    child: PersianFeature(
      child: _EditPostView(post: post, backendPost: backendPost),
    ),
  );
}

class _EditPostView extends StatefulWidget {
  const _EditPostView({required this.post, this.backendPost});
  final PostItem post;
  final MyServerPost? backendPost;
  @override
  State<_EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<_EditPostView> {
  final _form = GlobalKey<FormState>();
  late final quill.QuillController _caption;
  late final PostCaptionSynchronizer _synchronizer;
  final _operation = PostOperationCubit();
  late final PostDraft _initialDraft;
  final Set<String> _touched = {};
  bool _confirming = false;
  CreatePostCubit get _editor => context.read<CreatePostCubit>();

  @override
  void initState() {
    super.initState();
    final draft = _editor.state;
    _initialDraft = draft;
    _caption = quill.QuillController(
      document: draft.captionDelta.isEmpty
          ? (quill.Document()..insert(0, draft.caption))
          : quill.Document.fromJson(draft.captionDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    // Set the presentation before synchronization so opening the editor alone
    // does not mark the post dirty or discard its inline formatting.
    _caption.document.format(
      0,
      _caption.document.length,
      quill.Attribute.rightAlignment,
    );
    _caption.document.history.clear();
    _synchronizer = PostCaptionSynchronizer(
      controller: _caption,
      onChanged: (text, delta) {
        _editor.updateRichCaption(text, delta);
        _markDirty();
      },
    );
  }

  @override
  void dispose() {
    _operation.close();
    _synchronizer.dispose();
    _caption.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_operation.state.dirty && mounted) _operation.markDirty();
  }

  Future<void> _close([PostItem? result]) async {
    _operation.allowPop();
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _cancel() async {
    if (_operation.state.saving || _confirming) return;
    _confirming = true;
    final discard =
        !_operation.state.dirty || await confirmDiscardPostChanges(context);
    _confirming = false;
    if (mounted && discard) await _close();
  }

  Future<void> _save() async {
    if (_operation.state.saving) return;
    if (widget.backendPost != null) {
      await _saveBackend();
      return;
    }
    final categories = context.read<ProfileCategoriesCubit>();
    if (categories.state.loading || categories.state.loadFailed) {
      _operation.showError(ProfilePostStrings.loadFailed);
      return;
    }
    _synchronizer.flush();
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    _editor.selectProfileCategory(
      categories.state.find(_editor.state.profileCategoryId)?.id,
    );
    FocusScope.of(context).unfocus();
    _operation.beginSave();
    final posts = context.read<PostsCubit>();
    final updated = await posts.update(
      widget.post.id,
      _editor.state,
      mediaChanges: context.read<PostEditorMediaCubit>().state.changes,
    );
    if (!mounted) return;
    if (updated != null) {
      categories.select(updated.profileCategoryId);
      await _close(updated);
    } else {
      _operation.fail(
        posts.state.publishError ?? ProfilePostStrings.saveFailed,
      );
    }
  }

  Future<void> _saveBackend() async {
    _synchronizer.flush();
    FocusScope.of(context).unfocus();
    _operation.beginSave();
    final repository = context.read<ApiPostsRepository>();
    try {
      _form.currentState!.save();
      final original = widget.backendPost!;
      final result = await repository.updateEditablePost(
        original,
        _editor.state,
        initialDraft: _initialDraft,
        touched: _touched,
        mediaChanges: context.read<PostEditorMediaCubit>().state.changes,
        initialMediaPaths: [for (final media in widget.post.media) media.path],
      );
      if (!mounted) return;
      if (!identical(result, original)) {
        final feed = context.read<FeedCubit?>();
        final own = context.read<OwnPostsCubit?>();
        if (result.status != 'published') {
          feed?.removePost(result.id);
          own?.removePost(result.id);
        }
        if (feed != null) unawaited(feed.refreshFromServer());
        if (own != null) unawaited(own.refresh());
        AppToast.success(
          context,
          result.status == 'pending_review'
              ? 'Saved and sent for review.'
              : 'Post changes saved.',
        );
      }
      await _close(backendPostFromJson(result.data));
    } catch (error) {
      if (mounted) {
        _operation.fail(
          error is PostApiException
              ? error.message
              : ProfilePostStrings.saveFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostOperationCubit, PostOperationState>(
        bloc: _operation,
        builder: (context, state) => PopScope(
          canPop:
              _operation.state.allowPop ||
              (!_operation.state.dirty && !_operation.state.saving),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cancel();
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ProfilePostStrings.editPost,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),

              actions: [
                IconButton(
                  tooltip: ProfilePostStrings.back,
                  onPressed: _operation.state.saving ? null : _cancel,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      if (_operation.state.saving)
                        const LinearProgressIndicator(minHeight: 2),
                      if (_operation.state.error != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _operation.state.error!,
                            style: AppTextStyles.inherit.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: _operation.state.saving,
                          child: EditPostForm(
                            formKey: _form,
                            captionController: _caption,
                            onChanged: _markDirty,
                            backend: widget.backendPost != null,
                            backendData: widget.backendPost?.data,
                            onTouched: widget.backendPost == null
                                ? null
                                : _touched.add,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: PostEditorActions(
              saving: _operation.state.saving,
              onCancel: _cancel,
              onSave: _save,
            ),
          ),
        ),
      );
}
