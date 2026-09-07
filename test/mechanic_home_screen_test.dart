import 'dart:io';

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
/// bar, a fixed static greeting hero, a single full-width pending-requests
/// list) while keeping every value real: business name, unread-message
/// count, new-request count, and isVerified. These tests assert the real
/// data renders correctly and that nothing fabricated (a weekly total, a
/// repeat-customer percentage, a stock vehicle/profile photo, a 4th bottom
/// nav tab) ever appears. The old stats row, the "Bugünün Programı"
/// today's-schedule card, and the "Servis Performansınız"
/// rating/repeat-customer/on-time card were all removed entirely — the
/// pending-requests list is now the screen's only body content, at every
/// width (no more two-column/sidebar layout). The one deliberate exception
/// to "real data only" is the "İşletmeniz İlgi Görüyor" weekly engagement
/// summary card's sparkline shape, still a static placeholder. Both of the
/// card's stats are real now: the appointment-request count (a live 7-day
/// count from AppointmentRepository.watchRecentAppointmentRequestCount) and
/// the profile-view count (a live count from
/// MechanicProfileRepository.watchProfileViewCount, incremented via
/// recordProfileView from MechanicDetailPage — see
/// test/mechanic_profile_repository_test.dart for that write path's own
/// dedicated tests).
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

  // Narrow (phone-width) by default — this screen has a lot of vertical
  // content (top bar, hero, the pending-requests list), and a plain
  // ListView still needs each item within the viewport/cache extent to
  // actually build it.
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
      // Bumped up from 11 so it reads proportionate to the logo beside it.
      final tagline = tester.widget<Text>(find.text('Güvenle Büyüyen İşletmeler'));
      expect(tagline.style?.fontSize, 12);
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

    testWidgets('Doğrulanmış Servis appears (top-bar profile chip badge) only for a verified account', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount(isVerified: true);
      await pumpScreen(tester);

      // Only the top-bar profile chip's own badge now — the performance
      // card that used to carry a second copy of this badge is gone.
      expect(find.text('Doğrulanmış Servis'), findsOneWidget);
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

    testWidgets('The old "İyi bakım, daha uzun yollar." promo card is gone entirely — no remnant of it anywhere', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(find.textContaining('İyi bakım'), findsNothing);
      expect(find.textContaining('daha uzun yollar'), findsNothing);
      expect(find.byIcon(Icons.directions_car_filled_rounded), findsNothing);
    });
  });

  group('Removed sidebar cards', () {
    testWidgets(
      'No stats row, no "Bugünün Programı" card, and no "Servis Performansınız" card remain, even with real '
      'confirmed-appointment and performance data present',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).update({'repeatCustomerCount': 6});
        await seedConfirmedAppointment(
          id: 'appt-1',
          appointmentDate: daysFromNow(0),
          time: '09:00',
          vehicleModel: 'Fiat Egea',
          serviceType: 'Yağ Değişimi',
        );
        await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());

        await pumpScreen(tester);

        // The old stats row's own labels.
        expect(find.text('Bugün / Randevu'), findsNothing);
        expect(find.text('Müşteri Puanı'), findsNothing);
        // "Yeni Talepler" now appears exactly once — the pending-requests
        // list's own section heading — since the stats row that used to
        // share this exact text is gone.
        expect(find.text('Yeni Talepler'), findsOneWidget);

        // The "Bugünün Programı" card, including its confirmed-appointment
        // row, empty state, and availability button.
        expect(find.text('Bugünün Programı'), findsNothing);
        expect(find.text('Fiat Egea'), findsNothing);
        expect(find.text('09:00'), findsNothing);
        expect(find.text('Uygunluk durumunu düzenle'), findsNothing);

        // The "Servis Performansınız" card, including its repeat-customer
        // count and on-time-rate rows.
        expect(find.text('Servis Performansınız'), findsNothing);
        expect(find.text('Tekrar Müşteri'), findsNothing);
        expect(find.text('Zamanında Teslim'), findsNothing);
        expect(find.text('6'), findsNothing);
      },
    );
  });

  group('İşletmeniz İlgi Görüyor (weekly engagement summary card)', () {
    testWidgets(
      'Renders the header, message, day labels, and both real stats (profile views, appointment requests)',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        // 2 real appointment requests, both within the last 7 days — the
        // real data source for that stat (see the dedicated 7-day window
        // test below for the exclusion boundary itself).
        await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());
        await seedAppointment(
          'req-2',
          appointmentDate: daysFromNow(2),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        await pumpScreen(tester);

        expect(find.text('Bu haftanın özeti'), findsOneWidget);
        expect(find.text('İşletmeniz ilgi görüyor 📈'), findsOneWidget);
        expect(find.text('Daha fazla sürücü sizi keşfediyor.'), findsOneWidget);

        // "0" is the real profileViewCount — no customer has viewed this
        // business's MechanicDetailPage in this test (see
        // mechanic_profile_repository_test.dart for the write path's own
        // dedicated coverage). "2" is the real count of the two
        // appointments just seeded above.
        expect(find.text('0'), findsOneWidget);
        expect(find.text('kişi işletmenizi görüntüledi'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('kişi randevu talebi oluşturdu'), findsOneWidget);
        expect(find.text('randevu talebi aldı'), findsNothing);
        // The old hardcoded placeholders are gone — "127"/"8" would only
        // coincidentally reappear if those exact real counts happened,
        // which isn't the case here.
        expect(find.text('127'), findsNothing);
        expect(find.text('8'), findsNothing);

        for (final day in ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']) {
          expect(find.text(day), findsOneWidget);
        }

        // No "Tüm istatistikler" link/button anywhere on this card (or the
        // screen at all) — the header row is just the plain label.
        expect(find.textContaining('Tüm istatistikler'), findsNothing);
        // No fabricated comparison percentage or extra metrics beyond what
        // was explicitly specified.
        expect(find.textContaining('geçen haftaya göre'), findsNothing);
        expect(find.textContaining('tekrar tercih'), findsNothing);
        expect(find.textContaining('güven skoru'), findsNothing);
      },
    );

    testWidgets('Shows the real profileViewCount once a customer has actually viewed this business', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      // Simulates a real recorded view — the same write MechanicDetailPage's
      // initState triggers via MechanicProfileRepository.recordProfileView
      // (see mechanic_profile_repository_test.dart for that method's own
      // direct tests); this screen just needs to prove it reads the real
      // field back correctly.
      await firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).update({'profileViewCount': 3});

      await pumpScreen(tester);

      // "3" is the real profileViewCount just written above. Not asserting
      // the sibling appointment-request stat's absence here — with no
      // appointments seeded in this test, that one legitimately also
      // renders "0", which isn't what this test is checking.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'The appointment-request stat only counts requests created in the last 7 days — an older one is excluded, '
      'a recent one is included',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await seedAppointment(
          'req-old',
          appointmentDate: daysFromNow(1),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        );
        await seedAppointment(
          'req-recent',
          appointmentDate: daysFromNow(1),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await pumpScreen(tester);

        // Only "req-recent" counts — "1", not "2".
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsNothing);
      },
    );

    testWidgets("Shows '...' (not stale/fabricated numbers) on both stats while the real counts are still loading", (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();

      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // A single pump (not pumpAndSettle) — catches the very first frame,
      // before resolveMyBusinessId()/the profile lookup/either count
      // stream resolve. Both stats start null now (profileViewCount and
      // appointmentRequestCount), so both show '...'.
      await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));

      expect(find.text('...'), findsNWidgets(2));
      expect(find.text('127'), findsNothing);
      expect(find.text('8'), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets(
      'Both stats share the exact same icon chip style (size, radius, fill) and icon size/color, separated by '
      'the original thin vertical divider',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await pumpScreen(tester);

        expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
        expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

        // Both icons render through the same _EngagementStat widget — same
        // size, same color — for both the eye stat and the calendar stat.
        final eyeIcon = tester.widget<Icon>(find.byIcon(Icons.visibility_rounded));
        final calendarIcon = tester.widget<Icon>(find.byIcon(Icons.calendar_month_rounded));
        expect(eyeIcon.size, calendarIcon.size);
        expect(eyeIcon.color, calendarIcon.color);

        // Each icon sits in its own small rounded chip container — exactly
        // 2 of them, both with the identical 36x36 turquoise-tint/rounded
        // style (one shared style source, per _EngagementStat).
        expect(
          find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final constraints = widget.constraints;
            if (constraints == null || constraints.maxWidth != 36 || constraints.maxHeight != 36) return false;
            final decoration = widget.decoration;
            if (decoration is! BoxDecoration) return false;
            return decoration.color == AppColors.turquoise.withValues(alpha: 0.1) &&
                decoration.borderRadius == BorderRadius.circular(AppRadius.sm);
          }),
          findsNWidgets(2),
        );
        // Both icons are 18px — sized up from the chip's earlier 16px, in
        // proportion with the chip's own 32->36 increase.
        expect(eyeIcon.size, 18);

        // The thin vertical divider between the two stats (1px wide, 44
        // tall, AppColors.divider) is still there — the two stats stay
        // side by side, only each one's internal icon+number layout
        // changed.
        expect(
          find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final constraints = widget.constraints;
            return constraints != null && constraints.maxWidth == 1 && constraints.maxHeight == 44;
          }),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Only the header text block is tinted blue — the two stat numbers, chart, and weekday labels sit on '
      'plain white below it',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await pumpScreen(tester);

        // Exactly one tinted Container — the header block wrapping "Bu
        // haftanın özeti" / the headline / the subtitle — with top-only
        // rounded corners matching the card's own radius.
        final tintedHeaderFinder = find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          return decoration.color == AppColors.primary.withValues(alpha: 0.09) &&
              decoration.borderRadius ==
                  const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  );
        });
        expect(tintedHeaderFinder, findsOneWidget);

        // The tinted header block's bottom edge sits above (a smaller dy
        // than) both stats (found by their labels rather than their
        // values, since both values are real data now, not fixed
        // "127"/"8"), the sparkline, and the weekday labels below it —
        // proving the tint doesn't extend into the body.
        final headerBottomY = tester.getBottomLeft(tintedHeaderFinder).dy;
        final profileViewsY = tester.getTopLeft(find.text('kişi işletmenizi görüntüledi')).dy;
        final appointmentsY = tester.getTopLeft(find.text('kişi randevu talebi oluşturdu')).dy;
        final dayLabelY = tester.getTopLeft(find.text('Pzt')).dy;

        expect(profileViewsY, greaterThan(headerBottomY));
        expect(appointmentsY, greaterThan(headerBottomY));
        expect(dayLabelY, greaterThan(headerBottomY));

        // The outer PremiumSurface itself carries no tint any more (its
        // `color` param is unset, defaulting to plain white) — only the
        // header Container above does.
        expect(
          find.byWidgetPredicate((widget) => widget is PremiumSurface && widget.color != null),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Sits between the greeting hero and "Yeni Talepler" in the widget tree, not inside or under the list',
      (WidgetTester tester) async {
        await seedMechanicAccount();
        await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

        await pumpScreen(tester);

        final greetingY = tester.getTopLeft(find.text('Merhaba 👋')).dy;
        final cardHeaderY = tester.getTopLeft(find.text('Bu haftanın özeti')).dy;
        final pendingListHeadingY = tester.getTopLeft(find.text('Yeni Talepler')).dy;

        expect(cardHeaderY, greaterThan(greetingY));
        expect(pendingListHeadingY, greaterThan(cardHeaderY));
      },
    );

    testWidgets('No overflow at a narrow phone width or a wider width', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());

      await pumpScreen(tester, width: 360);
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget); // real profileViewCount — no view recorded in this test
      expect(find.text('1'), findsOneWidget);
      expect(find.text('kişi randevu talebi oluşturdu'), findsOneWidget);

      await pumpScreen(tester, width: 900, height: 1400);
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('kişi randevu talebi oluşturdu'), findsOneWidget);
    });

    test(
      'Both old hardcoded placeholder constants (_profileViewCount = 127, _appointmentRequestCount) and their '
      'TODO(real-data) comments are gone entirely from source — both stats are wired to real data now',
      () {
        final source = File('lib/mechanic/home/mechanic_home_screen.dart').readAsStringSync();

        expect(source, isNot(contains('_profileViewCount = 127')));
        expect(source, isNot(contains('_appointmentRequestCount')));
        expect(source, isNot(contains('TODO(real-data)')));
        // The real constructor param + repository wiring are still there.
        expect(source, contains('required this.profileViewCount'));
        expect(source, contains('MechanicProfileRepository().watchProfileViewCount'));
      },
    );
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

  group('Layout at every width (single column, no sidebar any more)', () {
    testWidgets('No overflow at a narrow (phone) width, pending-requests list renders full-width', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester, width: 360);

      expect(tester.takeException(), isNull);
      expect(find.text('Renault Clio'), findsOneWidget);
    });

    testWidgets('No overflow at a wide (tablet/desktop) width — still single column, no side-by-side sidebar', (
      WidgetTester tester,
    ) async {
      await seedMechanicAccount();
      await seedAppointment('req-1', appointmentDate: daysFromNow(0), createdAt: DateTime.now());

      await pumpScreen(tester, width: 900, height: 1400);

      expect(tester.takeException(), isNull);
      expect(find.text('Renault Clio'), findsOneWidget);
      // There is nothing left to sit beside the pending-requests list any
      // more — no former sidebar card exists at any width.
      expect(find.text('Bugünün Programı'), findsNothing);
      expect(find.text('Servis Performansınız'), findsNothing);
    });
  });
}
