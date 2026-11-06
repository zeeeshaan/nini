import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nini/core/localization/create_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/caption_editor/client_caption_toolbar.dart';

/// A real rich-text editor. Its controller stores Quill Delta, so formatting is
/// retained when leaving the screen; toolbar actions affect the selection.
class CaptionEditor extends StatefulWidget {
  const CaptionEditor({super.key, required this.controller});
  final QuillController controller;
  @override
  State<CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends State<CaptionEditor> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    delegates: const [
      ...GlobalMaterialLocalizations.delegates,
      FlutterQuillLocalizations.delegate,
    ],
    child: Builder(
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuillSimpleToolbar(
              controller: widget.controller,
              config: QuillSimpleToolbarConfig(
                buttonOptions: clientCaptionButtons(context),
                multiRowsDisplay: false,
                showFontFamily: false,
                showFontSize: false,
                showSmallButton: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showHeaderStyle: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showAlignmentButtons: true,
                showDirection: true,
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 180,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: QuillEditor.basic(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    placeholder: CreatePostStrings.writeCaption,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
