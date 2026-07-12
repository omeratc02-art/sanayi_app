import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';

void main() {
  testWidgets('Home page renders search bar, categories and bottom nav', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Aracınıza ne oldu?'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsWidgets);
    expect(find.text('Popüler Ustalar'), findsOneWidget);
    expect(find.text('En Yüksek Puanlılar'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Randevular'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
