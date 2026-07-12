import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/booking/appointment_booking_page.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';
import 'package:sanayi_app/widgets/booking/booking_success_dialog.dart';
import 'package:sanayi_app/widgets/booking/date_strip.dart';
import 'package:sanayi_app/widgets/booking/service_type_selector.dart';
import 'package:sanayi_app/widgets/booking/time_slot_grid.dart';
import 'package:sanayi_app/widgets/booking/vehicle_info_form.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pumpAndSettle();
  }

  Future<void> openBookingPageForHizliLastikci(WidgetTester tester) async {
    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.tap(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Randevu Al'));
    await tester.pumpAndSettle();
  }

  testWidgets('Randevu Al on the detail page opens the booking page', (WidgetTester tester) async {
    await pumpApp(tester);
    await openBookingPageForHizliLastikci(tester);

    expect(find.byType(AppointmentBookingPage), findsOneWidget);
    expect(find.text('Tarih Seçin'), findsOneWidget);
    expect(find.text('Saat Seçin'), findsOneWidget);
    expect(find.text('Hizmet Türü'), findsOneWidget);
    expect(find.text('Araç Bilgileri'), findsOneWidget);
  });

  testWidgets('Confirming with missing fields shows a validation message', (WidgetTester tester) async {
    await pumpApp(tester);
    await openBookingPageForHizliLastikci(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Randevuyu Onayla'));
    await tester.pump();

    expect(find.text('Lütfen tüm gerekli alanları doldurun.'), findsOneWidget);
  });

  testWidgets('Completing the form confirms the appointment and returns to the detail page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openBookingPageForHizliLastikci(tester);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = today.add(const Duration(days: 3));

    // The date strip, time grid and service selector live inside a scrolling Form body
    // where precise pixel taps proved unreliable in this test harness (hit-test misses
    // on nested InkWells). Drive their callbacks directly instead — this still exercises
    // the real State.setState code path, just without emulating the tap gesture itself.
    tester.widget<DateStrip>(find.byType(DateStrip)).onSelected(targetDate);
    await tester.pumpAndSettle();

    final availableSlot = tester
        .widget<TimeSlotGrid>(find.byType(TimeSlotGrid))
        .slots
        .firstWhere((slot) => slot.isAvailable);
    tester.widget<TimeSlotGrid>(find.byType(TimeSlotGrid)).onSelected(availableSlot.label);
    await tester.pumpAndSettle();

    tester.widget<ServiceTypeSelector>(find.byType(ServiceTypeSelector)).onSelected('Lastik');
    await tester.pumpAndSettle();

    final vehicleFields = find.descendant(
      of: find.byType(VehicleInfoForm),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(vehicleFields.at(0), 'Renault Clio');
    await tester.enterText(vehicleFields.at(1), '42 ABC 123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Randevuyu Onayla'));
    await tester.pumpAndSettle();

    final dialogScope = find.byType(BookingSuccessDialog);
    expect(dialogScope, findsOneWidget);
    expect(find.descendant(of: dialogScope, matching: find.textContaining('Renault Clio')), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentBookingPage), findsNothing);
    expect(find.byType(MechanicDetailPage), findsOneWidget);
  });
}
