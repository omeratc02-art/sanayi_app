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

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall surface — this screen has a lot more vertical content (unified
    // top section, new-requests list, today's-appointments timeline,
    // service-performance tiles) than the default test window, and a plain
    // ListView still needs each item within the viewport/cache extent to
    // actually build it.
    tester.view.physicalSize = const Size(400, 3000);
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
    // The generic (no-name) fallback greeting must not show when a real
    // business name exists.
    expect(find.text('${expectedGreetingPrefix()} 👋'), findsNothing);
  });

  testWidgets('Falls back to a generic greeting when there is no mechanicAccounts profile', (
    WidgetTester tester,
  ) async {
    // Deliberately no seedMechanicAccount() call.
    await pumpScreen(tester);

    expect(find.text('${expectedGreetingPrefix()} 👋'), findsOneWidget);
  });

  testWidgets(
    "Top section's workload numbers show real live counts, not hidden at 0, with no hardcoded mock content",
    (WidgetTester tester) async {
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

      await pumpScreen(tester);

      // Today's-confirmed-appointment count and new-request count — the
      // only two numbers the unified top section shows (upcoming/overdue
      // counts and any weekly total are explicitly out of scope for this
      // section and are not displayed anywhere on this screen).
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('Bugünkü Randevu'), findsOneWidget);
      expect(find.text('Yeni Talep'), findsOneWidget);
      expect(find.text('Randevularınızı ve hizmet taleplerinizi yönetin.'), findsOneWidget);

      // The old hardcoded elements are fully gone.
      expect(find.text('3'), findsNothing);
      expect(find.textContaining('Ahmet Yılmaz'), findsNothing);
      expect(find.text('Önemli Gelişmeler'), findsNothing);
    },
  );

  testWidgets('Empty state: zero pending/today appointments shows real zeros, not a hidden/broken layout', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await pumpScreen(tester);

    expect(find.text('Bekleyen talebiniz yok.'), findsOneWidget);
    // The top section's 2 counts (today/new) plus the service-performance
    // section's real repeat-customer count (also unthresholded — 0 is a
    // real, shown value, not hidden) — 3 in total. Rating and on-time-rate
    // show '—' instead of a fake 0 since there's no completed job yet to
    // compute either from.
    expect(find.text('0'), findsNWidgets(3));
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

      // The older request appears as a compact preview beneath the
      // spotlighted one, with a real date-based tag instead (appointmentDate
      // is 2 days out -> "Yaklaşan"). The unified top section no longer has
      // an "upcoming" secondary chip of its own (that concept was dropped
      // when the old separate "Bugün" overview card was folded in — see
      // _MechanicHomeHeader), so this tag is now unambiguous.
      expect(find.text('Yaklaşan'), findsOneWidget);
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

  testWidgets(
    'Other-requests preview tags Bugün/Yarın correctly, and caps at 3 with a real "Tümünü Gör" overflow link',
    (WidgetTester tester) async {
      await seedMechanicAccount();
      // Newest -> the spotlighted priority card (shows no date-bucket tag
      // of its own). The other 3 are previewed newest-first, but the
      // section only ever shows up to 3 cards total (1 spotlighted + 2
      // more) — so with 4 pending requests overall, the oldest one
      // (req-overdue) is deliberately not rendered in the preview, only
      // reachable via "Tümünü Gör (4)". This matches the redesign's
      // "shouldn't consume almost the entire screen" cap.
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

      // 'Bugün' and 'Yarın' each come only from their request's own
      // date-based tag — the top section's today/new-request labels are
      // 'Bugünkü Randevu'/'Yeni Talep', not 'Bugün'/'Yarın', so neither
      // collides.
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('Yarın'), findsOneWidget);
      // req-overdue's own "Gecikti" tag is capped out of the preview, and
      // the unified top section no longer has its own "delayed" secondary
      // chip (dropped when the old separate overview card was folded in),
      // so "Gecikti" doesn't appear anywhere on screen in this scenario —
      // only reachable via "Tümünü Gör".
      expect(find.text('Gecikti'), findsNothing);
      expect(find.text('Tümünü Gör (4)'), findsOneWidget);
    },
  );

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

  testWidgets("Bugünün Randevuları shows real confirmed appointments sorted earliest-first", (
    WidgetTester tester,
  ) async {
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
    expect(find.text('Opel Astra'), findsOneWidget);
    expect(find.text('VW Golf'), findsOneWidget);

    // Earliest appointment renders above the later one.
    final earlyY = tester.getTopLeft(find.text('08:00')).dy;
    final lateY = tester.getTopLeft(find.text('14:30')).dy;
    expect(earlyY, lessThan(lateY));
  });

  testWidgets('Bugünün Randevuları shows a compact empty state when there are none today', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await pumpScreen(tester);

    expect(find.text('Bugün için planlanmış randevu yok'), findsOneWidget);
  });

  testWidgets(
    'Servis Performansı shows the real repeat-customer count, and — for rating/on-time when no completed job exists yet',
    (WidgetTester tester) async {
      await seedMechanicAccount();
      await firestoreInstance.collection('mechanicAccounts').doc(mechanicUid).update({'repeatCustomerCount': 6});

      await pumpScreen(tester);

      expect(find.text('Servis Performansı'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      // Rating and on-time-completion both have no eligible verified-
      // completed appointment yet, so both show '—' rather than a
      // fabricated 0/0%.
      expect(find.text('—'), findsNWidgets(2));
    },
  );

  testWidgets('Servis Performansı shows the verified badge only for a real-verified account', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount(isVerified: true);
    await pumpScreen(tester);

    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets('Servis Performansı shows no verified badge for an unverified account', (WidgetTester tester) async {
    await seedMechanicAccount(isVerified: false);
    await pumpScreen(tester);

    expect(find.byIcon(Icons.verified_rounded), findsNothing);
  });

  testWidgets(
    'Top section shows the real SanayiGo wordmark (logo badge beside the text, not stacked) plus the slogan',
    (WidgetTester tester) async {
      await seedMechanicAccount();
      await pumpScreen(tester);

      expect(find.text('SanayiGo'), findsOneWidget);
      expect(find.text('Güvenle Yönetin'), findsOneWidget);
      // The real app-icon foreground art (see pubspec.yaml's assets entry),
      // not a placeholder — same file the launcher icon is generated from.
      // (assets/icon/sanayigo_logo.png was requested to replace this but
      // does not exist anywhere in the project — see this file's own
      // _logoAssetPath doc comment — so this still points at the real,
      // existing, correctly pubspec-registered asset.)
      final logo = tester.widget<Image>(find.byType(Image));
      expect(logo.image, isA<AssetImage>());
      expect((logo.image as AssetImage).assetName, 'assets/icon/app_icon_foreground.png');
      // The asset actually loads (no broken-image errorBuilder fallback
      // triggered) — pumpScreen's pumpAndSettle already resolved image
      // loading, so the real Image widget having a non-null size confirms
      // it rendered, not the errorBuilder's SizedBox.shrink().
      expect(tester.getSize(find.byType(Image)).height, greaterThan(0));

      // Side-by-side now (the top-section redesign moved the logo into a
      // small colored badge to the left of the identity text column,
      // replacing the earlier stacked logo-above-text arrangement): the
      // logo badge sits to the left of the "SanayiGo" text, not above it.
      final logoRect = tester.getRect(find.byType(Image));
      final textRect = tester.getRect(find.text('SanayiGo'));
      expect(logoRect.right, lessThanOrEqualTo(textRect.left));
    },
  );

  testWidgets(
    "Top section's workload numbers use the same real counts as the rest of the screen, not a second computation",
    (WidgetTester tester) async {
      await seedMechanicAccount();
      // 2 confirmed appointments today.
      await seedConfirmedAppointment(
        id: 'appt-1',
        appointmentDate: daysFromNow(0),
        time: '09:00',
        vehicleModel: 'Fiat Egea',
        serviceType: 'Yağ Değişimi',
      );
      await seedConfirmedAppointment(
        id: 'appt-2',
        appointmentDate: daysFromNow(0),
        time: '11:00',
        vehicleModel: 'Renault Clio',
        serviceType: 'Lastik Değişimi',
      );
      // 4 pending ("new") requests — created "now" so the spotlighted
      // request's own tag reads "Bugün Gelen Talep" rather than "Yeni
      // Talep", keeping it distinct from the top section's "Yeni Talep"
      // caption label.
      await seedAppointment('req-1', appointmentDate: daysFromNow(1), createdAt: DateTime.now());
      await seedAppointment('req-2', appointmentDate: daysFromNow(1), createdAt: DateTime.now());
      await seedAppointment('req-3', appointmentDate: daysFromNow(1), createdAt: DateTime.now());
      await seedAppointment('req-4', appointmentDate: daysFromNow(1), createdAt: DateTime.now());

      await pumpScreen(tester);

      expect(find.text('Bugünkü Randevu'), findsOneWidget);
      expect(find.text('Yeni Talep'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    },
  );

  testWidgets(
    "Top section's workload numbers show a safe '...' placeholder while loading, never null or a fabricated number",
    (WidgetTester tester) async {
      await seedMechanicAccount();

      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // A single pump (not pumpAndSettle) — catches the screen's very first
      // frame, before resolveMyBusinessId()/the appointment streams have
      // resolved, when todayCount/newRequestsCount are still null.
      await tester.pumpWidget(const MaterialApp(home: MechanicHomeScreen()));

      // Both workload numbers (today + new requests) share the same '...'
      // placeholder convention.
      expect(find.text('...'), findsNWidgets(2));
      expect(find.textContaining('null'), findsNothing);

      // Let everything settle so no pending timers/streams leak into the
      // next test.
      await tester.pumpAndSettle();
    },
  );
}
