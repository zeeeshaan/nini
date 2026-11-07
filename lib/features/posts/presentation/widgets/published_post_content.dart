import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PublishedPostContent extends StatefulWidget {
  const PublishedPostContent({
    super.key,
    required this.post,
    this.serviceLayout = false,
  });
  final PostItem post;
  final bool serviceLayout;
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
            style: widget.serviceLayout
                ? AppTextStyles.postHeading.copyWith(
                    fontWeight: AppTextStyles.bold,
                  )
                : theme.textTheme.titleLarge,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          if (widget.serviceLayout) ...[
            const Text(
              AppStrings.serviceDescription,
              textAlign: TextAlign.right,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 20),
          ],
          Localizations.override(
            context: context,
            delegates: const [quill.FlutterQuillLocalizations.delegate],
            child: Directionality(
              textDirection: TextDirection.rtl,
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
          ),
          if (!widget.serviceLayout && tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(
                    label: Text(
                      '#$tag',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ],
          if (!widget.serviceLayout && address != null) ...[
            const SizedBox(height: 16),
            Text(
              address.address,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
          if (schedule != null) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.scheduledFor(
                MaterialLocalizations.of(context)
                    .formatMediumDate(schedule.startsAt),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
    );
  }
}
