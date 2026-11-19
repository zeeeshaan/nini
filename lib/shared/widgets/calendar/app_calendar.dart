import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

/// Formats the same Gregorian DateTime in the Solar Hijri calendar.
String formatSolarDate(DateTime date) {
  final jalali = Jalali.fromDateTime(date);
  return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
}

/// Calendar selection never changes the underlying Gregorian DateTime contract.
class AppCalendar extends StatefulWidget {
  const AppCalendar({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate, firstDate, lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  final _solar = ValueNotifier(true);
  late final _selected = ValueNotifier(widget.selectedDate);

  @override
  void didUpdateWidget(covariant AppCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _selected.value = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    _solar.dispose();
    _selected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _solar,
    builder: (context, solar, _) => ValueListenableBuilder<DateTime>(
      valueListenable: _selected,
      builder: (context, selected, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Solar Hijri')),
              ButtonSegment(value: false, label: Text('Gregorian')),
            ],
            selected: {solar},
            onSelectionChanged: (value) => _solar.value = value.single,
          ),
          if (solar)
            Localizations.override(
              context: context,
              locale: const Locale('fa', 'IR'),
              delegates: const [PersianMaterialLocalizations.delegate],
              child: PersianCalendarDatePicker(
                initialDate: Jalali.fromDateTime(selected),
                firstDate: Jalali.fromDateTime(widget.firstDate),
                lastDate: Jalali.fromDateTime(widget.lastDate),
                onDateChanged: (date) => _changeDate(date.toDateTime()),
              ),
            )
          else
            CalendarDatePicker(
              initialDate: selected,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDateChanged: _changeDate,
            ),
        ],
      ),
    ),
  );

  void _changeDate(DateTime date) {
    _selected.value = date;
    widget.onDateChanged(date);
  }
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  var selected = initialDate;
  return showDialog<DateTime>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: AppCalendar(
            selectedDate: selected,
            firstDate: firstDate,
            lastDate: lastDate,
            onDateChanged: (date) => selected = date,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
}
