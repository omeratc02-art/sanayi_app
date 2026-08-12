import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/home/home_tab.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pumpAndSettle();
  }

  testWidgets('Tapping a home category opens search pre-filtered by that category', (WidgetTester tester) async {
    await pumpApp(tester);

    final lastikCategory = find.descendant(of: find.byType(HomeTab), matching: find.text('Lastik & Jant'));
    await tester.tap(lastikCategory);
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    expect(find.descendant(of: searchScope, matching: find.text('Usta Ara')), findsOneWidget);
    expect(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')), findsOneWidget);
    expect(find.descendant(of: searchScope, matching: find.text('Master Fren Sistemleri')), findsNothing);
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
