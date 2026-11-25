import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/report_strings.dart';
import 'package:nini/core/network/api_client/api_client.dart';
import 'package:nini/core/security/secure_token/secure_token.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/reports/data/api_reports_repository.dart';
import 'package:nini/features/reports/presentation/cubit/report_cubit.dart';
import 'package:nini/features/reports/presentation/widgets/report_sheet.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

Future<bool> openReportSheet(
  BuildContext context, {
  required String title,
  required String targetType,
  required String targetId,
}) async {
  if (!ProfileCategory.isBackendId(targetId)) {
    AppToast.error(context, ReportStrings.failed);
    return false;
  }
  final session = context.read<SessionCubit?>();
  final initial = session?.state;
  if (session == null ||
      initial == null ||
      initial.status != SessionStatus.authenticated ||
      initial.userId == null) {
    AppToast.warning(context, ReportStrings.signInRequired);
    return false;
  }
  bool current() =>
      !session.isClosed &&
      session.state.status == SessionStatus.authenticated &&
      !session.state.isLoggingOut &&
      !session.state.logoutCleanupRequired &&
      session.state.userId == initial.userId &&
      session.state.accountRevision == initial.accountRevision;

  final provided = context.read<ApiReportsRepository?>();
  final repository =
      provided ??
      ApiReportsRepository(
        context.read<ApiClient>(),
        context.read<SecureTokenStore>(),
        isCurrentAccount: current,
      );

  final result = await showPostDialog<bool>(
    context,
    BlocProvider(
      create: (_) => ReportCubit(repository),
      child: ReportSheet(
        title: title,
        targetType: targetType,
        targetId: targetId,
      ),
    ),
  );
  return result == true;
}
