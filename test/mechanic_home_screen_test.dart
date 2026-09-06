import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/home/mechanic_home_screen.dart';
import 'package:sanayi_app/theme/app_theme.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

/// MechanicHomeScreen was rebuilt to match a visual reference mockup (top
/// bar, greeting hero, stats row, a responsive two-column body) while
/// keeping every value real: business name, unread-message count, today's
/// confirmed-appointment count, new-request count, rating/repeat-customer/
/// on-time metrics, and isVerified. These tests assert the real data
/// renders correctly and that nothing fabricated (a weekly total, a
/// repeat-customer percentage, a stock vehicle/profile photo, a 4th bottom
/// nav tab) ever appears.
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

  Future<void> seedMechanicAccount({String name = 'Test Usta İşletmesi', bool isVerified = true}) {
    return firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).set({
      'businessId': businessId,
      'name': name,
      'email': 'usta@example.com',
      'isVerified': isVerified,
    });
  }

  Future<void> seedConfirmedAppointment({
    required String id,
    required DateTime appointmentDate,
    required String time,
    required String vehicleModel,
    required String serviceType,
  }) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'randevu_kimliği': id,
      'müşteri_kimliği': 'customer-$id',
      'araçModeli': vehicleModel,
      'hizmetTürü': serviceType,
      'randevuTarihi': Timestamp.fromDate(appointmentDate),
      'randevu_zamani': time,
      'müşteriNotu': '',
      'durum': 'kabul edildi',
      'oluşturulma_tarihi': Timestamp.fromDate(DateTime.now()),
      'işletme_kimliği': businessId,
      'tamamlanmaDurumu': 'beklemede',
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

  // Mirrors mechanic_home_screen.dart's own _timeAwareGreetingPrefix (a
  // private top-level function, not reachable from here) so these tests
  // stay correct regardless of what time of day the suite actually runs.
  String expectedGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  // Narrow (phone-width, stacked layout) by default — this screen has a
  // lot of vertical content (top bar, hero, stats, priority card, recent
  // list, schedule card, performance card), and a plain ListView still
  // needs each item within the viewport/cache extent to actually build it.
  Future<void> pumpScreen(WidgetTester tester, {double width = 390, double height = 3200}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));
    await tester.pumpAndSettle();
  }

  group('Top bar', () {
    testWidgets('Shows the real SanayiGo wordmark, static tagline, and the real bell badge count', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await firestoreInstance.collection('chats').doc(businessId).set({
        'mechanicName': 'Test Usta İşletmesi',
        'lastMessageAt': Timestamp.now(),
        'lastMessageText': 'Merhaba',
        'lastMessageSenderId': 'customer-uid',
        'lastMessageSenderRole': 'customer',
      });
      await firestoreInstance.collection('chats').doc(businessId).collection('messages').add({
        'senderId': 'customer-uid',
        'text': 'Merhaba',
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      await pumpScreen(tester);

      expect(find.text('SanayiGo'), findsOneWidget);
      expect(find.text('Ustanın Gücü, Yolda Güven'), findsOneWidget);
      expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
    });

    testWidgets('Bell badge is hidden (no numeric label) when there are no unread chats', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isFalse);
    });

    testWidgets('Profile chip shows the real business name, not a generic one', (WidgetTester tester) async {
      await seedMechanicAccount(name: 'Güven Oto Bakım');
      await pumpScreen(tester);

      expect(find.text('Güven Oto Bakım'), findsOneWidget);
      expect(find.text('Usta'), findsNothing);
    });

    testWidgets('Profile chip falls back to a generic label when there is no mechanicAccounts profile', (
      WidgetTester tester,
    ) async {
      // Deliberately no seedMechanicAccount() call.
      await pumpScreen(tester);

      expect(find.text('Usta'), findsOneWidget);
    });

    testWidgets('Doğrulanmış Servis appears (top-bar chip + performance-card badge) only for a verified account', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount(isVerified: true);
      await pumpScreen(tester);

      expect(find.text('Doğrulanmış Servis'), findsNWidgets(2));
    });

    testWidgets('Doğrulanmış Servis appears nowhere for an unverified account', (WidgetTester tester) async {
      await seedMechanicAccount(isVerified: false);
      await pumpScreen(tester);

      expect(find.text('Doğrulanmış Servis'), findsNothing);
    });
  });

  group('Greeting', () {
    testWidgets('Shows the real time-aware greeting with the real business name', (WidgetTester tester) async {
      await seedMechanicAccount(name: 'Güven Oto Bakım');
      await pumpScreen(tester);

      expect(find.text('${expectedGreetingPrefix()}, Güven Oto Bakım 👋'), findsOneWidget);
      expect(find.text('${expectedGreetingPrefix()} 👋'), findsNothing);
    });

    testWidgets('Falls back to a generic greeting when there is no mechanicAccounts profile', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('${expectedGreetingPrefix()} 👋'), findsOneWidget);
    });
  });

  group('Stats row', () {
    testWidgets('Shows real live counts and real rating, with no hardcoded mock content', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedConfirmedAppointment(
        id: 'appt-1',
        appointmentDate: daysFromNow(0),
        time: '09:00',
        vehicleModel: 'Fiat Egea',
        serviceType: 'Yağ Değişimi',
      );
      await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(find.text('Bugün / Randevu'), findsOneWidget);
      expect(find.text('Yeni Talepler'), findsOneWidget);
      // Both counts are 1, plus the plain "Müşteri Puanı" stat label
      // (rating summary is null — no rated jobs yet) also happens to read
      // "Müşteri Puanı" with no parenthetical, same as the performance
      // card's own label in that same no-data state — 2 in total.
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('—'), findsWidgets); // rating value + on-time value, both no data yet
      expect(find.textContaining('Ahmet Yılmaz'), findsNothing);
      expect(find.text('Önemli Gelişmeler'), findsNothing);
      expect(find.textContaining('Bu Hafta'), findsNothing);
      expect(find.textContaining('Toplam İş'), findsNothing);
    });

    testWidgets("Shows '...' placeholders while loading, never null or a fabricated number", (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();

      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // A single pump (not pumpAndSettle) — catches the very first frame,
      // before resolveMyBusinessId()/the appointment streams resolve, when
      // todayCount/newRequestsCount are still null.
      await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));

      expect(find.text('...'), findsNWidgets(2));
      expect(find.textContaining('null'), findsNothing);

      await tester.pumpAndSettle();
    });

    // Finds the small dot indicator by its actual decoration (a tiny
    // circle in the muted scheduleOverdue color) rather than a widget
    // type, since it's a plain, unlabeled Container — the same "calm, not
    // alarming" color this file already uses for "Gecikti" elsewhere.
    Finder findDotIndicator() => find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      return decoration.shape == BoxShape.circle && decoration.color == AppColors.scheduleOverdue;
    });

    testWidgets('Shows a small dot indicator only when the real new-requests count is > 0', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(findDotIndicator(), findsOneWidget);
    });

    testWidgets('Shows no dot indicator when the new-requests count is 0', (WidgetTester tester) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(findDotIndicator(), findsNothing);
      // The stat itself still shows a real 0, not hidden.
      expect(find.text('0'), findsWidgets);
    });
  });

  group('Priority card', () {
    testWidgets(
      'Spotlights the newest request honestly (no "Acil"/urgent label), with real elapsed time, note, and vehicle',
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
          // Exactly "now" — a small offset like "2 hours ago" is only
          // reliably "today" depending on wall-clock time at test run,
          // which can cross midnight. Zero offset is same-day always.
          createdAt: DateTime.now(),
          customerNote: 'Frenlerden ses geliyor, kontrol edebilir misiniz?',
          vehicleModel: 'Opel Astra',
        );

        await pumpScreen(tester);

        expect(find.text('Opel Astra'), findsOneWidget);
        expect(find.text('Bugün Gelen Talep'), findsOneWidget);
        expect(find.textContaining('geldi'), findsWidgets);
        expect(find.text('"Frenlerden ses geliyor, kontrol edebilir misiniz?"'), findsOneWidget);
        expect(find.text('Talebi İncele'), findsOneWidget);

        // No fabricated urgency label anywhere on this screen.
        expect(find.textContaining('Acil'), findsNothing);
        expect(find.textContaining('ACİL'), findsNothing);

        // One other pending request exists beyond the spotlighted one.
        expect(find.text('Diğer 1 talebi gör'), findsOneWidget);
      },
    );

    testWidgets('Shows no "Diğer N talebi gör" link when there is only one pending request', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-only', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(find.textContaining('talebi gör'), findsNothing);
    });

    testWidgets('A request with no customer note omits the quote block entirely for that card', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-no-note', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(find.textContaining('"'), findsNothing);
    });

    testWidgets('Shows the real empty state when there are zero pending requests', (WidgetTester tester) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(find.text('Bekleyen talebiniz yok.'), findsOneWidget);
      expect(find.text('Talebi İncele'), findsNothing);
    });
  });

  group('Son Talepler (recent requests list)', () {
    testWidgets('Shows requests beyond the spotlighted one, each with a real elapsed time and a Yeni Talep tag', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment(
        'req-newest',
        appointmentDate: daysFromNow(0),
        createdAt: DateTime.now(),
        vehicleModel: 'Opel Astra',
      );
      await seedAppointment(
        'req-second',
        appointmentDate: daysFromNow(1),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        vehicleModel: 'Volkswagen Golf',
        serviceType: 'Fren Bakımı',
      );

      await pumpScreen(tester);

      expect(find.text('Son Talepler'), findsOneWidget);
      expect(find.text('Volkswagen Golf'), findsOneWidget);
      expect(find.text('Fren Bakımı'), findsOneWidget);
      expect(find.text('Yeni Talep'), findsOneWidget); // one recent row -> one tag
      expect(find.textContaining('saat önce geldi'), findsOneWidget);
      // The spotlighted request itself is not duplicated into this list.
      expect(find.text('Opel Astra'), findsOneWidget);
    });

    testWidgets('Does not render at all when there is only the spotlighted request', (WidgetTester tester) async {
      await seedMechanicAccount();
      await seedAppointment('req-only', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(find.text('Son Talepler'), findsNothing);
    });

    testWidgets('Caps the preview at 3 and shows a real "Tümünü Gör (N)" overflow count beyond that', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      // 1 spotlighted + 4 more = 5 pending total; the recent list previews
      // only 3 of those 4, with an overflow link showing the real total
      // "other" count (4).
      await seedAppointment('req-0', appointmentDate: daysFromNow(0), createdAt: DateTime.now());
      await seedAppointment(
        'req-1',
        appointmentDate: daysFromNow(1),
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await seedAppointment(
        'req-2',
        appointmentDate: daysFromNow(1),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      await seedAppointment(
        'req-3',
        appointmentDate: daysFromNow(1),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await seedAppointment(
        'req-4',
        appointmentDate: daysFromNow(1),
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      );

      await pumpScreen(tester);

      expect(find.text('Yeni Talep'), findsNWidgets(3)); // only 3 previewed
      expect(find.text('Tümünü Gör (4)'), findsOneWidget);
      expect(find.text('Diğer 4 talebi gör'), findsOneWidget);
    });
  });

  group('Bugünün Programı', () {
    testWidgets('Shows real confirmed appointments sorted earliest-first', (WidgetTester tester) async {
      await seedMechanicAccount();
      await seedConfirmedAppointment(
        id: 'appt-late',
        appointmentDate: daysFromNow(0),
        time: '14:30',
        vehicleModel: 'VW Golf',
        serviceType: 'Periyodik Bakım',
      );
      await seedConfirmedAppointment(
        id: 'appt-early',
        appointmentDate: daysFromNow(0),
        time: '08:00',
        vehicleModel: 'Opel Astra',
        serviceType: 'Fren Bakımı',
      );

      await pumpScreen(tester);

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);

      final earlyY = tester.getTopLeft(find.text('08:00')).dy;
      final lateY = tester.getTopLeft(find.text('14:30')).dy;
      expect(earlyY, lessThan(lateY));
    });

    testWidgets('Shows the real empty-state copy when there are none today, plus the availability button', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(find.text('Bugün için planlanmış randevu yok'), findsOneWidget);
      expect(find.text('Uygunluk durumunu düzenle'), findsOneWidget);
      expect(find.text('Tümünü Gör'), findsOneWidget);
    });

    testWidgets('Tapping "Uygunluk durumunu düzenle" opens the real appointments screen (no dead button)', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      await tester.tap(find.text('Uygunluk durumunu düzenle'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Talepler'), findsOneWidget); // MechanicAppointmentsScreen's default tab
    });
  });

  group('Servis Performansınız', () {
    testWidgets('Shows the real repeat-customer count as a raw integer, never a percentage', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).update({'repeatCustomerCount': 6});

      await pumpScreen(tester);

      expect(find.text('Servis Performansınız'), findsOneWidget);
      expect(find.text('Tekrar Müşteri'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.textContaining('%6'), findsNothing);
    });

    testWidgets('Shows — for rating/on-time when no completed job exists yet, not a fabricated 0', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      // 3 in total: the stats row's own "Müşteri Puanı" value, plus the
      // performance card's rating value and on-time value — none
      // fabricated as a 0/0%, since there's no completed job yet.
      expect(find.text('—'), findsNWidgets(3));
    });
  });

  group('Responsive layout', () {
    testWidgets('Stacks vertically with no overflow at a common phone width', (WidgetTester tester) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());
      await seedConfirmedAppointment(
        id: 'appt-1',
        appointmentDate: daysFromNow(0),
        time: '09:00',
        vehicleModel: 'Fiat Egea',
        serviceType: 'Yağ Değişimi',
      );

      await pumpScreen(tester, width: 360);

      expect(tester.takeException(), isNull);
      // Stacked: the sidebar's "Bugünün Programı" card renders below the
      // main column's priority card, not beside it.
      final priorityY = tester.getTopLeft(find.text('Talebi İncele')).dy;
      final scheduleY = tester.getTopLeft(find.text('Bugünün Programı')).dy;
      expect(scheduleY, greaterThan(priorityY));
    });

    testWidgets('Renders a true two-column layout with no overflow at a wide (tablet/desktop) width', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester, width: 900, height: 1400);

      expect(tester.takeException(), isNull);
      // Side by side: the sidebar's "Bugünün Programı" title sits to the
      // right of the priority card's own content, roughly at the same
      // vertical position rather than far below it.
      final priorityX = tester.getTopLeft(find.text('Talebi İncele')).dx;
      final scheduleX = tester.getTopLeft(find.text('Bugünün Programı')).dx;
      expect(scheduleX, greaterThan(priorityX));
    });
  });
}
