import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/mechanic/auth/mechanic_login_page.dart';
import 'package:sanayi_app/screens/auth/login_page.dart';
import 'package:sanayi_app/screens/home/main_shell.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
  // Runs before every test in this file — guarantees firebaseAuthInstance/
  // firestoreInstance are always a safe mock/fake before any widget touches
  // them. Without this, a test that never explicitly assigns its own mock
  // (e.g. the plain login-screen render below) would still trigger the real
  // FirebaseAuth.instance/FirebaseFirestore.instance lazy initializers the
  // first time DevModeLauncher's sign-out call (or anything else) touches
  // them — and this test process never calls Firebase.initializeApp().
  // GoogleSignInPlatform.instance needs the same treatment: it defaults to
  // a throwing placeholder outside a real app run (see
  // FakeGoogleSignInPlatform's own doc comment).
  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth();
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
  }

  testWidgets('App opens on the login screen', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sanayi App'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Kayıt Ol'), findsOneWidget);
    expect(find.text('Misafir olarak devam et'), findsNothing);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('Signing in with a mocked FirebaseAuth user navigates to the home page and replaces the login screen', (
    WidgetTester tester,
  ) async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-user-id', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );

    await pumpApp(tester);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Giriş Yap')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Aracın için her şey burada!'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('Giriş Yap and Kayıt Ol both open their auth dialog without navigating away', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    // Not widgetWithText(AlertDialog, 'Giriş Yap') — the dialog's title and
    // its submit button both say 'Giriş Yap', so that finder matches this
    // one dialog twice (once per matching descendant) instead of once.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'E-posta'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ad Soyad'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets(
    '"İşletmeni Ekle" opens real mechanic registration (MechanicLoginPage) — the only way a real mechanic '
    'reaches it without ever seeing DevModeLauncher\'s developer-facing picker',
    (WidgetTester tester) async {
      await pumpApp(tester);

      // Both spans render inside one bare RichText (not Text.rich), which
      // find.text/find.textContaining don't match — same established
      // pattern as appointment_negotiation_test.dart's own RichText finder.
      bool anyRichTextContains(String text) => tester
          .widgetList<RichText>(find.byType(RichText))
          .any((richText) => richText.text.toPlainText().contains(text));

      expect(anyRichTextContains('İşletme sahibi misiniz?'), isTrue);
      expect(anyRichTextContains('İşletmeni Ekle'), isTrue);

      final linkButton = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('İşletmeni Ekle'),
        ),
        matching: find.byType(TextButton),
      );
      await tester.tap(linkButton);
      await tester.pumpAndSettle();

      expect(find.byType(MechanicLoginPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    },
  );
}
