import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/mechanic/home/mechanic_home_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
  setUp(() {
    // signedIn: false — createUserWithEmailAndPassword below is what
    // actually signs the mocked user in, same as a real registration.
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-mechanic-uid', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  Future<void> openMechanicRegisterDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Usta Modu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
  }

  Future<void> submitAndWaitForNavigation(WidgetTester tester) async {
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Kayıt Ol')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Registering as Araç Tamiri picks a real catalog business and writes hizmetTürü: tamir', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    // 'tamir' is the default selection — the dropdown is already showing.
    await tester.tap(find.text('Usta / İşletme Adı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızlı Lastikçi').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'tamirci@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await submitAndWaitForNavigation(tester);

    expect(find.byType(MechanicHomePage), findsOneWidget);

    final snapshot = await firestoreInstance.collection('mechanicAccounts').get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();
    expect(data['name'], 'Hızlı Lastikçi');
    expect(data['hizmetTürü'], 'tamir');
    expect(data['email'], 'tamirci@example.com');
    // Bootstrapped from the picked catalog entry, same as before hizmetTürü
    // selection existed.
    expect(data['phone'], isNotNull);
    expect(data['specialty'], isNotNull);
  });

  testWidgets('Registering as Ekspertiz uses a typed business name (no MockData catalog) and writes hizmetTürü: ekspertiz', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    await tester.tap(find.text('Ekspertiz').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'İşletme Adı'), 'Konya Ekspertiz Merkezi');
    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'ekspertiz@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await submitAndWaitForNavigation(tester);

    expect(find.byType(MechanicHomePage), findsOneWidget);

    final snapshot = await firestoreInstance.collection('mechanicAccounts').get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();
    expect(data['name'], 'Konya Ekspertiz Merkezi');
    expect(data['hizmetTürü'], 'ekspertiz');
    expect(data['email'], 'ekspertiz@example.com');
    // No MockData catalog entry exists for a new Ekspertiz business — these
    // fields must not be fabricated, unlike the tamir path above.
    expect(data.containsKey('phone'), isFalse);
    expect(data.containsKey('specialty'), isFalse);
    expect(data.containsKey('hizmetler'), isFalse);
  });

  testWidgets('Submitting without a business name shows an error and does not write to Firestore', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    await tester.tap(find.text('Ekspertiz').first);
    await tester.pumpAndSettle();
    // Deliberately leave "İşletme Adı" empty.
    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'ekspertiz@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Kayıt Ol')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lütfen usta/işletme adı, e-posta ve şifrenizi girin.'), findsOneWidget);
    expect((await firestoreInstance.collection('mechanicAccounts').get()).docs, isEmpty);
  });
}
