import 'package:nini/features/create_post/presentation/cubit/post_operation_cubit.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_caption_synchronizer.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_basic_details_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_options_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_pricing_inventory_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_publish_actions.dart';
import 'package:nini/features/create_post/presentation/widgets/form/selected_media_grid.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class CreatePostDetailsScreen extends StatefulWidget {
  const CreatePostDetailsScreen({super.key, required this.attachments});
  final List<GalleryAttachment> attachments;
  @override
  State<CreatePostDetailsScreen> createState() =>
      _CreatePostDetailsScreenState();
}

class _CreatePostDetailsScreenState extends State<CreatePostDetailsScreen> {
  late final TextEditingController _titleController,
      _priceController,
      _discountController,
      _stockController;
  late final quill.QuillController _captionController;
  late final PostCaptionSynchronizer _captionSynchronizer;
  final _operation = PostOperationCubit();
  CreatePostCubit get _draft => context.read<CreatePostCubit>();

  @override
  void initState() {
    super.initState();
    final draft = _draft.state;
    _titleController = TextEditingController(text: draft.title);
    _priceController = TextEditingController(text: draft.price);
    _discountController = TextEditingController(text: draft.discount);
    _stockController = TextEditingController(text: draft.warehouseStock);
    final document = draft.captionDelta.isEmpty
        ? (quill.Document()..insert(0, draft.caption))
        : quill.Document.fromJson(draft.captionDelta);
    _captionController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _captionSynchronizer = PostCaptionSynchronizer(
      controller: _captionController,
      onChanged: _draft.updateRichCaption,
    );
  }

  @override
  void dispose() {
    _operation.close();
    _captionSynchronizer.dispose();
    _captionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _goBack() => Navigator.of(context).pop();

  bool _validateBasicDetails() {
    final issue = PostDraftValidator.forPublishing(
      _draft.state,
      hasAttachments: widget.attachments.isNotEmpty,
      now: DateTime.now(),
    );
    if (issue == null) return true;
    AppToast.warning(context, switch (issue) {
      PostDraftIssue.missingAttachment =>
        CreatePostStrings.selectAttachmentRequired,
      PostDraftIssue.missingPostType =>
        CreatePostStrings.selectPostTypeRequired,
      PostDraftIssue.missingTitle => CreatePostStrings.titleRequired,
      PostDraftIssue.missingCaption => CreatePostStrings.captionRequired,
      PostDraftIssue.scheduleInPast => CreatePostStrings.schedulePassed,
    });
    return false;
  }

  Future<void> _onPublish() async {
    if (_operation.state.saving) return;
    _captionSynchronizer.flush();
    if (!_validateBasicDetails()) return;
    ContextMenuController.removeAny();
    FocusScope.of(context).unfocus();
    final posts = context.read<PostsCubit>();
    final draft = _draft.state;
    _operation.beginSave();
    final post = await posts.publish(draft, widget.attachments);
    if (!mounted) return;
    if (post != null) {
      // Keep the UI busy during the closing transition. Typed route results
      // unwind details -> gallery -> dashboard without fragile popUntil calls.
      Navigator.of(context).pop<PostItem>(post);
    } else {
      _operation.retry();
      AppToast.error(
        context,
        CreatePostStrings.errorMessage(
          posts.state.publishError ?? CreatePostStrings.publishFailed,
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostOperationCubit, PostOperationState>(
    bloc: _operation,
    builder: (context, state) {
      final theme = Theme.of(context), colors = theme.colorScheme;
      return Localizations.override(
        context: context,
        locale: const Locale('en'),
        child: PopScope(
          canPop: !_operation.state.saving,
          child: Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              elevation: 0,
              toolbarHeight: 56,
              centerTitle: false,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leadingWidth: 48,
              leading: IconButton(
                tooltip: CreatePostStrings.backToGallery,
                onPressed: _operation.state.saving ? null : _goBack,
                icon: const AppIcon(AppIcons.back, size: 22),
              ),
              title: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      CreatePostStrings.createPost,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: .5,
                  color: theme.dividerColor,
                ),
              ),
            ),
            body: AbsorbPointer(
              absorbing: _operation.state.saving,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SingleChildScrollView(
                      key: const PageStorageKey('create-post-details'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SelectedMediaGrid(attachments: widget.attachments),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PostBasicDetailsSection(
                                  titleController: _titleController,
                                  captionController: _captionController,
                                  attachments: widget.attachments,
                                ),
                                PostPricingInventorySection(
                                  priceController: _priceController,
                                  discountController: _discountController,
                                  stockController: _stockController,
                                ),
                                const PostOptionsSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: PostPublishActions(
              publishing: _operation.state.saving,
              onCancel: _goBack,
              onPublish: _onPublish,
            ),
          ),
        ),
      );
    },
  );
}
