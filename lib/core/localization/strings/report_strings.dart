import 'package:nini/features/reports/data/api_reports_repository.dart';

/// Copy for the shared report sheet (Swagger reason enums only).
abstract final class ReportStrings {
  static const report = 'Report';
  static const reportUser = 'Report user';
  static const reportPost = 'Report post';
  static const chooseReason = 'Select a reason';
  static const noteOptional = 'Additional details (optional)';
  static const noteHint = 'Add more information…';
  static const submit = 'Submit report';
  static const submitting = 'Submitting…';
  static const success = 'Report submitted.';
  static const failed = 'Could not submit the report. Try again.';
  static const signInRequired = 'Please sign in to report.';
  static const ownAccount = 'You cannot report your own account.';
  static const ownPost = 'You cannot report your own post.';
  static const reasonRequired = 'Select a reason before submitting.';

  static const reasons = <String, String>{
    ReportReason.spam: 'Spam',
    ReportReason.abusive: 'Abusive',
    ReportReason.inappropriateContent: 'Inappropriate content',
    ReportReason.fraud: 'Fraud',
    ReportReason.prohibitedItem: 'Prohibited item',
    ReportReason.other: 'Other',
  };
}
