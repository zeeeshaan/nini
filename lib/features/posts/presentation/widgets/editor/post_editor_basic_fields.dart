import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/form/caption_editor.dart';

import '../../helpers/post_editor_validation.dart';

class PostEditorBasicFields extends StatelessWidget {
  const PostEditorBasicFields({
    super.key,
    required this.captionController,
    this.backend = false,
  });
  final quill.QuillController captionController;
  final bool backend;
  @override
  Widget build(BuildContext context) {
    final editor = context.read<CreatePostCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: backend,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DropdownButtonFormField<CreatePostType>(
              initialValue: editor.state.postType,
              decoration: const InputDecoration(
                labelText: ProfilePostStrings.type,
              ),
              items: const [
                DropdownMenuItem(
                  value: CreatePostType.product,
                  child: Text(
                    ProfilePostStrings.product,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
                DropdownMenuItem(
                  value: CreatePostType.services,
                  child: Text(
                    ProfilePostStrings.service,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null && !backend) editor.selectPostType(value);
              },
              alignment: Alignment.centerRight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            initialValue: editor.state.title,
            decoration: const InputDecoration(
              labelText: ProfilePostStrings.title,
            ),
            validator: PostEditorValidation.requiredText,
            onChanged: editor.updateTitle,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 16),
        FormField<String>(
          validator: (_) => PostEditorValidation.requiredText(
            captionController.document.toPlainText(),
          ),
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                ProfilePostStrings.caption,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              CaptionEditor(controller: captionController),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    field.errorText!,
                    style: AppTextStyles.inherit.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
