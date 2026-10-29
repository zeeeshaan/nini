import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TagsDialog extends StatefulWidget {
  const TagsDialog({super.key, required this.initial});
  final List<String> initial;
  @override
  State<TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<TagsDialog> {
  final _controller = TextEditingController();
  late final List<String> _tags = [...widget.initial];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final candidates = _controller.text
        .split(RegExp(r'[,،\n]'))
        .map((text) => text.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((text) => text.isNotEmpty);
    setState(() {
      for (final tag in candidates) {
        if (!_tags.any((value) => value.toLowerCase() == tag.toLowerCase())) {
          _tags.add(tag);
        }
      }
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => PostDialog(
    title: AppStrings.tagsKeywords,
    actions: PostDialogActions(
      onDone: () {
        _add();
        Navigator.of(context).pop(List<String>.unmodifiable(_tags));
      },
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          AppTextField(
            controller: _controller,
            label: AppStrings.keywords,
            hint: AppStrings.separateTags,
            onSubmitted: (_) => _add(),
            suffixIcon: IconButton(
              tooltip: AppStrings.addTags,
              onPressed: _add,
              icon: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                InputChip(
                  label: Text('#$tag'),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
