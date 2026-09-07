import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/profile/mechanic_profile_screen.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/common/premium_surface.dart';

/// MechanicProfileScreen shows a mechanic their own completed-job and
/// repeat-customer counts as an always-visible, unthresholded motivational
/// signal — deliberately different from VerifiedJobsBadge (shown to
/// customers on MechanicDetailPage, hidden below its own minThreshold: 10)
/// and from ServiceCenterCard/MechanicDetailPage's own hide-when-zero
/// repeat-customer chip, neither of which this file touches.
///
/// The redesigned layout combines Tamamlanan İş/Tekrar Eden Müşteri/
/// Değerlendirme into one single stats card instead of three stacked
/// "label: value" rows — these tests assert the value and its label as
/// separate real widgets (matching the new _StatColumn structure) rather
/// than the old combined string.
void main() {
  const uid = 'test-mechanic-uid';
  const businessId = 'test-usta-isletmesi';

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: uid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: true,
    );
    firestoreInstance = FakeFirebaseFirestore();
  });

  Future<void> seedProfile({int? repeatCustomerCount, List<String>? hizmetler}) {
    return firestoreInstance.collection('mechanicAccounts').doc(uid).set({
      'businessId': businessId,
      'name': 'Test Usta İşletmesi',
      'email': 'usta@example.com',
      'phone': '5551234567',
      'address': 'Test Sanayi Sitesi, Konya',
      'isVerified': true,
      if (repeatCustomerCount != null) 'repeatCustomerCount': repeatCustomerCount,
      if (hizmetler != null) 'hizmetler': hizmetler,
    });
  }

  Future<void> seedCompletedAppointment(String id) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'işletme_kimliği': businessId,
      'tamamlanmaDurumu': 'dogrulanmis_tamamlandi',
    });
  }

  // Tall by default (matches the convention already used in
  // mechanic_home_screen_test.dart) — this screen's redesigned body (cover
  // header, stats card, contact cards, services chips) is taller than the
  // 800x600 default test viewport, so anything below the fold (e.g. a
  // "Tümünü Gör" tap target) needs real room to actually be hit-testable.
  Future<void> pumpScreen(WidgetTester tester, {double width = 400, double height = 2000}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MechanicProfileScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Shows both stats as a real 0, not hidden, when there is no completed-job or repeat-customer data yet',
    (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      expect(find.text('Tamamlanan İş'), findsOneWidget);
      expect(find.text('Tekrar Eden Müşteri'), findsOneWidget);
      // Both stats resolve to a real 0 (not hidden, not "...") — two
      // separate "0" value widgets.
      expect(find.text('0'), findsNWidgets(2));
      // VerifiedJobsBadge no longer appears on this screen at all — its
      // own rendered text, not just the widget type, since that's what a
      // regression here would actually show.
      expect(find.textContaining('Doğrulanmış İş'), findsNothing);
    },
  );

  testWidgets('Shows real non-zero counts once completed-job and repeat-customer data exist', (
    WidgetTester tester,
  ) async {
    await seedProfile(repeatCustomerCount: 5);
    await seedCompletedAppointment('appt-1');
    await seedCompletedAppointment('appt-2');
    await seedCompletedAppointment('appt-3');
    await pumpScreen(tester);

    expect(find.text('Tamamlanan İş'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Tekrar Eden Müşteri'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets(
    'The three stats render inside exactly one PremiumSurface card, not three separate cards',
    (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      // One card contains all three stat labels — proven by checking each
      // label is a descendant of the SAME single PremiumSurface instance
      // that directly wraps the stats Row (the "İletişim Bilgileri"
      // contact cards below also use PremiumSurface, so this checks
      // descendance from one specific instance, not just the widget type
      // count).
      final statsCard = find.ancestor(of: find.text('Tamamlanan İş'), matching: find.byType(PremiumSurface)).first;
      expect(find.descendant(of: statsCard, matching: find.text('Tekrar Eden Müşteri')), findsOneWidget);
      expect(find.descendant(of: statsCard, matching: find.text('Değerlendirme')), findsOneWidget);
    },
  );

  testWidgets('Değerlendirme shows a real "—" (never a fabricated 0.0) when there is no rating yet', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('—'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('Shows real contact info cards for phone, email, and address', (WidgetTester tester) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Telefon Numarası'), findsOneWidget);
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.text('usta@example.com'), findsOneWidget);
    expect(find.text('Adres'), findsOneWidget);
    // The real address renders twice by design — once as the header's
    // location line (under the business name), once again in the "Adres"
    // contact card below — not a duplicate-rendering bug.
    expect(find.text('Test Sanayi Sitesi, Konya'), findsNWidgets(2));
  });

  testWidgets('Shows real hizmetler as chips, and hides the section entirely when there are none', (
    WidgetTester tester,
  ) async {
    await seedProfile(hizmetler: ['Periyodik Bakım', 'Motor', 'Fren Sistemi']);
    await pumpScreen(tester);

    expect(find.text('Hizmetler'), findsOneWidget);
    expect(find.text('Periyodik Bakım'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('Fren Sistemi'), findsOneWidget);
  });

  testWidgets('No "Hizmetler" section at all when the account has no real services listed', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Hizmetler'), findsNothing);
  });

  testWidgets('"Tümünü Gör" reveals the rest of the services in place when there are more than 6', (
    WidgetTester tester,
  ) async {
    await seedProfile(
      hizmetler: ['Motor', 'Fren Sistemi', 'Klima', 'Elektrik', 'Süspansiyon', 'Egzoz', 'Yağ Değişimi'],
    );
    await pumpScreen(tester);

    expect(find.text('Yağ Değişimi'), findsNothing);
    expect(find.text('Tümünü Gör (7)'), findsOneWidget);

    await tester.tap(find.text('Tümünü Gör (7)'));
    await tester.pumpAndSettle();

    expect(find.text('Yağ Değişimi'), findsOneWidget);
    expect(find.text('Tümünü Gör (7)'), findsNothing);
  });

  testWidgets('No "Ustaya Sor"/"Randevu Al" buttons or promotional content on this screen', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Ustaya Sor'), findsNothing);
    expect(find.text('Randevu Al'), findsNothing);
    expect(find.textContaining('tercih edilme'), findsNothing);
    expect(find.textContaining('kupon'), findsNothing);
  });
}
