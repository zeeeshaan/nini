import 'package:nini/core/localization/strings/team_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:nini/features/team/presentation/helpers/select_team_members.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/features/team/data/in_memory_teams_repository.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/team/presentation/pages/team_request_screen.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

import '../widgets/common/attachment_section.dart';
import '../widgets/common/general_section.dart';
import '../widgets/common/header.dart';
import '../widgets/common/location_field.dart';
import '../widgets/common/team_picker_card.dart';
import '../widgets/common/timer_frame.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({
    super.key,
    this.onSubmit,
    this.onSelectMembers,
    this.memberCount = 0,
    this.memberAvatars = const [],
    this.teamsRepository,
  });

  final ValueChanged<TeamFormState>? onSubmit;

  final VoidCallback? onSelectMembers;
  final int memberCount;
  final List<ImageProvider> memberAvatars;
  final InMemoryTeamsRepository? teamsRepository;

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final TeamFormCubit _formCubit = TeamFormCubit();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  void _saveTeam() {
    final form = _formCubit.state;
    if (form.requestDraft?.status == TeamRequestStatus.paid &&
        widget.onSubmit == null) {
      _recordPaidTeam(form.requestDraft!);
      Navigator.of(context).pop();
      return;
    }

    if (!form.canSubmit) {
      _showMessage("نام تیم را وارد کنید.");
      return;
    }

    if (widget.onSubmit == null) {
      _showMessage("ابتدا درخواست تیم و پرداخت آزمایشی را تکمیل کنید.");
      return;
    }

    widget.onSubmit!(form);
  }

  Future<void> _selectMembers() async {
    if (widget.onSelectMembers != null) {
      widget.onSelectMembers!();
      return;
    }

    final confirmed = await selectTeamMembers(context, _formCubit);
    if (mounted &&
        confirmed == true &&
        _formCubit.state.memberServices.isNotEmpty) {
      await _openRequest();
    }
  }

  Future<void> _openRequest() async {
    final form = _formCubit.state;
    final providers = form.memberServices.values.toList();
    if (providers.isEmpty) return;
    final initial =
        form.requestDraft?.copyWith(providers: providers) ??
        TeamRequest(
          providers: providers,
          schedule: form.timeFrame,
          attachments: form.attachments,
        );
    if (initial.status == TeamRequestStatus.paid) _recordPaidTeam(initial);
    final result = await Navigator.of(context).push<TeamRequest>(
      MaterialPageRoute(
        builder: (_) => TeamRequestScreen(
          initial: initial,
          onPaid: _recordPaidTeam,
          closeOnPaid: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _formCubit.updateRequestDraft(result);
    if (result.status == TeamRequestStatus.paid &&
        widget.onSubmit == null &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _recordPaidTeam(TeamRequest request) {
    if (!mounted ||
        request.status != TeamRequestStatus.paid ||
        request.paymentId == null) {
      return;
    }
    _formCubit.updateRequestDraft(request);
    final form = _formCubit.state;
    final owner = context.read<UserProfileCubit?>()?.seller ?? localPostSeller;
    (widget.teamsRepository ?? InMemoryTeamsRepository.instance).addPaid(
      TeamWorkspace(
        id: request.paymentId!,
        name: form.name.trim().isEmpty ? request.title : form.name.trim(),
        description: form.description.trim().isEmpty
            ? request.description
            : form.description.trim(),
        owner: owner,
        request: request,
        createdAt: DateTime.now(),
        providers: request.providers,
        locations: form.locations,
      ),
    );
  }

  @override
  void dispose() {
    _formCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: AppResponsiveBuilder(
        builder: (context, responsive) {
          final theme = Theme.of(context);

          final spacing = responsive.verticalSpacing;
          final padding = responsive.horizontalPadding;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: TeamHeader(
              onSave: _saveTeam,
              onBack: () {
                Navigator.of(context).maybePop();
              },
            ),
            body: BlocBuilder<TeamFormCubit, TeamFormState>(
              builder: (context, form) {
                return SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: spacing * 2),

                                TeamGeneralSection(
                                  spacing: spacing / 2,
                                  onNameChanged: _formCubit.updateName,
                                  onDescriptionChanged:
                                      _formCubit.updateDescription,
                                ),

                                SizedBox(height: spacing),

                                TeamLocationField(
                                  locations: form.locations,
                                  onChanged: _formCubit.updateLocations,
                                ),

                                SizedBox(height: spacing / 2),

                                TeamTimeFrameField(
                                  timeFrame: form.timeFrame,
                                  onChanged: _formCubit.updateTimeFrame,
                                ),

                                SizedBox(height: spacing / 2),

                                TeamPickerCard(
                                  onTap: _selectMembers,
                                  memberCount: widget.onSelectMembers != null
                                      ? widget.memberCount
                                      : form.members.length,
                                  memberAvatars: widget.onSelectMembers != null
                                      ? widget.memberAvatars
                                      : const [],
                                  members: widget.onSelectMembers == null
                                      ? form.members
                                      : const [],
                                ),

                                if (widget.onSelectMembers == null &&
                                    form.memberServices.isNotEmpty) ...[
                                  SizedBox(height: spacing / 2),
                                  AppButton(
                                    label: TeamStrings.requestProviders(
                                      form.memberServices.length,
                                    ),
                                    onPressed: _openRequest,
                                  ),
                                ],
                                SizedBox(height: spacing / 2),
                              ],
                            ),
                          ),

                          TeamAttachmentsSection(
                            attachments: form.attachments,
                            horizontalPadding: padding,
                            spacing: spacing,
                            onAddAttachments: _formCubit.addAttachments,
                            onRemoveAttachment: _formCubit.removeAttachment,
                          ),

                          SizedBox(height: spacing),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
