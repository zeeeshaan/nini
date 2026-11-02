import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/shared/models/post/post_attributes.dart';

import '../post_feature_editor_row/post_feature_editor_row.dart';

class PostEditorFeaturesField extends StatefulWidget {
  const PostEditorFeaturesField({super.key});
  @override
  State<PostEditorFeaturesField> createState() =>
      _PostEditorFeaturesFieldState();
}

class _PostEditorFeaturesFieldState extends State<PostEditorFeaturesField> {
  late final _entries = context
      .read<CreatePostCubit>()
      .state
      .features
      .map((feature) => _FeatureEntry(feature.name, feature.value))
      .toList();
  @override
  Widget build(BuildContext context) => FormField<void>(
    validator: (_) =>
        _entries.any(
          (item) => item.name.trim().isEmpty || item.value.trim().isEmpty,
        )
        ? ProfilePostStrings.invalidFeatures
        : null,
    onSaved: (_) => context.read<CreatePostCubit>().setFeatures([
      for (final item in _entries)
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
        for (final entry in _entries)
          PostFeatureEditorRow(
            key: ObjectKey(entry),
            name: entry.name,
            value: entry.value,
            onNameChanged: (value) {
              entry.name = value;
              field.didChange(null);
            },
            onValueChanged: (value) {
              entry.value = value;
              field.didChange(null);
            },
            onRemove: () {
              setState(() => _entries.remove(entry));
              field.didChange(null);
            },
          ),
        if (field.hasError)
          Text(
            field.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _entries.add(_FeatureEntry('', '')));
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
  );
}

class _FeatureEntry {
  _FeatureEntry(this.name, this.value);
  String name, value;
}
