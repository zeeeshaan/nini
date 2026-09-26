import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../utils/fa.dart';

/// Opens the dark "Scheduled posts" sheet and resolves to the picked date
/// and time, or null when cancelled. [title] replaces the sheet heading,
/// e.g. for the limited-time discount end date.
Future<DateTime?> showScheduleSheet(
  BuildContext context, {
  DateTime? initial,
  String title = 'پست‌های زمان‌بندی‌شده',
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.deepBlack,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ScheduleSheet(initial: initial, title: title),
  );
}

const _white = AppColors.pureWhite;
const _muted = AppColors.midGray;

enum _Tab { time, calendar }

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({this.initial, required this.title});

  final DateTime? initial;
  final String title;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late final DateTime _today = _dateOnly(DateTime.now());
  late final DateTime _start =
      widget.initial ?? DateTime.now().add(const Duration(hours: 1));

  late DateTime _day = _dateOnly(_start);
  late int _hour = _start.hour;
  late int _minute = _start.minute;
  _Tab _tab = _Tab.calendar;

  // The Jalali month on screen.
  late int _year = toJalali(_day).$1;
  late int _month = toJalali(_day).$2;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _shiftMonth(int delta) {
    setState(() {
      final index = _year * 12 + (_month - 1) + delta;
      _year = index ~/ 12;
      _month = index % 12 + 1;
    });
  }

  bool get _canGoBack {
    final (ty, tm, _) = toJalali(_today);
    return _year * 12 + _month > ty * 12 + tm;
  }

  void _done() {
    final at = DateTime(_day.year, _day.month, _day.day, _hour, _minute);
    if (at.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('زمان انتخاب‌شده گذشته است')),
      );
      return;
    }
    Navigator.of(context).pop(at);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 18),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: _white,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Tabs(value: _tab, onChanged: (t) => setState(() => _tab = t)),
            const SizedBox(height: 14),
            SizedBox(
              height: 300,
              child: switch (_tab) {
                _Tab.calendar => _buildCalendar(),
                _Tab.time => _TimeWheels(
                  hour: _hour,
                  minute: _minute,
                  onHour: (h) => _hour = h,
                  onMinute: (m) => _minute = m,
                ),
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _done,
                    style: FilledButton.styleFrom(
                      backgroundColor: _white,
                      foregroundColor: AppColors.deepBlack,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('تأیید'),
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _white,
                      side: const BorderSide(color: _white),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('انصراف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final first = fromJalali(_year, _month, 1);
    final length = jalaliMonthLength(_year, _month);
    // Saturday-first: DateTime.saturday (6) -> column 0.
    final lead = (first.weekday + 1) % 7;
    return Column(
      children: [
        Row(
          children: [
            _MonthMenu(
              year: _year,
              month: _month,
              onPicked: (y, m) => setState(() {
                _year = y;
                _month = m;
              }),
            ),
            const Spacer(),
            IconButton(
              onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
              color: _white,
              disabledColor: AppColors.dividerOnDark,
              // Chevrons mirror under RTL, so "left" points back (→).
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              color: _white,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final w in kFaWeekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 36,
            ),
            itemCount: lead + length,
            itemBuilder: (_, i) {
              if (i < lead) return const SizedBox.shrink();
              final dayNum = i - lead + 1;
              final date = DateTime(
                first.year,
                first.month,
                first.day + i - lead,
              );
              final past = date.isBefore(_today);
              return _DayCell(
                label: faDigits(dayNum),
                selected: date == _day,
                today: date == _today,
                disabled: past,
                onTap: () => setState(() => _day = date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.value, required this.onChanged});

  final _Tab value;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_Tab t, String label) => Expanded(
      child: InkWell(
        onTap: () => onChanged(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: t == value ? _white : _muted,
                fontSize: 13.5,
                fontWeight: t == value ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.dividerOnDark),
          bottom: BorderSide(color: AppColors.dividerOnDark),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            tab(_Tab.time, 'ساعت'),
            const VerticalDivider(width: 1, color: AppColors.dividerOnDark),
            tab(_Tab.calendar, 'تقویم'),
          ],
        ),
      ),
    );
  }
}

/// "Mehr 1404 ▾": jumps straight to any of the next 12 months.
class _MonthMenu extends StatelessWidget {
  const _MonthMenu({
    required this.year,
    required this.month,
    required this.onPicked,
  });

  final int year;
  final int month;
  final void Function(int year, int month) onPicked;

  @override
  Widget build(BuildContext context) {
    final (ty, tm, _) = toJalali(DateTime.now());
    return PopupMenuButton<(int, int)>(
      onSelected: (v) => onPicked(v.$1, v.$2),
      color: AppColors.surfaceOnDark,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (var i = 0; i < 12; i++)
          () {
            final index = ty * 12 + (tm - 1) + i;
            final y = index ~/ 12, m = index % 12 + 1;
            return PopupMenuItem(
              value: (y, m),
              child: Text(
                '${kJalaliMonths[m - 1]} ${faDigits(y)}',
                style: TextStyle(
                  color: _white,
                  fontWeight: y == year && m == month
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            );
          }(),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              '${kJalaliMonths[month - 1]} ${faDigits(year)}',
              style: const TextStyle(
                color: _white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: _white),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.selected,
    required this.today,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool today;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkResponse(
        onTap: disabled ? null : onTap,
        radius: 18,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _white : null,
            border: today && !selected ? Border.all(color: _white) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.deepBlack
                  : disabled
                  ? AppColors.dividerOnDark
                  : _white,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hour and minute wheels, shown left-to-right as HH : MM.
class _TimeWheels extends StatelessWidget {
  const _TimeWheels({
    required this.hour,
    required this.minute,
    required this.onHour,
    required this.onMinute,
  });

  final int hour;
  final int minute;
  final ValueChanged<int> onHour;
  final ValueChanged<int> onMinute;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: AppColors.surfaceOnDark,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Wheel(count: 24, initial: hour, onChanged: onHour),
              ),
              const Text(
                ':',
                style: TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: _Wheel(count: 60, initial: minute, onChanged: onMinute),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.count,
    required this.initial,
    required this.onChanged,
  });

  final int count;
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.initial,
  );
  late int _value = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 44,
      diameterRatio: 1.6,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        setState(() => _value = i % widget.count);
        widget.onChanged(_value);
      },
      childDelegate: ListWheelChildLoopingListDelegate(
        children: [
          for (var i = 0; i < widget.count; i++)
            Center(
              child: Text(
                faDigits(i.toString().padLeft(2, '0')),
                style: TextStyle(
                  color: i == _value ? _white : _muted,
                  fontSize: i == _value ? 22 : 17,
                  fontWeight: i == _value ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
