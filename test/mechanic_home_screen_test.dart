import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/home/mechanic_home_screen.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

/// MechanicHomeScreen's redesign replaced every mock/hardcoded element (the
/// '3' bell badge, the "Ahmet Yılmaz..." Önemli Gelişmeler card) with real
/// Firestore-backed data — real business name, real live stat counts, a
/// real unread-message badge, and real Bugün/Yarın/Gecikti tags computed
/// from each request's own appointmentDate. These tests assert the real
/// numbers/text appear and the old hardcoded ones are gone.
void main() {
  const mechanicUid = 'test-mechanic-uid';
  const businessId = 'test-usta-isletmesi';

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: mechanicUid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: true,
    );
    firestoreInstance = FakeFirebaseFirestore();
  });

  Future<void> seedMechanicAccount({String name = 'Test Usta İşletmesi'}) {
    return firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).set({
      'businessId': businessId,
      'name': name,
      'email': 'usta@example.com',
      'isVerified': true,
    });
  }

  Future<void> seedAppointment(
    String id, {
    required DateTime appointmentDate,
    required DateTime createdAt,
    String customerNote = '',
    String durum = 'beklemede',
    String tamamlanmaDurumu = 'beklemede',
    String vehicleModel = 'Renault Clio',
    String serviceType = 'Genel Bakım',
  }) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'randevu_kimliği': id,
      'müşteri_kimliği': 'customer-$id',
      'müşteriAdı': 'Test Müşteri',
      'araçModeli': vehicleModel,
      'plaka': '34ABC123',
      'hizmetTürü': serviceType,
      'randevuTarihi': Timestamp.fromDate(appointmentDate),
      'randevu_zamani': '10:00',
      'tahminiSüreDakika': 60,
      'müşteriNotu': customerNote,
      'durum': durum,
      'oluşturulma_tarihi': Timestamp.fromDate(createdAt),
      'işletme_kimliği': businessId,
      'tamamlanmaDurumu': tamamlanmaDurumu,
    });
  }

  DateTime daysFromNow(int days) {
    final target = DateTime.now().add(Duration(days: days));
    return DateTime(target.year, target.month, target.day, 12);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall surface — this screen has a lot more vertical content (gradient
    // header, 4 stat cards, banner, priority card, other-requests list)
    // than the default test window, and a plain ListView still needs each
    // item within the viewport/cache extent to actually build it.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('Shows the real business name in the greeting, not a generic one', (WidgetTester tester) async {
    await seedMechanicAccount(name: 'Güven Oto Bakım');
    await pumpScreen(tester);

    expect(find.textContaining('Güven Oto Bakım'), findsOneWidget);
    expect(find.text('Hoş geldiniz 👋'), findsNothing);
  });

  testWidgets('Falls back to a generic greeting when there is no mechanicAccounts profile', (
    WidgetTester tester,
  ) async {
    // Deliberately no seedMechanicAccount() call.
    await pumpScreen(tester);

    expect(find.text('Hoş geldiniz 👋'), findsOneWidget);
  });

  testWidgets('Stat cards show real live counts, not hidden at 0, with no hardcoded mock content', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    // 1 pending ("new request").
    await seedAppointment(
      'req-pending',
      appointmentDate: daysFromNow(0),
      createdAt: DateTime.now(),
    );
    // 1 confirmed for today.
    await seedAppointment(
      'req-today',
      appointmentDate: daysFromNow(0),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      durum: 'kabul edildi',
    );
    // 1 confirmed for the future ("upcoming").
    await seedAppointment(
      'req-upcoming',
      appointmentDate: daysFromNow(5),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      durum: 'kabul edildi',
    );
    // 1 confirmed for the past, never completed ("overdue").
    await seedAppointment(
      'req-overdue',
      appointmentDate: daysFromNow(-3),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      durum: 'kabul edildi',
    );
    // A verified-completed job with a past date must NOT inflate "overdue"
    // — durum stays 'kabul edildi' forever once accepted (see
    // AppointmentRepository.markCustomerVerified, which only ever touches
    // tamamlanmaDurumu), so this specifically exercises that distinction.
    await seedAppointment(
      'req-completed-old',
      appointmentDate: daysFromNow(-30),
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      durum: 'kabul edildi',
      tamamlanmaDurumu: 'dogrulanmis_tamamlandi',
    );

    await pumpScreen(tester);

    expect(find.text('1'), findsNWidgets(4)); // today, new, upcoming, overdue — each real, each exactly 1
    expect(find.textContaining('Bugün 1 randevunuz, 1 yeni talebiniz var.'), findsOneWidget);

    // The old hardcoded elements are fully gone.
    expect(find.text('3'), findsNothing);
    expect(find.textContaining('Ahmet Yılmaz'), findsNothing);
    expect(find.text('Önemli Gelişmeler'), findsNothing);
  });

  testWidgets('Empty state: zero pending/upcoming appointments shows real zeros, not a hidden/broken layout', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await pumpScreen(tester);

    expect(find.text('Bekleyen talebiniz yok.'), findsOneWidget);
    // All four stat cards genuinely show 0 — real data, not hidden.
    expect(find.text('0'), findsNWidgets(4));
    expect(find.textContaining('Ahmet Yılmaz'), findsNothing);
  });

  testWidgets(
    'Priority card highlights the newest request honestly (no "Acil"/urgent label) with real elapsed time and note',
    (WidgetTester tester) async {
      await seedMechanicAccount();
      await seedAppointment(
        'req-older',
        appointmentDate: daysFromNow(2),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        customerNote: 'Klimadan garip bir koku geliyor.',
      );
      await seedAppointment(
        'req-newest',
        appointmentDate: daysFromNow(0),
        // Exactly "now" (not e.g. "2 hours ago") — a small offset is only
        // reliably "today" depending on what wall-clock time the test
        // happens to run at (it can cross midnight), which made this test
        // flaky. Zero offset is same-day by construction, always.
        createdAt: DateTime.now(),
        customerNote: 'Frenlerden ses geliyor, kontrol edebilir misiniz?',
      );

      await pumpScreen(tester);

      // The newest-submitted request (req-newest) is the priority card,
      // and since it was created today, it gets the "today" honest label.
      expect(find.text('Bugün Gelen Talep'), findsOneWidget);
      expect(find.textContaining('geldi'), findsWidgets);
      expect(find.text('"Frenlerden ses geliyor, kontrol edebilir misiniz?"'), findsOneWidget);

      // No fabricated urgency label anywhere on this screen.
      expect(find.textContaining('Acil'), findsNothing);
      expect(find.textContaining('ACİL'), findsNothing);

      // The older request appears under "Diğer Talepler" with a real
      // date-based tag instead (appointmentDate is 2 days out -> "Yaklaşan").
      // Found twice: once as that tag, once more as the compact "Bugüne
      // Bakış" overview row's own "Yaklaşan" (upcoming-count) label — the
      // same real coincidence of wording as 'Bugün'/'Gecikti' above.
      expect(find.text('Diğer Talepler'), findsOneWidget);
      expect(find.text('Yaklaşan'), findsNWidgets(2));
    },
  );

  testWidgets('A request with no customer note omits the quote block entirely for that card', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedAppointment(
      'req-no-note',
      appointmentDate: daysFromNow(0),
      createdAt: DateTime.now(),
    );

    await pumpScreen(tester);

    expect(find.textContaining('"'), findsNothing);
  });

  testWidgets('Other-requests list tags Bugün/Yarın/Gecikti correctly from real appointment dates', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedAppointment(
      'req-newest',
      appointmentDate: daysFromNow(0),
      createdAt: DateTime.now(),
    );
    await seedAppointment(
      'req-today',
      appointmentDate: daysFromNow(0),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await seedAppointment(
      'req-tomorrow',
      appointmentDate: daysFromNow(1),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    await seedAppointment(
      'req-overdue',
      appointmentDate: daysFromNow(-2),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    await pumpScreen(tester);

    // 'Bugün' and 'Gecikti' each appear twice: once as the request's own
    // date-based tag (what this test is really checking), and once more as
    // the compact "Bugüne Bakış" overview row's own short stat labels
    // ('Bugün'/'Gecikti' for the today/overdue counts) — a real, harmless
    // coincidence of wording, not a duplicate tag. 'Yarın' isn't used as an
    // overview label, so it stays unambiguous at 1.
    expect(find.text('Bugün'), findsNWidgets(2));
    expect(find.text('Yarın'), findsOneWidget);
    expect(find.text('Gecikti'), findsNWidgets(2));
  });

  testWidgets('Notification bell badge reflects a real unread-chat count, not a hardcoded number', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await firestoreInstance.collection('chats').doc(businessId).set({
      'mechanicName': 'Test Usta İşletmesi',
      'lastMessageAt': Timestamp.now(),
      'lastMessageText': 'Merhaba, aracım için bilgi alabilir miyim?',
      'lastMessageSenderId': 'customer-uid',
      'lastMessageSenderRole': 'customer',
    });
    await firestoreInstance.collection('chats').doc(businessId).collection('messages').add({
      'senderId': 'customer-uid',
      'text': 'Merhaba, aracım için bilgi alabilir miyim?',
      'createdAt': Timestamp.now(),
      'isRead': false,
    });

    await pumpScreen(tester);

    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('Bell badge is hidden (no numeric label) when there are no unread chats', (WidgetTester tester) async {
    await seedMechanicAccount();
    await pumpScreen(tester);

    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isFalse);
  });
}
