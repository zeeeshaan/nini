import 'package:nini/features/posts/presentation/cubit/post_editor_fields_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/shared/models/post/post_attributes.dart';

import '../post_feature_editor_row/post_feature_editor_row.dart';

class PostEditorFeaturesField extends StatelessWidget {
  const PostEditorFeaturesField({super.key});
  @override
  Widget build(BuildContext context) {
    final fields = context.read<PostEditorFieldsCubit>();
    return BlocBuilder<PostEditorFieldsCubit, PostEditorFieldsState>(
      bloc: fields,
      builder: (context, state) => FormField<void>(
        validator: (_) =>
            fields.state.features.any(
              (item) => item.name.trim().isEmpty || item.value.trim().isEmpty,
            )
            ? ProfilePostStrings.invalidFeatures
            : null,
        onSaved: (_) => context.read<CreatePostCubit>().setFeatures([
          for (final item in fields.state.features)
            PostFeature(name: item.name.trim(), value: item.value.trim()),
        ]),
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ProfilePostStrings.features,
              style: Theme.of(context).textTheme.titleMedium,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            for (final entry in fields.state.features)
              PostFeatureEditorRow(
                key: ValueKey(entry.id),
                name: entry.name,
                value: entry.value,
                onNameChanged: (value) {
                  fields.changeFeature(entry.id, name: value);
                  field.didChange(null);
                },
                onValueChanged: (value) {
                  fields.changeFeature(entry.id, value: value);
                  field.didChange(null);
                },
                onRemove: () {
                  fields.removeFeature(entry.id);
                  field.didChange(null);
                },
              ),
            if (field.hasError)
              Text(
                field.errorText!,
                style: AppTextStyles.inherit.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  fields.addFeature();
                  field.didChange(null);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  ProfilePostStrings.addFeature,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
