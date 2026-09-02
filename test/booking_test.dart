import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/data/pending_booking_vehicle.dart';
import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/models/mechanic.dart';
import 'package:sanayi_app/screens/booking/appointment_request_page.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/booking/date_strip.dart';

import 'test_utils/fake_google_sign_in_platform.dart';
import 'test_utils/mechanic_seed.dart';

void main() {
  setUp(() async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-user-id', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
    // SearchTab now queries mechanicAccounts directly instead of MockData.
    await seedMechanicAccounts(firestoreInstance);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Müşteri Modu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Giriş Yap')),
    );
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

  testWidgets('Submitting without a time window keeps the submit button disabled', (WidgetTester tester) async {
    await pumpApp(tester);
    await openRequestPageForHizliLastikci(tester);

    // Fill in every other required field, but deliberately leave the time
    // window unselected, to isolate that specific missing requirement.
    final vehicleField = find.widgetWithText(TextField, 'Marka ve Model');
    await tester.ensureVisible(vehicleField);
    await tester.enterText(vehicleField, 'Renault Clio 2018');

    final phoneField = find.widgetWithText(TextField, 'Telefon Numarası');
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '5551234567');

    final kvkkCheckbox = find.byType(Checkbox);
    await tester.ensureVisible(kvkkCheckbox);
    await tester.tap(kvkkCheckbox);
    await tester.pumpAndSettle();

    final submitButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Randevu Talebini Gönder'),
    );
    expect(submitButton.onPressed, isNull);
  });

  testWidgets('Submitting a preferred window confirms the request and returns to the detail page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openRequestPageForHizliLastikci(tester);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = today.add(const Duration(days: 3));

    // The date strip lives inside a scrolling body where precise pixel taps
    // proved unreliable in this test harness (hit-test misses on nested
    // InkWells). Drive its callback directly instead — this still exercises
    // the real State.setState code path, just without emulating the tap
    // gesture itself. The time window chips are plain ChoiceChips with
    // visible text, so those are tapped normally below.
    tester.widget<DateStrip>(find.byType(DateStrip)).onSelected(targetDate);
    await tester.pumpAndSettle();

    final timeWindowChip = find.text('08:00 – 10:00');
    await tester.ensureVisible(timeWindowChip);
    await tester.tap(timeWindowChip);
    await tester.pumpAndSettle();

    final vehicleField = find.widgetWithText(TextField, 'Marka ve Model');
    await tester.ensureVisible(vehicleField);
    await tester.enterText(vehicleField, 'Renault Clio 2018');

    final phoneField = find.widgetWithText(TextField, 'Telefon Numarası');
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '5551234567');

    final kvkkCheckbox = find.byType(Checkbox);
    await tester.ensureVisible(kvkkCheckbox);
    await tester.tap(kvkkCheckbox);
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Randevu Talebini Gönder');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Randevu Talebiniz Alındı!'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentRequestPage), findsNothing);
    expect(find.byType(MechanicDetailPage), findsOneWidget);
  });

  testWidgets(
    'AppointmentRequestPage pre-fills vehicle/plate from a pending Araçlarım selection, '
    'and name/phone from the signed-in customer profile',
    (WidgetTester tester) async {
      firebaseAuthInstance = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'test-user-id',
          email: 'test@example.com',
          isEmailVerified: true,
          displayName: 'Ayşe Yılmaz',
          phoneNumber: '+905551234567',
        ),
        // true (not the usual false) — this test pumps AppointmentRequestPage
        // directly, bypassing the login UI other tests here drive through,
        // so currentUser needs to already be signed in for initState's
        // Firebase Auth pre-fill to see it at all.
        signedIn: true,
      );

      // Same call MyVehiclesSection makes right before reusing the "Araç
      // Tamiri" entry point — set directly here since this test pumps
      // AppointmentRequestPage on its own, without the full "Araçlarım" ->
      // sub-service -> mechanic navigation chain (already covered by
      // my_vehicles_test.dart and the category/search tests).
      PendingBookingVehicle.set(vehicleLabel: 'Renault Clio 2018', licensePlate: '34 ABC 123');

      const mechanic = Mechanic(
        name: 'Hızlı Lastikçi',
        rating: 4.7,
        reviewCount: 96,
        phone: '0212 667 45 09',
        address: 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
      );

      await tester.pumpWidget(
        const MaterialApp(home: AppointmentRequestPage(mechanic: mechanic, serviceLabel: 'Lastik Değişimi')),
      );
      await tester.pumpAndSettle();

      // Vehicle/plate from the pending Araçlarım selection.
      expect(find.text('Renault Clio 2018'), findsOneWidget);
      expect(find.text('34 ABC 123'), findsOneWidget);

      // Name from Firebase Auth displayName, phone from Firebase Auth
      // phoneNumber — converted from E.164 ("+905551234567") to this
      // form's own bare/grouped local format, not a raw pass-through.
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('555 123 45 67'), findsOneWidget);
    },
  );
}