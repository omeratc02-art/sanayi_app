import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/categories/ac_climate_category_page.dart';
import 'package:sanayi_app/screens/categories/motor_category_page.dart';
import 'package:sanayi_app/screens/categories/periodic_maintenance_category_page.dart';
import 'package:sanayi_app/screens/home/home_tab.dart';
import 'package:sanayi_app/screens/home/vehicle_repair_category_page.dart';
import 'package:sanayi_app/screens/service_listing/service_listing_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-user-id', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
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

  // The full sub-service category list moved from HomeTab directly into
  // VehicleRepairCategoryPage — reached by tapping the "Araç Tamiri" card,
  // one of the 3 top-level category cards HomeTab shows instead. Every test
  // below that used to interact with these on HomeTab now goes through
  // this first.
  Future<void> openVehicleRepair(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(HomeTab), matching: find.text('Araç Tamiri')));
    await tester.pumpAndSettle();
  }

  testWidgets('Home shows the main service category cards (Sigorta hidden behind kSigortaEnabled)', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final homeScope = find.byType(HomeTab);
    for (final label in ['Araç Tamiri', 'Ekspertiz']) {
      expect(find.descendant(of: homeScope, matching: find.text(label)), findsOneWidget);
    }
    // Sigorta stays in code (SigortaPage, its route, hizmetTürü:'sigorta'
    // Firestore data) but isn't rendered while kSigortaEnabled is false —
    // see feature_flags.dart.
    expect(find.descendant(of: homeScope, matching: find.text('Sigorta')), findsNothing);
  });

  testWidgets('Tapping Araç Tamiri opens a page with every sub-service category, no truncation', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openVehicleRepair(tester);

    // The old "Tüm Hizmetler" tap-through tile is gone — every real
    // category (the former CategoryList teaser set plus the ones that used
    // to be reachable only via AllCategoriesPage) is visible directly on
    // this page now.
    final vehicleRepairScope = find.byType(VehicleRepairCategoryPage);
    for (final label in [
      'Periyodik Bakım',
      'Yağ Değişimi',
      'Fren Sistemi',
      'Motor',
      'Akü & Elektrik',
      'Lastik & Jant',
      'Şanzıman ve Debriyaj',
      'Klima',
      'Süspansiyon & Direksiyon',
      'Kaporta & Boya',
      'Cam & Aydınlatma',
      'Egzoz Sistemi',
    ]) {
      expect(find.descendant(of: vehicleRepairScope, matching: find.text(label)), findsOneWidget);
    }
    expect(find.descendant(of: vehicleRepairScope, matching: find.text('Tüm Hizmetler')), findsNothing);
  });

  testWidgets('Tapping "Klima" on Araç Tamiri opens its dedicated category page directly', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openVehicleRepair(tester);

    // Klima used to be reachable only via the "Tümünü Gör" -> AllCategoriesPage
    // hop — now it's a direct tap on Araç Tamiri itself, same as any other
    // category, and still dispatches to its real dedicated page.
    final vehicleRepairScope = find.byType(VehicleRepairCategoryPage);
    await tester.ensureVisible(find.descendant(of: vehicleRepairScope, matching: find.text('Klima')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: vehicleRepairScope, matching: find.text('Klima')));
    await tester.pumpAndSettle();

    expect(find.byType(AcClimateCategoryPage), findsOneWidget);
  });

  testWidgets('Tapping "Motor" on Araç Tamiri opens its dedicated category page', (WidgetTester tester) async {
    await pumpApp(tester);
    await openVehicleRepair(tester);

    final vehicleRepairScope = find.byType(VehicleRepairCategoryPage);
    await tester.tap(find.descendant(of: vehicleRepairScope, matching: find.text('Motor')));
    await tester.pumpAndSettle();

    expect(find.byType(MotorCategoryPage), findsOneWidget);
  });

  testWidgets(
    'Tapping "Periyodik Bakım" opens its 2-entry list, and tapping an entry goes straight to ServiceListingPage',
    (WidgetTester tester) async {
      await pumpApp(tester);
      await openVehicleRepair(tester);

      final vehicleRepairScope = find.byType(VehicleRepairCategoryPage);
      await tester.tap(find.descendant(of: vehicleRepairScope, matching: find.text('Periyodik Bakım')));
      await tester.pumpAndSettle();

      // One tap in — same depth as every other category (e.g. Motor,
      // Klima above) — no intermediate informational/checklist page.
      expect(find.byType(PeriodicMaintenanceCategoryPage), findsOneWidget);
      final periodicScope = find.byType(PeriodicMaintenanceCategoryPage);
      expect(find.descendant(of: periodicScope, matching: find.text('10.000–20.000 km Bakımı')), findsOneWidget);
      expect(find.descendant(of: periodicScope, matching: find.text('Ağır Bakım')), findsOneWidget);

      await tester.tap(find.descendant(of: periodicScope, matching: find.text('Ağır Bakım')));
      await tester.pumpAndSettle();

      final listingPage = tester.widget<ServiceListingPage>(find.byType(ServiceListingPage));
      expect(listingPage.serviceName, 'Ağır Bakım');
      expect(listingPage.hizmetTuru, 'tamir');
    },
  );
}
