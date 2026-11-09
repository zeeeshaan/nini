import 'package:nini/features/posts/presentation/cubit/post_editor_fields_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/presentation/cubit/post_operation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_caption_synchronizer.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../cubit/post_editor_media_cubit.dart';
import '../cubit/posts_cubit.dart';
import '../cubit/profile_categories_cubit.dart';
import '../helpers/confirm_discard_post_changes.dart';
import '../helpers/post_draft_mapper.dart';
import '../widgets/editor/edit_post_form.dart';
import '../widgets/editor/post_editor_actions.dart';

class EditPostScreen extends StatelessWidget {
  const EditPostScreen({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => CreatePostCubit(initial: postDraftFromPost(post)),
      ),
      BlocProvider(create: (_) => PostEditorMediaCubit(post.media)),
      BlocProvider(
        create: (_) => PostEditorFieldsCubit(postDraftFromPost(post)),
      ),
    ],
    child: PersianFeature(child: _EditPostView(post: post)),
  );
}

class _EditPostView extends StatefulWidget {
  const _EditPostView({required this.post});
  final PostItem post;
  @override
  State<_EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<_EditPostView> {
  final _form = GlobalKey<FormState>();
  late final quill.QuillController _caption;
  late final PostCaptionSynchronizer _synchronizer;
  final _operation = PostOperationCubit();
  bool _confirming = false;
  CreatePostCubit get _editor => context.read<CreatePostCubit>();

  @override
  void initState() {
    super.initState();
    final draft = _editor.state;
    _caption = quill.QuillController(
      document: draft.captionDelta.isEmpty
          ? (quill.Document()..insert(0, draft.caption))
          : quill.Document.fromJson(draft.captionDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
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
              title: const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  ProfilePostStrings.editPost,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
              leading: IconButton(
                tooltip: ProfilePostStrings.back,
                onPressed: _operation.state.saving ? null : _cancel,
                icon: const Icon(Icons.arrow_back),
              ),
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
                            textDirection: TextDirection.rtl,
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
