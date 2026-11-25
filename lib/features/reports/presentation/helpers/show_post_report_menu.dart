import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/report_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/posts/presentation/widgets/actions/post_owner_action_tile.dart';
import 'package:nini/features/reports/data/api_reports_repository.dart';
import 'package:nini/features/reports/presentation/helpers/open_report_sheet.dart';

/// ⋮ on a post first shows Report, then the report form sheet.
Future<void> showPostReportMenu(
  BuildContext context, {
  required String postId,
}) async {
  final selected = await showAppBottomSheet<bool>(
    context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PostOwnerActionTile(
          label: ReportStrings.reportPost,
          icon: Icons.flag_outlined,
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    ),
  );
  if (!context.mounted || selected != true) return;
  await openReportSheet(
    context,
    title: ReportStrings.reportPost,
    targetType: ReportTargetType.post,
    targetId: postId,
  );
}
