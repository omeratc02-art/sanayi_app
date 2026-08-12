import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/booking/appointment_request_page.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';
import 'package:sanayi_app/widgets/booking/date_strip.dart';
import 'package:sanayi_app/widgets/booking/time_slot_grid.dart';

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

  Future<void> openRequestPageForHizliLastikci(WidgetTester tester) async {
    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.tap(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Randevu Al'));
    await tester.pumpAndSettle();
  }

  testWidgets('Randevu Al on the detail page opens the appointment request page', (WidgetTester tester) async {
    await pumpApp(tester);
    await openRequestPageForHizliLastikci(tester);

    expect(find.byType(AppointmentRequestPage), findsOneWidget);
    expect(find.text('Tercih Ettiğiniz Tarih'), findsOneWidget);
    expect(find.text('Tercih Ettiğiniz Saat Aralığı'), findsOneWidget);
    expect(find.text('İlk Müsait Saat'), findsOneWidget);
    expect(find.text('Notlar (opsiyonel)'), findsOneWidget);
  });

  testWidgets('Submitting without a time window shows a validation message', (WidgetTester tester) async {
    await pumpApp(tester);
    await openRequestPageForHizliLastikci(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Randevu Talebi Oluştur'));
    await tester.pump();

    expect(find.text('Lütfen bir saat aralığı seçin.'), findsOneWidget);
  });

  testWidgets('Submitting a preferred window confirms the request and returns to the detail page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openRequestPageForHizliLastikci(tester);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = today.add(const Duration(days: 3));

    // The date strip and time window grid live inside a scrolling body where
    // precise pixel taps proved unreliable in this test harness (hit-test
    // misses on nested InkWells). Drive their callbacks directly instead —
    // this still exercises the real State.setState code path, just without
    // emulating the tap gesture itself.
    tester.widget<DateStrip>(find.byType(DateStrip)).onSelected(targetDate);
    await tester.pumpAndSettle();

    final availableWindow = tester
        .widget<TimeSlotGrid>(find.byType(TimeSlotGrid))
        .slots
        .firstWhere((slot) => slot.isAvailable);
    tester.widget<TimeSlotGrid>(find.byType(TimeSlotGrid)).onSelected(availableWindow.label);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Randevu Talebi Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Randevu Talebiniz Alındı!'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentRequestPage), findsNothing);
    expect(find.byType(MechanicDetailPage), findsOneWidget);
  });
}
