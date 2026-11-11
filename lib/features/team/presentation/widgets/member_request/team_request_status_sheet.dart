import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/presentation/cubit/team_request_cubit.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

class TeamRequestStatusSheet extends StatelessWidget {
  const TeamRequestStatusSheet({
    super.key,
    required this.cubit,
    required this.onCheckout,
  });

  final TeamRequestCubit cubit;
  final VoidCallback onCheckout;

  static String label(TeamRequestStatus status) => switch (status) {
    TeamRequestStatus.draft => 'Draft request',
    TeamRequestStatus.awaiting => 'Awaiting Acceptance',
    TeamRequestStatus.accepted => 'Your request has been accepted.',
    TeamRequestStatus.declined => 'Your request has been declined.',
    TeamRequestStatus.cancelled => 'Request cancelled.',
    TeamRequestStatus.paid => 'Demo payment completed.',
  };

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TeamRequestCubit, TeamRequest>(
    bloc: cubit,
    builder: (context, request) => SafeArea(
      top: false,
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height * .5).clamp(280.0, 480.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 14),
              const Text(
                'UI preview',
                style: AppTextStyles.smallPrint,
                textAlign: TextAlign.right,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label(request.status),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyText,
                        ),
                        if (request.status == TeamRequestStatus.awaiting) ...[
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    cubit.previewResponse(accepted: true),
                                child: const Text('Preview acceptance'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    cubit.previewResponse(accepted: false),
                                child: const Text('Preview decline'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (request.status == TeamRequestStatus.accepted)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.outlined,
                        onPressed: () {
                          cubit.cancelRequest();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Checkout',
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCheckout();
                        },
                      ),
                    ),
                  ],
                )
              else if (request.status == TeamRequestStatus.awaiting)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      cubit.cancelRequest();
                      Navigator.of(context).pop();
                    },
                    icon: const AppIcon(AppIcons.close, size: 20),
                    label: const Text('Cancel Request'),
                  ),
                )
              else
                AppButton(
                  label: request.status == TeamRequestStatus.paid
                      ? 'Done'
                      : 'Edit request',
                  onPressed: () {
                    if (request.status != TeamRequestStatus.paid) cubit.edit();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showTeamRequestStatus(
  BuildContext context,
  TeamRequestCubit cubit, {
  required VoidCallback onCheckout,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  constraints: const BoxConstraints(maxWidth: 720),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  clipBehavior: Clip.antiAlias,
  barrierColor: AppColors.black.withValues(alpha: .4),
  builder: (context) => Theme(
    data: Theme.of(context).brightness == Brightness.light
        ? AppTheme.dark
        : AppTheme.light,
    child: Material(
      color: Theme.of(context).colorScheme.onSurface,
      child: TeamRequestStatusSheet(cubit: cubit, onCheckout: onCheckout),
    ),
  ),
);
