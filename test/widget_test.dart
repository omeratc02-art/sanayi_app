import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';

void main() {
  testWidgets('Home page renders hero, categories and bottom nav', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Doğru ustayı güvenle bulun.'), findsOneWidget);
    expect(find.text('Hangi hizmete ihtiyacınız var?'), findsOneWidget);
    expect(find.text('Araçlarım'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Randevularım'), findsOneWidget);
    expect(find.text('Mesajlar'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
