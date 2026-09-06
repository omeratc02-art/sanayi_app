import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/home/mechanic_home_screen.dart';
import 'package:sanayi_app/theme/app_theme.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/common/premium_surface.dart';

/// MechanicHomeScreen was rebuilt to match a visual reference mockup (top
/// bar, a fixed static greeting hero, a responsive two-column body) while
/// keeping every value real: business name, unread-message count, today's
/// confirmed-appointment count, new-request count, rating/repeat-customer/
/// on-time metrics, and isVerified. These tests assert the real data
/// renders correctly and that nothing fabricated (a weekly total, a
/// repeat-customer percentage, a stock vehicle/profile photo, a 4th bottom
/// nav tab) ever appears. The stats row (today/new-requests/rating) was
/// removed entirely — those real values still render elsewhere on this
/// screen (the pending-requests list, the performance card), just not in
/// their own dedicated row any more.
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

  // Narrow (phone-width, stacked layout) by default — this screen has a
  // lot of vertical content (top bar, hero, the pending-requests list,
  // schedule card, performance card), and a plain ListView still needs
  // each item within the viewport/cache extent to actually build it.
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
      expect(find.text('Güvenle Büyüyen İşletmeler'), findsOneWidget);
      expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
    });

    testWidgets(
      'The real logo asset actually decodes and renders (not just present pre-decode, and not the '
      'errorBuilder fallback) — proves the asset+pubspec registration is genuinely correct',
      (WidgetTester tester) async {
        await seedMechanicAccount();

        tester.view.physicalSize = const Size(390, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // The whole sequence — pump, then enough further pumps for the
        // ImageStream's real (non-faked) codec-decode Future to actually
        // resolve and trigger Image's internal setState — has to run
        // inside one runAsync block. Splitting pumpWidget into its own
        // runAsync and settling afterward isn't enough: the decode
        // callback can still fire after that block returns, outside real
        // async execution, and never get picked up.
        await tester.runAsync(() async {
          await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));
          for (var i = 0; i < 10; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
          }
        });

        // If the asset had failed to load, errorBuilder would have
        // replaced the Image with a SizedBox — so there would be no Image
        // widget here at all, not a broken one.
        expect(find.byType(Image), findsOneWidget);

        // The authoritative proof of a successful decode: Image delegates
        // to RawImage once its ImageStream resolves a frame, and
        // RawImage.image is the actual decoded dart:ui.Image — non-null
        // (and with real pixel dimensions) only once real image bytes were
        // successfully read and decoded, not on the errorBuilder path.
        final rawImage = tester.widget<RawImage>(find.byType(RawImage));
        expect(rawImage.image, isNotNull);
        expect(rawImage.image!.width, greaterThan(0));
        expect(rawImage.image!.height, greaterThan(0));
      },
    );

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
    testWidgets('Shows the fixed "Merhaba 👋" greeting and fixed subtitle, regardless of business name', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount(name: 'Güven Oto Bakım');
      await pumpScreen(tester);

      expect(find.text('Merhaba 👋'), findsOneWidget);
      expect(find.text('İşletme Paneline Hoş Geldiniz'), findsOneWidget);
      // The business name is never repeated into the greeting itself — it
      // already appears once, in the top bar's profile chip.
      expect(find.text('Güven Oto Bakım'), findsOneWidget);
    });

    testWidgets('Shows the same fixed greeting when there is no mechanicAccounts profile at all', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Merhaba 👋'), findsOneWidget);
      expect(find.text('İşletme Paneline Hoş Geldiniz'), findsOneWidget);
    });

    testWidgets('No longer shows the old time-aware prefixes or the old tagline/subtitle text', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount(name: 'Güven Oto Bakım');
      await pumpScreen(tester);

      for (final oldPrefix in ['İyi geceler', 'Günaydın', 'İyi günler', 'İyi akşamlar']) {
        expect(find.textContaining(oldPrefix), findsNothing);
      }
      expect(find.text('Ustanın Gücü, Yolda Güven'), findsNothing);
      expect(find.text('Randevularınızı ve hizmet taleplerinizi yönetin.'), findsNothing);
    });
  });

  group('Stats row', () {
    testWidgets('The stats row is gone entirely — no leftover today/new-requests/rating stat widgets', (
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

      expect(find.text('Bugün / Randevu'), findsNothing);
      // "Yeni Talepler" now appears exactly once — the pending-requests
      // list's own section heading — since the stats row that used to
      // share this exact text is gone.
      expect(find.text('Yeni Talepler'), findsOneWidget);
      // "Müşteri Puanı" still appears once (rating summary is null — no
      // rated jobs yet, so the performance card's own label has no
      // parenthetical) — but only from the performance card now, not
      // doubled up with the removed stats row's own copy of the same text.
      expect(find.text('Müşteri Puanı'), findsOneWidget);
    });
  });

  group('Yeni Talepler (unified pending-requests list)', () {
    testWidgets(
      'Every pending request renders identically (same tag, same row style) regardless of how recently it arrived',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await seedAppointment(
          'req-older',
          appointmentDate: daysFromNow(2),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          customerNote: 'Klimadan garip bir koku geliyor.',
          vehicleModel: 'Volkswagen Golf',
          serviceType: 'Fren Bakımı',
        );
        await seedAppointment(
          'req-newest',
          appointmentDate: daysFromNow(0),
          // Exactly "now" — the newest-arrived request. There is no
          // separate "just arrived" label any more — every request, this
          // one included, gets the same plain "Yeni Talep" tag.
          createdAt: DateTime.now(),
          customerNote: 'Frenlerden ses geliyor, kontrol edebilir misiniz?',
          vehicleModel: 'Opel Astra',
        );

        await pumpScreen(tester);

        // Both requests show up, with real vehicle/service data.
        expect(find.text('Opel Astra'), findsOneWidget);
        expect(find.text('Volkswagen Golf'), findsOneWidget);
        expect(find.text('Fren Bakımı'), findsOneWidget);

        // Uniform tagging — exactly the plain "Yeni Talep" text for both,
        // never the old "Bugün Gelen Talep" variant that used to single
        // out the newest one.
        expect(find.text('Yeni Talep'), findsNWidgets(2));
        expect(find.text('Bugün Gelen Talep'), findsNothing);

        // Uniform action affordance — the same chevron on every row, not
        // a large button on one row and nothing on the rest.
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

        // Real elapsed time still shows for each row (the newest reads
        // "az önce", the older one in days).
        expect(find.textContaining('geldi'), findsNWidgets(2));

        // The old spotlighted-card-only elements are gone entirely: no big
        // CTA button, no customer-note preview, no "Diğer N talebi gör"
        // link, no fabricated urgency label.
        expect(find.text('Talebi İncele'), findsNothing);
        expect(find.textContaining('"'), findsNothing); // no note preview
        expect(find.textContaining('talebi gör'), findsNothing);
        expect(find.textContaining('Acil'), findsNothing);
        expect(find.textContaining('ACİL'), findsNothing);

        // No lingering solid-blue "priority" card background anywhere in
        // the list.
        expect(
          find.byWidgetPredicate((widget) {
            if (widget is! PremiumSurface) return false;
            return widget.color == AppColors.primary;
          }),
          findsNothing,
        );
      },
    );

    testWidgets('A single pending request still renders in the list, uniformly, not hidden or specially framed', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment(
        'req-only',
        appointmentDate: daysFromNow(0),
        createdAt: DateTime.now(),
        vehicleModel: 'Renault Clio',
      );

      await pumpScreen(tester);

      expect(find.text('Yeni Talepler'), findsOneWidget); // list heading (no stats row any more)
      expect(find.text('Renault Clio'), findsOneWidget);
      expect(find.text('Yeni Talep'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('Talebi İncele'), findsNothing);
    });

    testWidgets('Shows the real empty state when there are zero pending requests', (WidgetTester tester) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(find.text('Bekleyen talebiniz yok.'), findsOneWidget);
      expect(find.text('Talebi İncele'), findsNothing);
    });

    testWidgets('Caps the preview at 3 and shows a real "Tümünü Gör (N)" overflow count beyond that', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
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

      await pumpScreen(tester);

      expect(find.text('Yeni Talep'), findsNWidgets(3)); // only 3 of the real 4 previewed
      expect(find.text('Tümünü Gör (4)'), findsOneWidget);
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

      // 2 in total: the performance card's rating value and on-time value
      // — none fabricated as a 0/0%, since there's no completed job yet.
      // (No stats row any more to contribute a third.)
      expect(find.text('—'), findsNWidgets(2));
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
      // main column's pending-requests list, not beside it. 'Renault Clio'
      // is seedAppointment's default vehicle model for 'req-1'.
      final requestY = tester.getTopLeft(find.text('Renault Clio')).dy;
      final scheduleY = tester.getTopLeft(find.text('Bugünün Programı')).dy;
      expect(scheduleY, greaterThan(requestY));
    });

    testWidgets('Renders a true two-column layout with no overflow at a wide (tablet/desktop) width', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester, width: 900, height: 1400);

      expect(tester.takeException(), isNull);
      // Side by side: the sidebar's "Bugünün Programı" title sits to the
      // right of the main column's pending-requests list, not below it.
      final requestX = tester.getTopLeft(find.text('Renault Clio')).dx;
      final scheduleX = tester.getTopLeft(find.text('Bugünün Programı')).dx;
      expect(scheduleX, greaterThan(requestX));
    });
  });
}
