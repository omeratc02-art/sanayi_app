import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
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
    expect(find.descendant(of: detailScope, matching: find.text('%84')), findsOneWidget);
    expect(find.descendant(of: detailScope, matching: find.text('0.8 km')), findsOneWidget);
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
}
