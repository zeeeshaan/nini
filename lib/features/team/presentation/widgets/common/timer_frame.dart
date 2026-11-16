import 'package:flutter/material.dart';

import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/schedule_post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/form/post_form_option_tile.dart';

class TeamTimeFrameField extends StatelessWidget {
  const TeamTimeFrameField({
    super.key,
    required this.timeFrame,
    required this.onChanged,
  });

  final PostSchedule? timeFrame;
  final ValueChanged<PostSchedule?> onChanged;

  Future<void> _selectTimeFrame(BuildContext context) async {
    final result = await showPostDialog<ScheduleSelection>(
      context,
      SchedulePostDialog(initial: timeFrame),
    );

    if (!context.mounted || result == null) return;

    onChanged(result.schedule);
  }

  @override
  Widget build(BuildContext context) {
    String? label;

    if (timeFrame != null) {
      final dates = MaterialLocalizations.of(context);

      final start = dates.formatMediumDate(timeFrame!.startsAt);
      final end = dates.formatMediumDate(timeFrame!.endsAt);

      label = '$start - $end';
    }

    return PostFormOptionTile(
      label: "بازه زمانی پروژه",
      value: label,
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () => _selectTimeFrame(context),
    );
  }
}
