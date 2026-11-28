import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/models/post_draft.dart';
import 'package:hywork/features/create_post/cubit/create_post_cubit.dart';
import 'package:hywork/features/create_post/utils/post_option_selection.dart';
import 'package:hywork/features/create_post/widgets/alt_text_dialog/alt_text_dialog.dart';
import 'package:hywork/features/create_post/widgets/caption_editor/caption_editor.dart';
import 'package:hywork/features/create_post/widgets/post_form_option_tile/post_form_option_tile.dart';
import 'package:hywork/features/create_post/widgets/post_type_dialog/post_type_dialog.dart';
import 'package:hywork/features/posts/presentation/widgets/categories/post_category_selector.dart';
import 'package:hywork/shared/widgets/app_textfield/app_text_field.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;

class PostBasicDetailsSection extends StatelessWidget {
  const PostBasicDetailsSection({
    super.key,
    required this.titleController,
    required this.captionController,
    required this.attachments,
    this.categoryError = false,
    this.typeError = false,
    this.titleError = false,
    this.captionError = false,
    this.lockPostType = false,
  });
  final TextEditingController titleController;
  final quill.QuillController captionController;
  final List<GalleryAttachment> attachments;
  final bool categoryError, typeError, titleError, captionError;
  final bool lockPostType;
  @override
  Widget build(BuildContext context) {
    final draftCubit = context.read<CreatePostCubit>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostCategorySelector(
          english: true,
          backendCategories: true,
          hasError: categoryError,
        ),
        const SizedBox(height: 16),
        BlocSelector<CreatePostCubit, PostDraft, CreatePostType?>(
          selector: (state) => state.postType,
          builder: (context, value) => PostFormOptionTile(
            hasError: typeError,
            label: CreatePostStrings.postType,
            value: value == null
                ? null
                : value == CreatePostType.product
                ? CreatePostStrings.product
                : CreatePostStrings.services,
            onTap: lockPostType
                ? null
                : () => choosePostOption<CreatePostType>(
                    context,
                    TypePostDialog(selected: draftCubit.state.postType),
                    draftCubit.selectPostType,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CreatePostStrings.productServiceLabel,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .45),
                ),
              ),
              Text(
                CreatePostStrings.titleLabel,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          hasError: titleError,
          controller: titleController,
          textAlign: TextAlign.right,
          decorationDirection: TextDirection.rtl,
          textInputAction: TextInputAction.next,
          onChanged: draftCubit.updateTitle,
        ),
        const SizedBox(height: 16),
        Text(
          CreatePostStrings.postCaption,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        CaptionEditor(controller: captionController, hasError: captionError),
        const SizedBox(height: 16),
        BlocSelector<CreatePostCubit, PostDraft, int>(
          selector: (state) =>
              state.altTexts.values.where((value) => value.isNotEmpty).length,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.altText,
            value: CreatePostStrings.descriptionCount(value),
            onTap: () => choosePostOption<Map<String, String>>(
              context,
              AltTextDialog(
                attachments: attachments,
                initial: draftCubit.state.altTexts,
              ),
              draftCubit.setAltTexts,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
