
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/team/presentation/cubit/team_form_cubit.dart';
import 'package:nini/features/team/presentation/helpers/select_team_members.dart';

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
  });

  final ValueChanged<TeamFormState>? onSubmit;
  final VoidCallback? onSelectMembers;

  final int memberCount;
  final List<ImageProvider> memberAvatars;

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final TeamFormCubit _formCubit = TeamFormCubit();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _saveTeam() {
    final form = _formCubit.state;

    if (!form.canSubmit) {
      _showMessage('Please enter a team name.');
      return;
    }

    if (widget.onSubmit == null) {
      _showMessage('Team saving is not connected yet.');
      return;
    }

    widget.onSubmit!(form);
  }

  void _selectMembers() {
    if (widget.onSelectMembers != null) {
      widget.onSelectMembers!();
      return;
    }

    selectTeamMembers(context, _formCubit);
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
                      constraints: const BoxConstraints(
                        maxWidth: 720,
                      ),
                      child: ListView(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: spacing * 2),

                                // General information.
                                TeamGeneralSection(
                                  spacing: spacing / 2,
                                  onNameChanged:
                                  _formCubit.updateName,
                                  onDescriptionChanged:
                                  _formCubit.updateDescription,
                                ),

                                SizedBox(height: spacing),

                                // Multiple project locations.
                                TeamLocationField(
                                  locations: form.locations,
                                  onChanged:
                                  _formCubit.updateLocations,
                                ),

                                SizedBox(height: spacing / 2),

                                // Existing date/time picker.
                                TeamTimeFrameField(
                                  timeFrame: form.timeFrame,
                                  onChanged:
                                  _formCubit.updateTimeFrame,
                                ),

                                SizedBox(height: spacing / 2),

                                // Team members.
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

                                SizedBox(height: spacing / 2),
                              ],
                            ),
                          ),

                          // Gallery, file picking and previews.
                          TeamAttachmentsSection(
                            attachments: form.attachments,
                            horizontalPadding: padding,
                            spacing: spacing,
                            onAddAttachments:
                            _formCubit.addAttachments,
                            onRemoveAttachment:
                            _formCubit.removeAttachment,
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
