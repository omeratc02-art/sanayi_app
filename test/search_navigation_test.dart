import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/categories/tire_wheel_category_page.dart';
import 'package:sanayi_app/screens/home/home_tab.dart';
import 'package:sanayi_app/screens/home/vehicle_repair_category_page.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

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

  testWidgets('Tapping a home category on Araç Tamiri opens its dedicated category page directly', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // Every sub-service category now shows directly on VehicleRepairCategoryPage
    // (no more truncated teaser list behind a "Tümünü Gör" tap-through), reached
    // by tapping the "Araç Tamiri" card — one of the 3 top-level category cards
    // HomeTab shows instead.
    await tester.tap(find.descendant(of: find.byType(HomeTab), matching: find.text('Araç Tamiri')));
    await tester.pumpAndSettle();

    // "Lastik & Jant" has a dedicated page in the single, unified dispatch
    // MainShell._openVehicleRepair now uses for every category shown here —
    // it no longer falls through to generic pre-filtered search the way
    // tapping it via the old separate AllCategoriesPage hop used to.
    final lastikCategory = find.descendant(
      of: find.byType(VehicleRepairCategoryPage),
      matching: find.text('Lastik & Jant'),
    );
    await tester.ensureVisible(lastikCategory);
    await tester.pumpAndSettle();
    await tester.tap(lastikCategory);
    await tester.pumpAndSettle();

    expect(find.byType(TireWheelCategoryPage), findsOneWidget);
  });

  testWidgets('Typing in the search field filters results by name', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.enterText(find.descendant(of: searchScope, matching: find.byType(TextField)), 'akü');
    await tester.pumpAndSettle();

    expect(find.descendant(of: searchScope, matching: find.text('Öztürk Elektrik')), findsOneWidget);
    expect(find.descendant(of: searchScope, matching: find.text('Aksoy Akü Merkezi')), findsOneWidget);
    expect(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')), findsNothing);
  });
}
