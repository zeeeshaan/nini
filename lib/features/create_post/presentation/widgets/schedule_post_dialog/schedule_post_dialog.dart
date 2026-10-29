import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';

class SchedulePostDialog extends StatefulWidget {
  const SchedulePostDialog({super.key, this.initial});
  final PostSchedule? initial;
  @override
  State<SchedulePostDialog> createState() => _SchedulePostDialogState();
}

class _SchedulePostDialogState extends State<SchedulePostDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late DateTime _date;
  late TimeOfDay _from, _to;
  bool _editingFrom = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, initialIndex: 1, vsync: this)
      ..addListener(_tabChanged);
    final initial = widget.initial;
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    final start = initial != null && initial.startsAt.isAfter(DateTime.now())
        ? initial.startsAt
        : nextHour;
    _date = DateUtils.dateOnly(start);
    _from = TimeOfDay.fromDateTime(start);
    _to = TimeOfDay.fromDateTime(
      initial != null && initial.endsAt.isAfter(start)
          ? initial.endsAt
          : start.add(const Duration(hours: 1)),
    );
  }

  void _tabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_tabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _save() {
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _from.hour,
      _from.minute,
    );
    var end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _to.hour,
      _to.minute,
    );
    if (_from == _to) {
      setState(() => _error = AppStrings.differentTimesRequired);
      return;
    }
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    if (!start.isAfter(DateTime.now())) {
      setState(() => _error = AppStrings.futureTimeRequired);
      return;
    }
    Navigator.of(context)
        .pop(ScheduleSelection(PostSchedule(startsAt: start, endsAt: end)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final editingFrom = _editingFrom;
    final editing = editingFrom ? _from : _to;
    return PostDialog(
      title: AppStrings.scheduledPosts,
      icon: AppIcons.calendar,
      actions: PostDialogActions(
        onDone: _save,
        doneLabel: _tabs.index == 0 ? AppStrings.add : AppStrings.done,
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
                Tab(text: AppStrings.time),
                Tab(text: AppStrings.calendar),
              ],
            ),
            SizedBox(
              height: 350,
              child: TabBarView(
                controller: _tabs,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _timeChoice(AppStrings.timeTo, _to, false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timeChoice(
                              AppStrings.timeFrom,
                              _from,
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
                              dateTimePickerTextStyle: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 28,
                                fontFamily: 'YekanBakh',
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            key: ValueKey(_editingFrom),
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            initialDateTime: DateTime(
                              _date.year,
                              _date.month,
                              _date.day,
                              editing.hour,
                              editing.minute,
                            ),
                            onDateTimeChanged: (date) => setState(() {
                              if (editingFrom) {
                                _from = TimeOfDay.fromDateTime(date);
                              } else {
                                _to = TimeOfDay.fromDateTime(date);
                              }
                              _error = null;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CalendarDatePicker(
                    initialDate: _date,
                    firstDate: today,
                    lastDate: DateTime(today.year + 5, 12, 31),
                    onDateChanged: (date) => setState(() {
                      _date = date;
                      _error = null;
                    }),
                  ),
                ],
              ),
            ),
            Text(
              '${MaterialLocalizations.of(context).formatMediumDate(_date)} · ${_from.format(context)} – ${_to.format(context)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.scheduleHelp,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            if (widget.initial != null)
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const ScheduleSelection(null)),
                child: const Text(AppStrings.removeSchedule),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeChoice(String label, TimeOfDay time, bool from) => Semantics(
    button: true,
    selected: _editingFrom == from,
    child: InkWell(
      onTap: () => setState(() => _editingFrom = from),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _editingFrom == from
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(time.format(context), textAlign: TextAlign.center),
          ),
        ],
      ),
    ),
  );
}
