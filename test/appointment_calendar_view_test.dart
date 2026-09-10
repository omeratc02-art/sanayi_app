import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/appointments/appointment_calendar_view.dart';
import 'package:sanayi_app/mechanic/appointments/data/appointment.dart';

/// Covers the fix for the desktop-vs-mobile date-strip discrepancy found in
/// the earlier investigation: AppointmentCalendarView always renders 7 real
/// day columns at a fixed 104px width regardless of viewport, so a phone
/// showed only ~1.5 fully-visible columns with the rest reachable only by
/// an undiscoverable horizontal swipe. resolveDayColumnWidth now shrinks
/// columns to fit exactly 3 on a narrow viewport (floored so
/// _AppointmentBlock's text never becomes unreadable), and keeps the
/// original fixed 104px width unchanged whenever all 7 already fit.
// Mirrors resolveDayColumnWidth's own private _minDayColumnWidth constant
// (not accessible here — different library) — kept as one named constant
// rather than a repeated magic number so the two widget tests that rely on
// this exact value stay obviously in sync with each other.
const _minDayColumnWidthForTests = 68.0;

void main() {
  group('resolveDayColumnWidth (pure function)', () {
    test('Desktop/tablet: wide enough for all 7 columns at 104px — returns exactly 104.0, unchanged', () {
      expect(resolveDayColumnWidth(1200), 104.0);
      // The exact boundary — 7 * 104 = 728 — must still count as "fits".
      expect(resolveDayColumnWidth(728), 104.0);
    });

    test('Narrower than 7 columns at 104px, but 3 columns at width/3 is still above the readability floor', () {
      // 300 / 3 = 100, comfortably above the 68px floor.
      expect(resolveDayColumnWidth(300), 100.0);
    });

    test('Narrow enough that width/3 would fall below the floor — clamps to the 68px minimum instead', () {
      // 150 / 3 = 50, below the floor — must clamp up to 68, not shrink further.
      expect(resolveDayColumnWidth(150), _minDayColumnWidthForTests);
    });

    test('Exactly at the floor boundary (204 / 3 = 68) resolves to exactly 68.0, not fractionally below', () {
      expect(resolveDayColumnWidth(204), _minDayColumnWidthForTests);
    });
  });

  group('AppointmentCalendarView (widget) — column width adapts to real viewport width', () {
    void setPhysicalSize(WidgetTester tester, double width, double height) {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    // The real day-strip's own viewport — the horizontally-scrolling
    // SingleChildScrollView inside _DayStrip, distinct from the whole
    // widget's own outer (vertical) SingleChildScrollView. Measuring this
    // widget's rendered width directly (rather than hand-deriving it from
    // the hour-column/arrow-chrome pixel constants, which would duplicate
    // implementation details a test shouldn't need to know) gives exactly
    // the `availableWidth` the real LayoutBuilder measured and passed to
    // resolveDayColumnWidth.
    double measureDayStripViewportWidth(WidgetTester tester) {
      final finder = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.horizontal,
      );
      return tester.getSize(finder).width;
    }

    double measureColumnWidth(WidgetTester tester, DateTime date) {
      return tester.getSize(find.byKey(ValueKey(date))).width;
    }

    final monday = DateTime(2026, 9, 7); // a real Monday, per the original screenshot's own "Pzt 07 Eyl".
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    testWidgets(
      'Phone width: exactly 3 day columns fit fully within the viewport, none partially clipped',
      (WidgetTester tester) async {
        // Chosen so the strip's own available width (viewport minus the
        // fixed hour column and week-jump arrows) divides three ways to
        // something comfortably above _minDayColumnWidth — this
        // specifically exercises the "shrink to exactly 3, evenly" branch
        // (not the floor-clamped one — see the narrower test below for
        // that), so this test's own intent isn't ambiguous between the two.
        setPhysicalSize(tester, 460, 800);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCalendarView(
                selectedDate: monday,
                appointments: const [],
                onWeekChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        final viewportWidth = measureDayStripViewportWidth(tester);
        final expectedColumnWidth = resolveDayColumnWidth(viewportWidth);

        // Genuinely exercising the intended "shrink to fit 3" branch, not
        // the readability floor from the test below.
        expect(expectedColumnWidth, greaterThan(_minDayColumnWidthForTests));

        // Exactly 3 whole columns fit; a 4th genuinely would not.
        expect(3 * expectedColumnWidth, lessThanOrEqualTo(viewportWidth));
        expect(4 * expectedColumnWidth, greaterThan(viewportWidth));

        // Every one of the 7 real columns (not just the visible ones) was
        // actually laid out at that same resolved width — proving the
        // strip is a real horizontal scroll containing all 7 days, not a
        // truncated 3-day view.
        for (final date in weekDates) {
          expect(measureColumnWidth(tester, date), expectedColumnWidth);
        }
      },
    );

    testWidgets(
      'Unusually narrow phone: the readability floor means fewer than 3 columns fit, not illegibly narrow ones',
      (WidgetTester tester) async {
        // availableWidth/3 here falls below _minDayColumnWidth, so
        // resolveDayColumnWidth clamps up to the floor instead of shrinking
        // further — the explicitly accepted tradeoff (see its own doc
        // comment): showing fewer than 3 fully-visible columns rather than
        // unreadable text.
        setPhysicalSize(tester, 358, 800);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCalendarView(
                selectedDate: monday,
                appointments: const [],
                onWeekChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        final viewportWidth = measureDayStripViewportWidth(tester);
        final expectedColumnWidth = resolveDayColumnWidth(viewportWidth);

        expect(expectedColumnWidth, _minDayColumnWidthForTests);
        // The floor itself doesn't let even 3 columns fit at this width —
        // fewer than 3 are fully visible here, by design.
        expect(3 * expectedColumnWidth, greaterThan(viewportWidth));

        for (final date in weekDates) {
          expect(measureColumnWidth(tester, date), expectedColumnWidth);
        }
      },
    );

    testWidgets(
      'Desktop width: all 7 columns remain visible at the original fixed 104px width, unchanged from before',
      (WidgetTester tester) async {
        setPhysicalSize(tester, 1600, 900);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCalendarView(
                selectedDate: monday,
                appointments: const [],
                onWeekChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        final viewportWidth = measureDayStripViewportWidth(tester);
        expect(viewportWidth, greaterThanOrEqualTo(7 * 104.0));

        for (final date in weekDates) {
          expect(measureColumnWidth(tester, date), 104.0);
        }
      },
    );

    testWidgets(
      'The header-only (empty-week) strip and the grid-with-appointments strip resolve to the exact same '
      'column width at the same viewport size — header and grid stay pixel-aligned',
      (WidgetTester tester) async {
        setPhysicalSize(tester, 400, 800);

        // Empty-week branch (showGrid == false) — header-only strip.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCalendarView(
                selectedDate: monday,
                appointments: const [],
                onWeekChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        final emptyWeekColumnWidth = measureColumnWidth(tester, monday);

        // Grid branch (showGrid == true) — a real appointment on the
        // selected day forces the hourly grid to render instead.
        final realAppointment = Appointment(
          appointmentId: 'calendar-width-test-appt',
          customerId: 'test-customer',
          customerName: 'Test Müşteri',
          customerPhone: '5551234567',
          vehicleModel: 'Renault Clio',
          licensePlate: '34ABC123',
          serviceType: 'Genel Bakım',
          appointmentDate: monday,
          appointmentTime: const TimeOfDay(hour: 10, minute: 0),
          estimatedDuration: const Duration(minutes: 60),
          customerNote: '',
          status: AppointmentStatus.accepted,
          createdAt: monday,
          distance: '',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCalendarView(
                selectedDate: monday,
                appointments: [realAppointment],
                onWeekChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        final gridColumnWidth = measureColumnWidth(tester, monday);

        expect(gridColumnWidth, emptyWeekColumnWidth);
      },
    );
  });
}
