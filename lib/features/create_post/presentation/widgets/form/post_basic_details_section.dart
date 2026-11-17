import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/helpers/post_option_selection.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/alt_text_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/form/caption_editor.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_type_dialog.dart';
import 'package:nini/features/posts/presentation/widgets/categories/post_category_selector.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;

class PostBasicDetailsSection extends StatelessWidget {
  const PostBasicDetailsSection({
    super.key,
    required this.titleController,
    required this.captionController,
    required this.attachments,
  });
  final TextEditingController titleController;
  final quill.QuillController captionController;
  final List<GalleryAttachment> attachments;
  @override
  Widget build(BuildContext context) {
    final draftCubit = context.read<CreatePostCubit>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PostCategorySelector(english: true),
        const SizedBox(height: 16),
        BlocSelector<CreatePostCubit, PostDraft, CreatePostType?>(
          selector: (state) => state.postType,
          builder: (context, value) => PostFormOptionTile(
            label: CreatePostStrings.postType,
            value: value == null
                ? null
                : value == CreatePostType.product
                ? CreatePostStrings.product
                : CreatePostStrings.services,
            onTap: () => choosePostOption<CreatePostType>(
              context,
              TypePostDialog(selected: draftCubit.state.postType),
              draftCubit.selectPostType,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: titleController,
          label: CreatePostStrings.productServiceTitle,
          hint: CreatePostStrings.enterPostTitle,
          textAlign: TextAlign.right,
          decorationDirection: TextDirection.rtl,
          textInputAction: TextInputAction.next,
          onChanged: draftCubit.updateTitle,
        ),
        const SizedBox(height: 16),
        Text(
          CreatePostStrings.postCaption,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 8),
        CaptionEditor(controller: captionController),
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
