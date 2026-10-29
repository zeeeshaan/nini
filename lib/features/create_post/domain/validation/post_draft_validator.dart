import 'package:nini/features/create_post/domain/models/post_draft.dart';

enum PostDraftIssue {
  missingAttachment,
  missingPostType,
  missingTitle,
  missingCaption,
  scheduleInPast,
}

/// Shared field rules; callers retain their existing messages and UI behavior.
abstract final class PostDraftValidator {
  static PostDraftIssue? requiredFields(
    PostDraft draft, {
    required bool hasAttachments,
  }) {
    if (!hasAttachments) return PostDraftIssue.missingAttachment;
    if (draft.postType == null) return PostDraftIssue.missingPostType;
    if (draft.title.trim().isEmpty) return PostDraftIssue.missingTitle;
    if (draft.caption.trim().isEmpty) return PostDraftIssue.missingCaption;
    return null;
  }

  static PostDraftIssue? forPublishing(
    PostDraft draft, {
    required bool hasAttachments,
    required DateTime now,
  }) {
    final missing = requiredFields(draft, hasAttachments: hasAttachments);
    if (missing != null) return missing;
    if (draft.schedule != null && !draft.schedule!.startsAt.isAfter(now)) {
      return PostDraftIssue.scheduleInPast;
    }
    return null;
  }
}
