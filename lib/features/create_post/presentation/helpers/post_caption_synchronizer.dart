import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Synchronizes rich caption edits without owning or disposing UI controllers.
class PostCaptionSynchronizer {
  PostCaptionSynchronizer({required this.controller, required this.onChanged}) {
    _subscription = controller.document.changes.listen((_) => flush());
  }
  final quill.QuillController controller;
  final void Function(String, List<Map<String, dynamic>>) onChanged;
  late final StreamSubscription<quill.DocChange> _subscription;

  void flush() {
    final document = controller.document;
    final text = document.toPlainText();
    onChanged(
      text.endsWith('\n') ? text.substring(0, text.length - 1) : text,
      document
          .toDelta()
          .toJson()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
    );
  }

  void dispose() => _subscription.cancel();
}
