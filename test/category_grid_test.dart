import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/categories/all_categories_page.dart';
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

  testWidgets('Home shows all 8 categories as cards', (WidgetTester tester) async {
    await pumpApp(tester);

    final homeScope = find.byType(HomeTab);
    for (final label in [
      'Periyodik Bakım',
      'Yağ Değişimi',
      'Fren Sistemi',
      'Motor',
      'Akü & Elektrik',
      'Lastik & Jant',
      'Şanzıman ve Debriyaj',
      'Tüm Hizmetler',
    ]) {
      expect(find.descendant(of: homeScope, matching: find.text(label)), findsOneWidget);
    }
  });

  testWidgets('All Services page shows additional categories not present on Home', (WidgetTester tester) async {
    await pumpApp(tester);

    for (final label in ['Klima', 'Süspansiyon & Direksiyon', 'Kaporta & Boya', 'Cam & Aydınlatma', 'Egzoz Sistemi']) {
      expect(find.descendant(of: find.byType(HomeTab), matching: find.text(label)), findsNothing);
    }

    await tester.tap(find.descendant(of: find.byType(HomeTab), matching: find.text('Tüm Hizmetler')));
    await tester.pumpAndSettle();

    final allCategoriesScope = find.byType(AllCategoriesPage);
    for (final label in ['Klima', 'Süspansiyon & Direksiyon', 'Kaporta & Boya', 'Cam & Aydınlatma', 'Egzoz Sistemi']) {
      expect(find.descendant(of: allCategoriesScope, matching: find.text(label)), findsOneWidget);
    }
  });

  testWidgets('Tapping "Tüm Hizmetler" on Home opens the all-categories page directly', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.descendant(of: find.byType(HomeTab), matching: find.text('Tüm Hizmetler')));
    await tester.pumpAndSettle();

    expect(find.byType(AllCategoriesPage), findsOneWidget);
    expect(find.text('Tüm Kategoriler'), findsOneWidget);
    expect(find.descendant(of: find.byType(AllCategoriesPage), matching: find.byType(TextField)), findsOneWidget);
  });

  testWidgets('Tümünü Gör on categories opens the all-categories page', (WidgetTester tester) async {
    await pumpApp(tester);

    final categoriesHeader = find.ancestor(
      of: find.text('Hangi hizmete ihtiyacınız var?'),
      matching: find.byType(Row),
    );
    await tester.tap(find.descendant(of: categoriesHeader, matching: find.text('Tümünü Gör')));
    await tester.pumpAndSettle();

    expect(find.byType(AllCategoriesPage), findsOneWidget);
    expect(find.text('Tüm Kategoriler'), findsOneWidget);
  });

  testWidgets('Selecting a category on the all-categories page opens pre-filtered search', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final categoriesHeader = find.ancestor(
      of: find.text('Hangi hizmete ihtiyacınız var?'),
      matching: find.byType(Row),
    );
    await tester.tap(find.descendant(of: categoriesHeader, matching: find.text('Tümünü Gör')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Motor'));
    await tester.pumpAndSettle();

    expect(find.byType(AllCategoriesPage), findsNothing);
    final searchScope = find.byType(SearchTab);
    expect(find.descendant(of: searchScope, matching: find.text('Usta Ara')), findsOneWidget);
  });
}
