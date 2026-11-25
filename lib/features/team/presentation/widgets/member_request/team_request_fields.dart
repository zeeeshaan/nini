import 'package:nini/shared/widgets/calendar/app_calendar.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/schedule_post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TeamRequestFields extends StatefulWidget {
  const TeamRequestFields({
    super.key,
    required this.request,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onScheduleChanged,
    required this.spacing,
  });

  final TeamRequest request;
  final ValueChanged<String> onTitleChanged, onDescriptionChanged;
  final ValueChanged<PostSchedule> onScheduleChanged;
  final double spacing;

  @override
  State<TeamRequestFields> createState() => _TeamRequestFieldsState();
}

class _TeamRequestFieldsState extends State<TeamRequestFields> {
  late final _title = TextEditingController(text: widget.request.title);
  late final _description = TextEditingController(
    text: widget.request.description,
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final result = await showPostDialog<ScheduleSelection>(
      context,
      SchedulePostDialog(initial: widget.request.schedule),
    );
    final schedule = result?.schedule;
    if (context.mounted && schedule != null) widget.onScheduleChanged(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.request.schedule;
    final dates = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _title,
          hint: 'Title',
          textStyle: AppTextStyles.bodyText,
          onChanged: widget.onTitleChanged,
        ),
        SizedBox(height: widget.spacing),
        AppTextField(
          controller: _description,
          hint: 'Description',
          maxLines: 5,
          textStyle: AppTextStyles.bodyText,
          onChanged: widget.onDescriptionChanged,
        ),
        SizedBox(height: widget.spacing),
        PostFormOptionTile(
          label: 'Start Date',
          value: schedule == null
              ? null
              : '${formatSolarDate(schedule.startsAt)} · ${dates.formatTimeOfDay(TimeOfDay.fromDateTime(schedule.startsAt))}',
          trailing: const AppIcon(AppIcons.calendar, size: 20),
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }
}
