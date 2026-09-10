import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/appointments/data/appointment.dart';
import 'package:sanayi_app/mechanic/appointments/data/appointment_repository.dart';
import 'package:sanayi_app/mechanic/appointments/mechanic_appointment_details_page.dart';
import 'package:sanayi_app/models/mechanic.dart';
import 'package:sanayi_app/screens/appointments/appointments_tab.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

/// Real, Firestore-backed completion -> customer-confirmation -> rating flow
/// (Appointment.tamamlanmaDurumu): mechanic marks a job complete
/// (MechanicAppointmentDetailsPage's _CompletionActionBar ->
/// AppointmentRepository.markMechanicCompleted), the customer sees a real
/// confirmation banner (AppointmentsTab's _CompletionVerificationCard) and
/// either verifies (optionally with a star rating + comment ->
/// markCustomerVerified) or disputes (markCustomerDisputed). Every
/// assertion reads the fake Firestore document directly (or, for the last
/// test, a second real widget) rather than just UI state, mirroring
/// appointment_negotiation_test.dart's own real-write verification style.
void main() {
  const mechanicUid = 'test-mechanic-uid';
  const businessId = 'hizli-lastikci'; // matches mechanicChatId('Hızlı Lastikçi')
  const customerUid = 'test-customer-uid';
  const appointmentId = 'test-completion-appt';

  final appointmentDate = DateTime.utc(2026, 9, 10, 12);
  const appointmentTimeString = '10:00';

  setUp(() {
    firestoreInstance = FakeFirebaseFirestore();
  });

  Future<void> seedMechanicAccount() {
    return firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).set({
      'name': 'Hızlı Lastikçi',
      'businessId': businessId,
      'email': 'usta@example.com',
      'isVerified': true,
    });
  }

  /// Same Turkish-field shape as appointment_negotiation_test.dart's own
  /// seedAppointment helper.
  Future<void> seedAppointment({required String id, required Map<String, dynamic> extraFields}) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'randevu_kimliği': id,
      'müşteri_kimliği': customerUid,
      'müşteriAdı': 'Test Müşteri',
      'müşteriTelefonu': '5551234567',
      'araçModeli': 'Renault Clio',
      'plaka': '34ABC123',
      'hizmetTürü': 'Lastik Değişimi',
      'randevuTarihi': Timestamp.fromDate(appointmentDate),
      'randevu_zamani': appointmentTimeString,
      'tahminiSüreDakika': 60,
      'müşteriNotu': '',
      'oluşturulma_tarihi': Timestamp.fromDate(DateTime.now()),
      'mesafe': '',
      'işletme_kimliği': businessId,
      'durum': 'kabul edildi',
      'tamamlanmaDurumu': 'beklemede',
      ...extraFields,
    });
  }

  Future<Map<String, dynamic>> readAppointment(String id) async {
    final doc = await firestoreInstance.collection('randevular').doc(id).get();
    return doc.data()!;
  }

  void setPhoneSize(WidgetTester tester) {
    // 430, not 400 — wide enough that MechanicDetailPage's _RatingSummaryRow
    // (pumped bare, without the app's real theme/font in the last test
    // below) doesn't overflow by a few px the way it would under the
    // default test font at 400.
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Builds the real [Appointment] object MechanicAppointmentDetailsPage is
  /// pumped with, straight from the same data seedAppointment just wrote —
  /// so the widget-under-test and the Firestore document it writes back to
  /// are guaranteed consistent, never hand-duplicated separately.
  Future<Appointment> buildSeededAppointment({required String id, required Map<String, dynamic> extraFields}) async {
    await seedAppointment(id: id, extraFields: extraFields);
    return Appointment.fromFirestore(await readAppointment(id), id);
  }

  group('Mechanic marks a job completed', () {
    testWidgets(
      'İşi Tamamladım writes tamamlanmaDurumu: usta_onayladi_bekleniyor and the action bar disappears',
      (WidgetTester tester) async {
        firebaseAuthInstance = MockFirebaseAuth(
          mockUser: MockUser(uid: mechanicUid, email: 'usta@example.com', isEmailVerified: true),
          signedIn: true,
        );
        final appointment = await buildSeededAppointment(id: appointmentId, extraFields: const {});
        setPhoneSize(tester);

        await tester.pumpWidget(MaterialApp(home: MechanicAppointmentDetailsPage(appointment: appointment)));
        await tester.pumpAndSettle();

        expect(find.text('İşi Tamamladım'), findsOneWidget);

        await tester.tap(find.text('İşi Tamamladım'));
        await tester.pumpAndSettle();

        // The mechanic's own confirmation dialog, telling them the
        // customer's approval is what's needed next.
        expect(find.text('İş Tamamlandı Olarak İşaretlendi'), findsOneWidget);
        await tester.tap(find.text('Tamam'));
        await tester.pumpAndSettle();

        expect(find.text('İşi Tamamladım'), findsNothing);

        final data = await readAppointment(appointmentId);
        expect(data['tamamlanmaDurumu'], 'usta_onayladi_bekleniyor');
        expect(data['ustaTamamlamaTarihi'], isNotNull);
      },
    );
  });

  group('Customer sees the completion-verification banner', () {
    const bannerPrompt = 'tamamlandı olarak işaretlendi. Onaylıyor musunuz?';

    testWidgets(
      'Shown for an appointment awaiting verification, and only that one — not for one still beklemede',
      (WidgetTester tester) async {
        firebaseAuthInstance = MockFirebaseAuth(
          mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
          signedIn: true,
        );
        await seedAppointment(
          id: appointmentId,
          extraFields: const {'tamamlanmaDurumu': 'usta_onayladi_bekleniyor'},
        );
        await seedAppointment(id: 'other-appt-still-pending', extraFields: const {'tamamlanmaDurumu': 'beklemede'});
        setPhoneSize(tester);

        await tester.pumpWidget(const MaterialApp(home: AppointmentsTab()));
        await tester.pumpAndSettle();

        expect(find.textContaining(bannerPrompt), findsOneWidget);
      },
    );

    testWidgets('Not shown at all when no appointment is awaiting verification', (WidgetTester tester) async {
      firebaseAuthInstance = MockFirebaseAuth(
        mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
        signedIn: true,
      );
      await seedAppointment(id: appointmentId, extraFields: const {'tamamlanmaDurumu': 'beklemede'});
      setPhoneSize(tester);

      await tester.pumpWidget(const MaterialApp(home: AppointmentsTab()));
      await tester.pumpAndSettle();

      expect(find.textContaining(bannerPrompt), findsNothing);
    });
  });

  group('Customer confirms completion (Evet, tamamlandı)', () {
    Future<void> pumpAwaitingVerification(WidgetTester tester) async {
      firebaseAuthInstance = MockFirebaseAuth(
        mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
        signedIn: true,
      );
      await seedAppointment(
        id: appointmentId,
        extraFields: const {'tamamlanmaDurumu': 'usta_onayladi_bekleniyor'},
      );
      setPhoneSize(tester);

      await tester.pumpWidget(const MaterialApp(home: AppointmentsTab()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Evet, tamamlandı'));
      await tester.pumpAndSettle();
      expect(find.text('Randevu Tamamlandı mı?'), findsOneWidget);
    }

    testWidgets('A star rating and comment are both written, tamamlanmaDurumu becomes dogrulanmis_tamamlandi', (
      WidgetTester tester,
    ) async {
      await pumpAwaitingVerification(tester);

      // 5 unfilled stars are all Icons.star_border_rounded initially; the
      // 5th (index 4) is a genuine 5-star rating.
      await tester.tap(find.byIcon(Icons.star_border_rounded).at(4));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Harika iş çıkardılar.');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Onayla'));
      await tester.pumpAndSettle();

      final data = await readAppointment(appointmentId);
      expect(data['tamamlanmaDurumu'], 'dogrulanmis_tamamlandi');
      expect(data['musteriPuani'], 5);
      expect(data['musteriYorumu'], 'Harika iş çıkardılar.');
      expect(data['musteriOnayTarihi'], isNotNull);
    });

    testWidgets(
      'The rating and comment are genuinely optional — confirming with neither still verifies completion, '
      'without writing musteriPuani/musteriYorumu at all',
      (WidgetTester tester) async {
        await pumpAwaitingVerification(tester);

        // No star tapped, no comment entered — straight to Onayla.
        await tester.tap(find.widgetWithText(ElevatedButton, 'Onayla'));
        await tester.pumpAndSettle();

        final data = await readAppointment(appointmentId);
        expect(data['tamamlanmaDurumu'], 'dogrulanmis_tamamlandi');
        expect(data['musteriOnayTarihi'], isNotNull);
        expect(data.containsKey('musteriPuani'), isFalse);
        expect(data.containsKey('musteriYorumu'), isFalse);
      },
    );
  });

  group('Customer disputes completion (Hayır, öyle değildi)', () {
    testWidgets('tamamlanmaDurumu becomes anlasmazlik, and no rating/comment fields are written', (
      WidgetTester tester,
    ) async {
      firebaseAuthInstance = MockFirebaseAuth(
        mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
        signedIn: true,
      );
      await seedAppointment(
        id: appointmentId,
        extraFields: const {'tamamlanmaDurumu': 'usta_onayladi_bekleniyor'},
      );
      setPhoneSize(tester);

      await tester.pumpWidget(const MaterialApp(home: AppointmentsTab()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hayır, öyle değildi'));
      await tester.pumpAndSettle();
      expect(find.text('Randevu Tamamlanmadı mı?'), findsOneWidget);

      await tester.tap(find.text('Evet, Bildir'));
      await tester.pumpAndSettle();

      final data = await readAppointment(appointmentId);
      expect(data['tamamlanmaDurumu'], 'anlasmazlik');
      expect(data.containsKey('musteriPuani'), isFalse);
      expect(data.containsKey('musteriYorumu'), isFalse);
      expect(data.containsKey('musteriOnayTarihi'), isFalse);
    });
  });

  testWidgets(
    'A rating written via customer verification genuinely feeds fetchRatingSummary / MechanicDetailPage\'s '
    'rating row, end to end',
    (WidgetTester tester) async {
      firebaseAuthInstance = MockFirebaseAuth(
        mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
        signedIn: true,
      );
      await seedMechanicAccount();
      await seedAppointment(
        id: appointmentId,
        extraFields: const {'tamamlanmaDurumu': 'usta_onayladi_bekleniyor'},
      );
      setPhoneSize(tester);

      // Real customer verification through the actual UI — same as the
      // "star rating and comment are both written" test above.
      await tester.pumpWidget(const MaterialApp(home: AppointmentsTab()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet, tamamlandı'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_border_rounded).at(4));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Onayla'));
      await tester.pumpAndSettle();
      expect((await readAppointment(appointmentId))['musteriPuani'], 5);

      // Directly confirms the repository-level aggregate first — the exact
      // computation _RatingSummaryRow's FutureBuilder relies on.
      final summary = await AppointmentRepository().fetchRatingSummary(businessId);
      expect(summary.averageRating, 5.0);
      expect(summary.ratedCount, 1);

      // Then a completely separate, freshly-pumped real widget — proving
      // the connection all the way to what a customer actually sees on
      // MechanicDetailPage, not just the repository call underneath it.
      await tester.pumpWidget(
        const MaterialApp(
          home: MechanicDetailPage(
            mechanic: Mechanic(
              name: 'Hızlı Lastikçi',
              rating: 0,
              reviewCount: 0,
              phone: '0212 667 45 09',
              address: 'Test Adres',
              priceMin: 200,
              priceMax: 380,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('(1 değerlendirme)'), findsOneWidget);
    },
  );
}
