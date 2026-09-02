import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/mechanic/appointments/appointment_calendar_view.dart';
import 'package:sanayi_app/mechanic/appointments/mechanic_request_details_page.dart';
import 'package:sanayi_app/screens/notifications/notifications_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

/// Real, Firestore-backed "propose a different time" negotiation flow —
/// covers all 4 states the task asked for: mechanic proposes, customer
/// accepts; and separately, customer counter-proposes, mechanic accepts the
/// counter-proposal. Every assertion reads the fake Firestore document
/// directly, so these prove the actual writes, not just UI state.
void main() {
  const mechanicUid = 'test-mechanic-uid';
  const businessId = 'hizli-lastikci'; // matches mechanicChatId('Hızlı Lastikçi')
  const customerUid = 'test-customer-uid';
  const appointmentId = 'test-appt-1';

  // The appointment's original confirmed time — must stay untouched
  // throughout every negotiation step except a final accept.
  final originalDate = DateTime.utc(2026, 9, 10, 12);
  const originalTimeString = '10:00';

  setUp(() {
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  Future<void> seedMechanicAccount() {
    return firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).set({
      'name': 'Hızlı Lastikçi',
      'businessId': businessId,
      'email': 'usta@example.com',
      'role': 'mechanic',
      'isVerified': true,
      'rating': 4.7,
      'reviewCount': 96,
    });
  }

  Future<void> seedAppointment(Map<String, dynamic> extraFields) {
    return firestoreInstance.collection('randevular').doc(appointmentId).set({
      'randevu_kimliği': appointmentId,
      'müşteri_kimliği': customerUid,
      'müşteriAdı': 'Test Müşteri',
      'müşteriTelefonu': '5551234567',
      'araçModeli': 'Renault Clio',
      'plaka': '34ABC123',
      'hizmetTürü': 'Lastik Değişimi',
      'randevuTarihi': Timestamp.fromDate(originalDate),
      'randevu_zamani': originalTimeString,
      'tahminiSüreDakika': 60,
      'müşteriNotu': 'Tercih edilen saat aralığı: 10:00 – 12:00',
      'oluşturulma_tarihi': Timestamp.fromDate(DateTime.now()),
      'mesafe': '',
      'işletme_kimliği': businessId,
      'kvkkOnaylandi': true,
      'tamamlanmaDurumu': 'beklemede',
      ...extraFields,
    });
  }

  Future<Map<String, dynamic>> readAppointment() async {
    final doc = await firestoreInstance.collection('randevular').doc(appointmentId).get();
    return doc.data()!;
  }

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Both showDatePicker/showTimePicker are opened in input mode (see
  // pickProposedDateTime) so this drives real text fields, not a calendar
  // grid or dial — deterministic regardless of which month/day the
  // calendar would otherwise be showing.
  Future<void> respondToDateTimePicker(WidgetTester tester, {required DateTime date, required TimeOfDay time}) async {
    final dateText = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    await tester.enterText(find.byType(TextField), dateText);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final timeFields = find.byType(TextField);
    await tester.enterText(timeFields.at(0), '$hour12');
    await tester.enterText(timeFields.at(1), time.minute.toString().padLeft(2, '0'));
    await tester.tap(find.text(time.period == DayPeriod.am ? 'AM' : 'PM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> signInAsMechanicAndOpenRequestDetails(WidgetTester tester) async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: mechanicUid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: false,
    );
    setPhoneSize(tester);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Usta Modu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test: Usta Girişi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lastik Değişimi'));
    await tester.pumpAndSettle();
    expect(find.byType(MechanicRequestDetailsPage), findsOneWidget);
  }

  Future<void> signInAsMechanicAndOpenAppointmentsScreen(WidgetTester tester) async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: mechanicUid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: false,
    );
    setPhoneSize(tester);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Usta Modu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test: Usta Girişi'));
    await tester.pumpAndSettle();

    // Bottom-nav "Randevular" tab — MechanicAppointmentsScreen, defaulting
    // to its "Yeni Talepler" sub-tab.
    await tester.tap(find.text('Randevular'));
    await tester.pumpAndSettle();
  }

  Future<void> signInAsCustomerAndOpenNotifications(WidgetTester tester) async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    setPhoneSize(tester);

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

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
  }

  testWidgets('Mechanic proposes a time: writes a real teklif, leaves the current time untouched', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedAppointment({'durum': 'beklemede'});
    await signInAsMechanicAndOpenRequestDetails(tester);

    await tester.tap(find.text('Başka Saat Öner'));
    await tester.pumpAndSettle();

    // Now opens the mechanic's own appointment calendar
    // (_ProposeTimeCalendarPage) instead of a generic date/time picker.
    // Its empty-slot cells are bare InkWells with no text/key (see
    // appointment_calendar_view.dart's _positionedSlotTap), so drive the
    // real onSlotSelected callback directly — the same established pattern
    // as the calendar-tap test further down this file.
    final calendarView = tester.widget<AppointmentCalendarView>(find.byType(AppointmentCalendarView));
    calendarView.onSlotSelected!(DateTime(2026, 9, 20, 14, 30));
    await tester.pumpAndSettle();

    expect(find.text('Bu saati müşteriye önermek istiyor musunuz?'), findsOneWidget);
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();

    final data = await readAppointment();
    expect(data['durum'], 'saat_teklif_edildi');
    expect(data['sonTeklifEden'], 'usta');
    expect(data['teklifEdilenSaat'], '14:30');
    expect((data['teklifEdilenTarih'] as Timestamp).toDate().day, 20);
    // The current confirmed time must not move during a proposal.
    expect(data['randevu_zamani'], originalTimeString);
    expect((data['randevuTarihi'] as Timestamp).toDate().day, originalDate.day);
  });

  testWidgets('Customer accepts the mechanic\'s proposal: teklif becomes the real time, negotiation fields clear', (
    WidgetTester tester,
  ) async {
    await seedAppointment({
      'durum': 'saat_teklif_edildi',
      'sonTeklifEden': 'usta',
      'teklifEdilenTarih': Timestamp.fromDate(DateTime.utc(2026, 9, 20, 12)),
      'teklifEdilenSaat': '14:30',
    });
    await signInAsCustomerAndOpenNotifications(tester);

    await tester.tap(find.text('Kabul Et'));
    await tester.pumpAndSettle();

    final data = await readAppointment();
    expect(data['durum'], 'kabul edildi');
    expect(data['randevu_zamani'], '14:30');
    expect((data['randevuTarihi'] as Timestamp).toDate().day, 20);
    expect(data.containsKey('sonTeklifEden'), isFalse);
    expect(data.containsKey('teklifEdilenTarih'), isFalse);
    expect(data.containsKey('teklifEdilenSaat'), isFalse);
  });

  testWidgets('Customer counter-proposes: a new teklif, current time still untouched', (WidgetTester tester) async {
    await seedAppointment({
      'durum': 'saat_teklif_edildi',
      'sonTeklifEden': 'usta',
      'teklifEdilenTarih': Timestamp.fromDate(DateTime.utc(2026, 9, 20, 12)),
      'teklifEdilenSaat': '14:30',
    });
    await signInAsCustomerAndOpenNotifications(tester);

    await tester.tap(find.text('Farklı Saat Öner'));
    await tester.pumpAndSettle();
    await respondToDateTimePicker(tester, date: DateTime(2026, 9, 22), time: const TimeOfDay(hour: 11, minute: 0));

    final data = await readAppointment();
    expect(data['durum'], 'saat_teklif_edildi');
    expect(data['sonTeklifEden'], 'musteri');
    expect(data['teklifEdilenSaat'], '11:00');
    expect((data['teklifEdilenTarih'] as Timestamp).toDate().day, 22);
    // The original confirmed time — not even the mechanic's first
    // proposal, since that was never accepted — must still be untouched.
    expect(data['randevu_zamani'], originalTimeString);
    expect((data['randevuTarihi'] as Timestamp).toDate().day, originalDate.day);
  });

  testWidgets('Mechanic accepts a counter-proposal: teklif becomes the real time, negotiation fields clear', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedAppointment({
      'durum': 'saat_teklif_edildi',
      'sonTeklifEden': 'musteri',
      'teklifEdilenTarih': Timestamp.fromDate(DateTime.utc(2026, 9, 22, 12)),
      'teklifEdilenSaat': '11:00',
    });
    await signInAsMechanicAndOpenRequestDetails(tester);

    // sonTeklifEden == 'musteri' means it's the mechanic's turn — the
    // button is "Kabul Et", not the first-request "Talebi Kabul Et".
    expect(find.text('Kabul Et'), findsOneWidget);
    expect(find.text('Talebi Kabul Et'), findsNothing);

    await tester.tap(find.text('Kabul Et'));
    await tester.pumpAndSettle();

    final data = await readAppointment();
    expect(data['durum'], 'kabul edildi');
    expect(data['randevu_zamani'], '11:00');
    expect((data['randevuTarihi'] as Timestamp).toDate().day, 22);
    expect(data.containsKey('sonTeklifEden'), isFalse);
    expect(data.containsKey('teklifEdilenTarih'), isFalse);
    expect(data.containsKey('teklifEdilenSaat'), isFalse);
  });

  testWidgets(
    'Tapping an empty calendar slot ("Başka Saat Öner" from Yeni Talepler) writes a real teklif proposal, '
    'not a direct time change, and the request drops off Yeni Talepler',
    (WidgetTester tester) async {
      await seedMechanicAccount();
      await seedAppointment({'durum': 'beklemede'});
      await signInAsMechanicAndOpenAppointmentsScreen(tester);

      // Confirmed present on "Yeni Talepler" before proposing.
      expect(find.text('Lastik Değişimi'), findsOneWidget);

      await tester.tap(find.text('Başka Saat Öner'));
      await tester.pumpAndSettle();

      // Switches to "Tüm Randevular" in slot-selection mode. The grid's
      // empty-slot cells are bare InkWells with no text/key (see
      // appointment_calendar_view.dart's _positionedSlotTap) — precise
      // pixel taps on a specific hour/day cell aren't reliable in this
      // harness, the same class of problem booking_test.dart already
      // solved for its date strip. Driving the real onSlotSelected
      // callback directly still exercises _handleSlotSelected's actual
      // logic (the confirmation dialog, the repository call) — it only
      // skips emulating the tap gesture itself.
      final calendarView = tester.widget<AppointmentCalendarView>(find.byType(AppointmentCalendarView));
      final proposedDate = DateTime.now().add(const Duration(days: 3));
      calendarView.onSlotSelected!(DateTime(proposedDate.year, proposedDate.month, proposedDate.day, 15));
      await tester.pumpAndSettle();

      expect(find.text('Bu randevu saatini müşteriye önermek istiyor musunuz?'), findsOneWidget);
      await tester.tap(find.text('Öneriyi Gönder'));
      await tester.pumpAndSettle();

      final data = await readAppointment();
      expect(data['durum'], 'saat_teklif_edildi');
      expect(data['sonTeklifEden'], 'usta');
      expect(data['teklifEdilenSaat'], '15:00');
      expect((data['teklifEdilenTarih'] as Timestamp).toDate().day, proposedDate.day);
      // The same guarantee as the MechanicRequestDetailsPage entry point —
      // this is a proposal, not a direct overwrite.
      expect(data['randevu_zamani'], originalTimeString);
      expect((data['randevuTarihi'] as Timestamp).toDate().day, originalDate.day);

      // No longer actionable for the mechanic (sonTeklifEden is now
      // 'usta') — consistent with the same rule
      // AppointmentRepository.watchPendingAppointments applies, the
      // request drops off "Yeni Talepler".
      expect(find.text('Lastik Değişimi'), findsNothing);

      // Let the "Saat önerisi müşteriye gönderildi." success banner's
      // delayed self-dismiss timer fire before the test tears down —
      // pumpAndSettle alone stops once the banner is idle (no scheduled
      // frame), leaving its Future.delayed pending and failing teardown's
      // "Timer is still pending" invariant check.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Yeni Talepler "Kabul Et" for a customer counter-proposal accepts the countered time via '
    'acceptTimeProposal, not the stale request.appointmentTime',
    (WidgetTester tester) async {
      final counteredDate = DateTime.utc(2026, 9, 20, 12);
      await seedMechanicAccount();
      await seedAppointment({
        'durum': 'saat_teklif_edildi',
        'sonTeklifEden': 'musteri',
        'teklifEdilenTarih': Timestamp.fromDate(counteredDate),
        'teklifEdilenSaat': '16:00',
      });
      await signInAsMechanicAndOpenAppointmentsScreen(tester);

      // The card must surface the customer's actual counter-proposal, not
      // just the original request info — otherwise the mechanic has no way
      // to know what they're about to accept. _InfoRow renders via a bare
      // RichText (not Text.rich), which find.text/find.textContaining don't
      // match — read its plain text directly instead.
      bool anyRichTextContains(String text) => tester
          .widgetList<RichText>(find.byType(RichText))
          .any((richText) => richText.text.toPlainText().contains(text));
      expect(anyRichTextContains('Müşterinin Önerdiği Saat'), isTrue);
      expect(anyRichTextContains('16:00'), isTrue);

      await tester.tap(find.text('Kabul Et'));
      await tester.pumpAndSettle();

      // The confirmation dialog must summarize the countered date/time
      // (20 Eylül 2026 / 16:00), not the original request's own date/time
      // (originalDate/originalTimeString, 10 Eylül 2026 / 10:00).
      expect(find.textContaining('20 Eylül 2026'), findsOneWidget);
      expect(find.textContaining('16:00'), findsWidgets);
      expect(find.textContaining('10 Eylül 2026'), findsNothing);

      // 'Randevuyu Onayla' also appears as the dialog's own title — target
      // the actual button, not just the text.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Randevuyu Onayla'));
      await tester.pumpAndSettle();

      final data = await readAppointment();
      expect(data['durum'], 'kabul edildi');
      expect(data['randevu_zamani'], '16:00');
      expect((data['randevuTarihi'] as Timestamp).toDate().day, counteredDate.day);
      expect(data.containsKey('sonTeklifEden'), isFalse);
      expect(data.containsKey('teklifEdilenTarih'), isFalse);
      expect(data.containsKey('teklifEdilenSaat'), isFalse);
    },
  );
}
