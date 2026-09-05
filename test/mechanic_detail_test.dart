import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/models/mechanic.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
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

  testWidgets('Tapping a search result opens the mechanic detail page with full info', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.tap(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')));
    await tester.pumpAndSettle();

    final detailScope = find.byType(MechanicDetailPage);
    expect(detailScope, findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.text('Hızlı Lastikçi')), findsWidgets);
    expect(find.descendant(of: detailScope, matching: find.text('Onaylı Usta')), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.text('42')), findsOneWidget);
    // No distance assertion: real mechanicAccounts have no real geolocation
    // data yet, so the distance stat tile was removed from this page.
    expect(find.descendant(of: detailScope, matching: find.text('₺200 - ₺380')), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.text('Her gün: 09:00 - 20:00')), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.text('Randevu Al')), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.byIcon(Icons.call_outlined)), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.byIcon(Icons.directions_outlined)), findsOneWidget);
  });

  testWidgets('Tapping the call button shows feedback with the phone number', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.tap(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.pump();

    expect(find.textContaining('0212 667 45 09'), findsOneWidget);
  });

  testWidgets(
    'Repeat-customer tile is hidden entirely (not a muted placeholder) when repeatCustomerCount is 0/absent, '
    'and the price tile takes the full row alone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // No mechanicAccounts document at all for this business — same
      // "no data yet" case fetchRepeatCustomerCount returns null for.
      await tester.pumpWidget(
        const MaterialApp(
          home: MechanicDetailPage(
            mechanic: Mechanic(
              name: 'Yeni Usta',
              rating: 0,
              reviewCount: 0,
              phone: '5551234567',
              address: 'Test Adres',
              priceMin: 200,
              priceMax: 400,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tekrar Müşteri'), findsNothing);
      expect(find.textContaining('Tekrar Tercih'), findsNothing);
      // The price tile still renders correctly, alone.
      expect(find.text('Fiyat Aralığı'), findsOneWidget);
      expect(find.text('₺200 - ₺400'), findsOneWidget);
    },
  );
}
