import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_caption_synchronizer.dart';
import 'package:nini/features/create_post/presentation/widgets/post_form_sections/post_basic_details_section.dart';
import 'package:nini/features/create_post/presentation/widgets/post_form_sections/post_options_section.dart';
import 'package:nini/features/create_post/presentation/widgets/post_form_sections/post_pricing_inventory_section.dart';
import 'package:nini/features/create_post/presentation/widgets/post_form_sections/post_publish_actions.dart';
import 'package:nini/features/create_post/presentation/widgets/selected_media_grid/selected_media_grid.dart';
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
  bool _publishing = false;
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
      PostDraftIssue.missingAttachment => AppStrings.selectAttachmentRequired,
      PostDraftIssue.missingPostType => AppStrings.selectPostTypeRequired,
      PostDraftIssue.missingTitle => AppStrings.titleRequired,
      PostDraftIssue.missingCaption => AppStrings.captionRequired,
      PostDraftIssue.scheduleInPast => AppStrings.schedulePassed,
    });
    return false;
  }

  Future<void> _onPublish() async {
    if (_publishing) return;
    _captionSynchronizer.flush();
    if (!_validateBasicDetails()) return;
    FocusScope.of(context).unfocus();
    final posts = context.read<PostsCubit>();
    final draft = _draft.state;
    setState(() => _publishing = true);
    final post = await posts.publish(draft, widget.attachments);
    if (!mounted) return;
    if (post != null) {
      // Keep the UI busy during the closing transition. Typed route results
      // unwind details -> gallery -> dashboard without fragile popUntil calls.
      Navigator.of(context).pop<PostItem>(post);
    } else {
      setState(() => _publishing = false);
      AppToast.error(
        context,
        posts.state.publishError ?? AppStrings.publishFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return PopScope(
      canPop: !_publishing,
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
            tooltip: AppStrings.backToGallery,
            onPressed: _publishing ? null : _goBack,
            icon: const AppIcon(AppIcons.back, size: 22),
          ),
          title: Text(
            AppStrings.createPost,
            style: theme.textTheme.titleMedium,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: .5, color: theme.dividerColor),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _publishing,
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
          publishing: _publishing,
          onCancel: _goBack,
          onPublish: _onPublish,
        ),
      ),
    );
  }
}
