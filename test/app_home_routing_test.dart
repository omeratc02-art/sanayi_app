import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/dev/dev_mode_launcher.dart';
import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/auth/login_page.dart';
import 'package:sanayi_app/screens/home/main_shell.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

/// resolveAppHome is the real fix for two entry-point gaps found in earlier
/// investigations:
///   1. DevModeLauncher (a screen literally titled "Geliştirici Test
///      Ekranı") was the app's unconditional home in every build, including
///      a real release build.
///   2. Even once (1) was fixed, a real build always opened on LoginPage,
///      even for a customer already signed in from a previous session.
/// kDebugMode itself can't be toggled from a test — it's a compile-time
/// constant, always true inside `flutter test` — so this tests the
/// extracted decision function (resolveAppHome) and the async gate widget
/// around it (CustomerSessionGate) directly instead, both built specifically
/// so this stays true.
void main() {
  // Pumping CustomerSessionGate can resolve as far as a real MainShell,
  // which touches firestoreInstance/firebaseAuthInstance/GoogleSignInPlatform
  // during its own initState (ChatRepository().watchUnreadChats,
  // resolveCustomerId) — same setup login_test.dart's own
  // "navigates to the home page" test already relies on for the same
  // reason, guarding against the real (uninitialized-in-tests)
  // FirebaseAuth.instance/FirebaseFirestore.instance singletons.
  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth();
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  group('resolveAppHome (pure decision function)', () {
    test('Debug build: DevModeLauncher, regardless of session state', () {
      expect(resolveAppHome(isDebugBuild: true, hasSignedInCustomer: false), isA<DevModeLauncher>());
      expect(resolveAppHome(isDebugBuild: true, hasSignedInCustomer: true), isA<DevModeLauncher>());
    });

    test('Real build, no signed-in customer: LoginPage', () {
      final home = resolveAppHome(isDebugBuild: false, hasSignedInCustomer: false);
      expect(home, isA<LoginPage>());
      expect(home, isNot(isA<DevModeLauncher>()));
    });

    test('Real build, a signed-in customer already exists: goes straight to MainShell, skipping LoginPage', () {
      final home = resolveAppHome(isDebugBuild: false, hasSignedInCustomer: true);
      expect(home, isA<MainShell>());
      expect(home, isNot(isA<LoginPage>()));
    });
  });

  group('CustomerSessionGate (widget)', () {
    // firebase_auth_mocks' MockUser is a real implementation of the User
    // interface CustomerSessionGate's Stream<User?> expects — no need for
    // a real Firebase App the way a bare FirebaseAuth.instance call would.
    final mockUser = MockUser(uid: 'test-customer-uid', email: 'test@example.com');

    // Phone-sized viewport, matching the convention already used elsewhere
    // in this codebase (e.g. login_test.dart's own pumpApp) — the default
    // 800x600 test viewport is too small for LoginPage's real content and
    // overflows.
    void setPhoneSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('Shows the startup splash (not LoginPage/MainShell) while the stream hasn\'t emitted yet', (
      WidgetTester tester,
    ) async {
      setPhoneSize(tester);
      final controller = StreamController<User?>();
      addTearDown(controller.close);

      await tester.pumpWidget(MaterialApp(home: CustomerSessionGate(authStateChanges: controller.stream)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(MainShell), findsNothing);
    });

    testWidgets('A real user on the first emission resolves to MainShell, not LoginPage', (
      WidgetTester tester,
    ) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(home: CustomerSessionGate(authStateChanges: Stream<User?>.value(mockUser))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('A null (no session) first emission resolves to LoginPage, not MainShell', (
      WidgetTester tester,
    ) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(home: CustomerSessionGate(authStateChanges: Stream<User?>.value(null))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });
  });
}
