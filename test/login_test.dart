import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/auth/login_page.dart';
import 'package:sanayi_app/screens/home/main_shell.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();
  }

  testWidgets('App opens on the login screen', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sanayi App'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Kayıt Ol'), findsOneWidget);
    expect(find.text('Misafir olarak devam et'), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('Continue as guest navigates to the home page and replaces the login screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Aracınıza ne oldu?'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('Giriş Yap and Kayıt Ol show a coming-soon message without navigating', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(find.text('Çok yakında!'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
