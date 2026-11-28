import 'package:flutter/widgets.dart';

/// Clears the text that was successfully sent without wiping concurrent edits.
///
/// - Exact match → clear the field.
/// - Sent text is still a prefix → keep only the appended remainder.
/// - Otherwise leave the user's rewritten draft unchanged.
///
/// On send failure the caller should not invoke this, so the draft stays.
void clearSentComposerDraft(TextEditingController controller, String sentText) {
  final current = controller.text;
  if (current == sentText) {
    controller.clear();
    return;
  }
  if (sentText.isNotEmpty && current.startsWith(sentText)) {
    final remaining = current.substring(sentText.length);
    controller.value = TextEditingValue(
      text: remaining,
      selection: TextSelection.collapsed(offset: remaining.length),
    );
  }
}
