import 'package:nini/features/create_post/presentation/cubit/post_schedule_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/shared/widgets/calendar/app_calendar.dart';

class SchedulePostDialog extends StatefulWidget {
  const SchedulePostDialog({super.key, this.initial});
  final PostSchedule? initial;
  @override
  State<SchedulePostDialog> createState() => _SchedulePostDialogState();
}

class _SchedulePostDialogState extends State<SchedulePostDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final _schedule = PostScheduleCubit(widget.initial);
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, initialIndex: 1, vsync: this)
      ..addListener(_tabChanged);
  }

  void _tabChanged() {
    if (mounted) _schedule.changeTab(_tabs.index);
  }

  @override
  void dispose() {
    _schedule.close();
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _save() {
    final schedule = _schedule.save();
    if (schedule != null) {
      Navigator.of(context).pop(ScheduleSelection(schedule));
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostScheduleCubit, PostScheduleState>(
    bloc: _schedule,
    builder: (context, state) {
      final theme = Theme.of(context);
      final today = DateUtils.dateOnly(DateTime.now());
      final editingFrom = _schedule.state.editingFrom;
      final editing = editingFrom ? _schedule.state.from : _schedule.state.to;
      return PostDialog(
        title: CreatePostStrings.scheduledPosts,
        icon: AppIcons.calendar,
        actions: PostDialogActions(
          onDone: _save,
          doneLabel: _tabs.index == 0
              ? CreatePostStrings.add
              : CreatePostStrings.done,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabs,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurface,
                indicatorColor: theme.colorScheme.onSurface,
                tabs: const [
                  Tab(text: CreatePostStrings.time),
                  Tab(text: CreatePostStrings.calendar),
                ],
              ),
              SizedBox(
                height: 410,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _timeChoice(
                                CreatePostStrings.timeTo,
                                _schedule.state.to,
                                false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _timeChoice(
                                CreatePostStrings.timeFrom,
                                _schedule.state.from,
                                true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoTheme(
                            data: CupertinoThemeData(
                              brightness: theme.brightness,
                              textTheme: CupertinoTextThemeData(
                                dateTimePickerTextStyle: AppTextStyles
                                    .scheduleTime
                                    .copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontFamily: AppTextStyles.fontFamily,
                                    ),
                              ),
                            ),
                            child: CupertinoDatePicker(
                              key: ValueKey(_schedule.state.editingFrom),
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: DateTime(
                                _schedule.state.date.year,
                                _schedule.state.date.month,
                                _schedule.state.date.day,
                                editing.hour,
                                editing.minute,
                              ),
                              onDateTimeChanged: (date) =>
                                  _schedule.changeTime(date, from: editingFrom),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppCalendar(
                      selectedDate: _schedule.state.date,
                      firstDate: today,
                      lastDate: DateTime(today.year + 5, 12, 31),
                      onDateChanged: _schedule.changeDate,
                    ),
                  ],
                ),
              ),
              Text(
                '${formatSolarDate(_schedule.state.date)} · ${_schedule.state.from.format(context)} – ${_schedule.state.to.format(context)}',
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              const Text(
                CreatePostStrings.scheduleHelp,
                textAlign: TextAlign.right,
                style: AppTextStyles.helper,
                textDirection: TextDirection.ltr,
              ),
              if (_schedule.state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _schedule.state.error!,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              if (widget.initial != null)
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const ScheduleSelection(null)),
                  child: const Text(
                    CreatePostStrings.removeSchedule,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _timeChoice(String label, TimeOfDay time, bool from) => Semantics(
    button: true,
    selected: _schedule.state.editingFrom == from,
    child: InkWell(
      onTap: () => _schedule.editFrom(from),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _schedule.state.editingFrom == from
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              time.format(context),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    ),
  );
}
