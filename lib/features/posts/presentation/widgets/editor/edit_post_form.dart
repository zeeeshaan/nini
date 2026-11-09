import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../categories/post_category_selector.dart';
import 'post_editor_basic_fields.dart';
import 'post_editor_features_field.dart';
import 'post_editor_location_fields.dart';
import 'post_editor_media_section.dart';
import 'post_editor_options_fields.dart';
import 'post_editor_pricing_fields.dart';
import 'post_editor_schedule_field.dart';

/// Composes small editor sections; persistence and route handling stay in the page.
class EditPostForm extends StatelessWidget {
  const EditPostForm({
    super.key,
    required this.formKey,
    required this.captionController,
    required this.onChanged,
  });
  final GlobalKey<FormState> formKey;
  final quill.QuillController captionController;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    onChanged: onChanged,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PostEditorMediaSection(),
          const SizedBox(height: 24),
          const PostCategorySelector(),
          const SizedBox(height: 16),
          PostEditorBasicFields(captionController: captionController),
          const SizedBox(height: 24),
          const PostEditorPricingFields(),
          const SizedBox(height: 24),
          const PostEditorOptionsFields(),
          const SizedBox(height: 24),
          const PostEditorLocationFields(),
          const SizedBox(height: 24),
          const PostEditorFeaturesField(),
          const SizedBox(height: 24),
          const PostEditorScheduleField(),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
