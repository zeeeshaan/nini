import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PublishedPostContent extends StatefulWidget {
  const PublishedPostContent({super.key, required this.post});
  final PostItem post;
  @override
  State<PublishedPostContent> createState() => _PublishedPostContentState();
}

class _PublishedPostContentState extends State<PublishedPostContent> {
  late final quill.QuillController _caption;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _caption = quill.QuillController(
      document: widget.post.captionDelta.isEmpty
          ? (quill.Document()..insert(0, widget.post.caption))
          : quill.Document.fromJson(widget.post.captionDelta),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post, theme = Theme.of(context);
    final tags = post.details.tags;
    final address = post.details.address;
    final schedule = post.details.schedule;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            post.title,
            textAlign: TextAlign.right,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (post.price.isNotEmpty)
            Text(
              AppStrings.persianDigits(post.price),
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          Localizations.override(
            context: context,
            delegates: const [quill.FlutterQuillLocalizations.delegate],
            child: quill.QuillEditor.basic(
              controller: _caption,
              focusNode: _focus,
              scrollController: _scroll,
              config: const quill.QuillEditorConfig(
                scrollable: false,
                enableInteractiveSelection: false,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in tags) Chip(label: Text('#$tag'))],
            ),
          ],
          if (address != null) ...[
            const SizedBox(height: 16),
            Text(address.address, textAlign: TextAlign.right),
          ],
          if (schedule != null) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.scheduledFor(
                MaterialLocalizations.of(context)
                    .formatMediumDate(schedule.startsAt),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
