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
    this.backend = false,
    this.backendData,
    this.onTouched,
  });
  final GlobalKey<FormState> formKey;
  final quill.QuillController captionController;
  final VoidCallback onChanged;
  final bool backend;
  final Map<String, dynamic>? backendData;
  final ValueChanged<String>? onTouched;
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
          PostEditorMediaSection(backend: backend),
          const SizedBox(height: 24),
          PostCategorySelector(
            backendCategories: backend,
            preserveUnlisted: backend,
            existingGlobal: backendData?['category'] is Map
                ? Map<String, dynamic>.from(backendData!['category'] as Map)
                : null,
            existingPersonal: backendData?['profileCategory'] is Map
                ? Map<String, dynamic>.from(
                    backendData!['profileCategory'] as Map,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          PostEditorBasicFields(
            captionController: captionController,
            backend: backend,
          ),
          const SizedBox(height: 24),
          PostEditorPricingFields(
            backend: backend,
            backendData: backendData,
            onTouched: onTouched,
          ),
          const SizedBox(height: 24),
          PostEditorOptionsFields(
            backendData: backendData,
            onTouched: onTouched,
          ),
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
