/// Persian formatting helpers: Persian digits, grouped amounts and Jalali
/// (Solar Hijri) dates, so no Latin numerals leak into the UI.
library;

const _faDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Replaces every Latin digit in [value] with its Persian counterpart.
String faDigits(Object value) => value.toString().replaceAllMapped(
  RegExp('[0-9]'),
  (m) => _faDigits[int.parse(m[0]!)],
);

/// Formats [value] with Persian digits and the Persian thousands separator,
/// e.g. 582000 -> ۵۸۲٬۰۰۰.
String faAmount(int value) => faDigits(
  value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '٬',
  ),
);

const kJalaliMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

/// Converts a Gregorian date to Jalali, returned as (year, month, day).
(int, int, int) toJalali(DateTime date) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy = date.year, gm = date.month, gd = date.day;
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days =
      355666 +
      365 * gy +
      (gy2 + 3) ~/ 4 -
      (gy2 + 99) ~/ 100 +
      (gy2 + 399) ~/ 400 +
      gd +
      gdm[gm - 1];
  var jy = -1595 + 33 * (days ~/ 12053);
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
  final jd = days < 186 ? 1 + days % 31 : 1 + (days - 186) % 30;
  return (jy, jm, jd);
}

/// e.g. ۱۵ آذر ۱۴۰۴
String faDateLong(DateTime date) {
  final (y, m, d) = toJalali(date);
  return '${faDigits(d)} ${kJalaliMonths[m - 1]} ${faDigits(y)}';
}

/// Converts a Jalali date back to Gregorian (midnight, local time).
DateTime fromJalali(int year, int month, int day) {
  // Nowruz (1 Farvardin) falls on 19–22 March; find it, then count forward.
  var nowruz = DateTime(year + 621, 3, 19);
  while (toJalali(nowruz) != (year, 1, 1)) {
    nowruz = DateTime(nowruz.year, nowruz.month, nowruz.day + 1);
  }
  final offset = month <= 6 ? (month - 1) * 31 : 186 + (month - 7) * 30;
  return DateTime(nowruz.year, nowruz.month, nowruz.day + offset + day - 1);
}

/// Number of days in a Jalali month (Esfand has 30 in leap years).
int jalaliMonthLength(int year, int month) {
  if (month <= 6) return 31;
  if (month <= 11) return 30;
  final esfand30 = fromJalali(
    year,
    12,
    1,
  ).add(const Duration(days: 29, hours: 12));
  return toJalali(esfand30).$2 == 12 ? 30 : 29;
}

/// Saturday-first single-letter weekday names.
const kFaWeekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
