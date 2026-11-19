import 'package:nini/features/create_post/presentation/cubit/post_operation_cubit.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/post_categories_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_caption_synchronizer.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_basic_details_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_options_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_pricing_inventory_section.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_publish_actions.dart';
import 'package:nini/features/create_post/presentation/widgets/form/selected_media_grid.dart';
import 'package:dio/dio.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
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
  final _basicKey = GlobalKey();
  final _priceKey = GlobalKey();
  final _mediaKey = GlobalKey();
  bool _showValidation = false;
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
    document.format(0, document.length, quill.Attribute.rightAlignment);
    document.history.clear();
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

  String _submissionError(Object error) {
    if (error is PostApiException) return error.message;
    if (error is DioException) {
      final retrySeconds = int.tryParse(
        error.response?.headers.value('retry-after') ?? '',
      );
      return switch (error.response?.statusCode) {
        400 =>
          'The server rejected the post or image. Check the entered details.',
        401 => 'Your session has expired.',
        403 => 'Your account cannot submit posts right now.',
        404 => 'The requested upload or post service is unavailable.',
        413 => 'An image exceeds the server size limit.',
        415 => 'The server rejected the image format.',
        429 =>
          retrySeconds != null && retrySeconds > 0
              ? 'Too many requests. Wait $retrySeconds seconds before trying again.'
              : 'Too many requests. Wait before trying again.',
        _ => 'The request could not be confirmed. Check My Posts before retrying if submission may have started.',
      };
    }
    return 'The request could not be confirmed. Check My Posts before retrying if submission may have started.';
  }

  Future<void> _onPublish() async {
    if (_operation.state.saving) return;
    _captionSynchronizer.flush();
    setState(() => _showValidation = true);
    final current = _draft.state;
    final categories = context.read<PostCategoriesCubit>().state;
    final missingCategory =
        current.categoryKey != null &&
        (!categories.loading &&
            categories.error == null &&
            categories.find(current.categoryKey) == null);
    final missingBasic =
        current.postType == null ||
        current.title.trim().isEmpty ||
        current.caption.trim().isEmpty ||
        missingCategory;
    final missingKey = widget.attachments.isEmpty
        ? _mediaKey
        : missingBasic
        ? _basicKey
        : current.price.trim().isEmpty
        ? _priceKey
        : null;
    if (missingKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = missingKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
            alignment: 0.1,
          );
        }
      });
    }
    if (!_validateBasicDetails()) return;
    if (current.categoryKey != null &&
        (categories.loading ||
            categories.error != null ||
            categories.categories.isEmpty)) {
      AppToast.warning(
        context,
        categories.error ??
            (categories.loading
                ? CreatePostStrings.categoriesLoadFailed
                : CreatePostStrings.categoriesEmpty),
      );
      return;
    }
    if (current.categoryKey != null &&
        categories.find(current.categoryKey) == null) {
      AppToast.warning(context, CreatePostStrings.categoryRequired);
      return;
    }
    final profileCategoryId = _draft.state.profileCategoryId;
    if (profileCategoryId != null) {
      final personal = context.read<ProfileCategoriesCubit>();
      final state = personal.state;
      if (personal.isClosed || state.loading || state.loadFailed) {
        if (!personal.isClosed && state.loading) unawaited(personal.load());
        AppToast.warning(
          context,
          state.loading
              ? CreatePostStrings.profileCategoriesLoading
              : state.error ?? CreatePostStrings.categoriesLoadFailed,
        );
        return;
      }
      if (!ProfileCategory.isBackendId(profileCategoryId) ||
          state.find(profileCategoryId) == null) {
        AppToast.warning(context, CreatePostStrings.profileCategoryUnavailable);
        return;
      }
    }
    if (_draft.state.price.trim().isEmpty) {
      AppToast.warning(context, CreatePostStrings.invalidPrice);
      return;
    }
    ContextMenuController.removeAny();
    FocusScope.of(context).unfocus();
    final posts = context.read<ApiPostsRepository>();
    final draft = _draft.state;
    final hasRichFormatting = draft.captionDelta.any((op) {
      final attributes = op['attributes'];
      return attributes is Map &&
          attributes.keys.any((key) => key != 'align' && key != 'direction');
    });
    if (hasRichFormatting) {
      AppToast.warning(
        context,
        'The server saves the caption as plain text; formatting will not be saved.',
      );
    }
    _operation.beginSave();
    try {
      final post = await posts.submit(draft, widget.attachments);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text(
              'Post Submitted for Review',
              textAlign: TextAlign.right,
            ),
            content: Text(
              '${post.status == 'pending_review' ? 'Your post has been submitted successfully and is now awaiting admin review. You can check its status in My Posts.' : 'Your post was submitted. Its current status is ${post.status.replaceAll('_', ' ')}. You can check its status in My Posts.'}${hasRichFormatting ? '\n\nThe caption was saved as plain text; formatting was not saved.' : ''}',
              textAlign: TextAlign.right,
            ),
            actions: [
              AppButton(
                label: 'Got it',
                onPressed: () => Navigator.of(dialogContext).pop(),
                height: 44,
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      _operation.retry();
      Navigator.of(context).pop<bool>(true);
    } catch (error) {
      if (!mounted) return;
      _operation.retry();
      AppToast.error(
        context,
        CreatePostStrings.errorMessage(
          posts.uncertainMessage ?? _submissionError(error),
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
              title: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      CreatePostStrings.createPost,
                      textDirection: TextDirection.ltr,
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

              actions: [
                IconButton(
                  tooltip: CreatePostStrings.backToGallery,
                  onPressed: _operation.state.saving ? null : _goBack,
                  icon: const AppIcon(AppIcons.backRight, size: 22),
                ),
              ],
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
                      child: BlocBuilder<CreatePostCubit, PostDraft>(
                        builder: (context, draft) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              key: _mediaKey,
                              decoration:
                                  _showValidation && widget.attachments.isEmpty
                                  ? BoxDecoration(
                                      border: Border.all(color: colors.error),
                                    )
                                  : null,
                              child: SelectedMediaGrid(
                                attachments: widget.attachments,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PostBasicDetailsSection(
                                    key: _basicKey,
                                    titleController: _titleController,
                                    captionController: _captionController,
                                    attachments: widget.attachments,
                                    categoryError:
                                        _showValidation &&
                                        draft.categoryKey != null &&
                                        !context
                                            .read<PostCategoriesCubit>()
                                            .state
                                            .loading &&
                                        context
                                                .read<PostCategoriesCubit>()
                                                .state
                                                .error ==
                                            null &&
                                        context
                                                .read<PostCategoriesCubit>()
                                                .state
                                                .find(draft.categoryKey) ==
                                            null,
                                    typeError:
                                        _showValidation &&
                                        draft.postType == null,
                                    titleError:
                                        _showValidation &&
                                        draft.title.trim().isEmpty,
                                    captionError:
                                        _showValidation &&
                                        draft.caption.trim().isEmpty,
                                  ),
                                  PostPricingInventorySection(
                                    key: _priceKey,
                                    priceController: _priceController,
                                    discountController: _discountController,
                                    stockController: _stockController,
                                    priceError:
                                        _showValidation &&
                                        draft.price.trim().isEmpty,
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
