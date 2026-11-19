import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/shared/widgets/calendar/app_calendar.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/schedule_post_dialog.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() {
  test('Solar Hijri conversion uses the real Gregorian calendar day', () {
    expect(formatSolarDate(DateTime(2024, 3, 20)), '1403/01/01');
    expect(formatSolarDate(DateTime(2025, 3, 20)), '1403/12/30');
    expect(formatSolarDate(DateTime(2025, 3, 21)), '1404/01/01');
  });

  testWidgets(
    'switching calendars keeps selection and returns Gregorian date',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2024, 3, 20),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(PersianCalendarDatePicker), findsOneWidget);
      tester
          .widget<PersianCalendarDatePicker>(
            find.byType(PersianCalendarDatePicker),
          )
          .onDateChanged(Jalali(1403, 1, 2));
      await tester.pump();
      await tester.tap(find.text('Gregorian'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
            .initialDate,
        DateTime(2024, 3, 21),
      );
      await tester.tap(find.text('Solar Hijri'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PersianCalendarDatePicker>(
              find.byType(PersianCalendarDatePicker),
            )
            .initialDate,
        Jalali(1403, 1, 2),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2024, 3, 21));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared scheduling calendar opens and switches without overflow',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePostDialog())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PersianCalendarDatePicker), findsOneWidget);
      await tester.tap(find.text('Gregorian'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
