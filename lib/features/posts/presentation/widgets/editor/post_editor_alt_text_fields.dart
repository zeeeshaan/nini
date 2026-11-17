import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';

import '../../cubit/post_editor_media_cubit.dart';

class PostEditorAltTextFields extends StatelessWidget {
  const PostEditorAltTextFields({super.key, required this.media});
  final PostEditorMediaState media;
  @override
  Widget build(BuildContext context) {
    final editor = context.read<CreatePostCubit>();
    final entries = [
      for (final item in media.retained)
        (id: 'media:${item.path}', name: item.name, altText: item.altText),
      for (final item in media.additions)
        (
          id: item.id,
          name:
              item.asset?.title ?? item.file?.name ?? ProfilePostStrings.media,
          altText: '',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            key: ValueKey(entry.id),
            padding: const EdgeInsets.only(top: 12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextFormField(
                initialValue: editor.state.altTexts[entry.id] ?? entry.altText,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: ProfilePostStrings.altText,
                  helperText: entry.name,
                  helperMaxLines: 2,
                ),
                onChanged: (value) => editor.setAltTexts({
                  ...editor.state.altTexts,
                  entry.id: value,
                }),
              ),
            ),
          ),
      ],
    );
  }
}
