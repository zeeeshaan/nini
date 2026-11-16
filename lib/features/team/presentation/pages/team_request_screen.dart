import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/presentation/cubit/team_request_cubit.dart';
import 'package:nini/features/team/presentation/helpers/open_team_checkout.dart';
import 'package:nini/features/team/presentation/widgets/common/attachment_section.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_actions.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_fields.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_provider_list.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_review_actions.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_status_sheet.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_summary.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// One work brief is completed after the provider multi-selection is finished.
class TeamRequestScreen extends StatelessWidget {
  const TeamRequestScreen({
    super.key,
    required this.initial,
    this.onPaid,
    this.closeOnPaid = false,
  });
  final TeamRequest initial;
  final ValueChanged<TeamRequest>? onPaid;
  final bool closeOnPaid;

  void _checkout(BuildContext context, TeamRequestCubit cubit) {
    cubit.checkout(() => openTeamCheckout(context, cubit.state));
  }

  void _status(BuildContext context, TeamRequestCubit cubit) {
    showTeamRequestStatus(
      context,
      cubit,
      onCheckout: () => _checkout(context, cubit),
    );
  }

  void _request(BuildContext context, TeamRequestCubit cubit) {
    FocusScope.of(context).unfocus();
    if (!cubit.submit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "عنوان کار، توضیحات و تاریخ شروع را وارد کنید.",
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }
    // UI demo only; waiting and decline states remain for provider responses.
    cubit.previewResponse(accepted: true);
    _status(context, cubit);
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TeamRequestCubit(initial),
    child: BlocListener<TeamRequestCubit, TeamRequest>(
      listenWhen: (before, after) =>
          before.status != TeamRequestStatus.paid &&
          after.status == TeamRequestStatus.paid,
      listener: (context, request) {
        onPaid?.call(request);
        if (closeOnPaid && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(request);
        }
      },
      child: AppResponsiveBuilder(
        builder: (context, responsive) =>
            BlocBuilder<TeamRequestCubit, TeamRequest>(
              builder: (context, request) {
                final cubit = context.read<TeamRequestCubit>();
                final padding = responsive.horizontalPadding;
                final spacing = responsive.verticalSpacing;
                final editing = request.status == TeamRequestStatus.draft;
                void close() => Navigator.of(context).pop(request);
                return PopScope<TeamRequest>(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    if (!didPop) close();
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          editing
                              ? "ارسال درخواست به افراد انتخاب‌شده"
                              : "درخواست تیم",
                          textAlign: TextAlign.right,
                          style: AppTextStyles.pageTitle,
                          textDirection: TextDirection.rtl,
                        ),
                      ),

                      actions: [
                        IconButton(
                          onPressed: close,
                          tooltip: "بازگشت",
                          icon: const AppIcon(AppIcons.backRight, size: 20),
                        ),
                      ],
                    ),
                    body: SafeArea(
                      top: false,
                      bottom: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: editing
                              ? ListView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(padding),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          TeamRequestProviderList(
                                            request: request,
                                            onQuantityChanged:
                                                cubit.updateQuantity,
                                          ),
                                          SizedBox(height: spacing * 1.5),
                                          TeamRequestFields(
                                            request: request,
                                            spacing: spacing / 2,
                                            onTitleChanged: cubit.updateTitle,
                                            onDescriptionChanged:
                                                cubit.updateDescription,
                                            onScheduleChanged:
                                                cubit.updateSchedule,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TeamAttachmentsSection(
                                      attachments: request.attachments,
                                      horizontalPadding: padding,
                                      spacing: spacing,
                                      onAddAttachments: cubit.addAttachments,
                                      onRemoveAttachment:
                                          cubit.removeAttachment,
                                    ),
                                    SizedBox(height: spacing),
                                  ],
                                )
                              : TeamRequestSummary(
                                  request: request,
                                  padding: padding,
                                  spacing: spacing,
                                ),
                        ),
                      ),
                    ),
                    bottomNavigationBar: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 12,
                        ),
                        child: Center(
                          heightFactor: 1,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: editing
                                ? TeamRequestActions(
                                    onCancel: close,
                                    onRequest: () => _request(context, cubit),
                                  )
                                : TeamRequestReviewActions(
                                    request: request,
                                    onEdit: cubit.edit,
                                    onStatus: () => _status(context, cubit),
                                    onCheckout: () => _checkout(context, cubit),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    ),
  );
}
