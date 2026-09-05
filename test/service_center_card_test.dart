import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/models/mechanic.dart';
import 'package:sanayi_app/utils/chat_id.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/service_listing/service_center_card.dart';

/// The name/trust-badge row previously overflowed and broke names
/// mid-word on realistic phone widths once the badge's own natural width
/// (driven by its letter-grade subtitle) squeezed the name's flex share
/// too far. This pumps the card at a real phone width and asserts no
/// RenderFlex overflow is thrown for a range of business-name lengths.
void main() {
  setUp(() {
    firestoreInstance = FakeFirebaseFirestore();
  });

  Future<void> pumpCard(WidgetTester tester, String name) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceCenterCard(
            mechanic: Mechanic(
              name: name,
              specialty: 'Genel Bakım',
              rating: 4.6,
              reviewCount: 12,
              isVerified: true,
              repeatCustomerRate: 80,
              phone: '5551234567',
              address: 'Kadıköy, İstanbul',
            ),
            serviceName: 'Genel Bakım',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('realistic business names render without overflow', (WidgetTester tester) async {
    for (final name in ['Güven Oto Bakım', 'Hızlı Lastikçi', 'Merkez Oto Servis ve Bakım']) {
      await pumpCard(tester, name);
      expect(tester.takeException(), isNull, reason: 'Overflow for "$name"');
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('a genuinely long business name still renders without overflow', (WidgetTester tester) async {
    await pumpCard(tester, 'Anadolu Yakası Merkez Oto Tamir ve Bakım Servisi Ltd. Şti.');
    expect(tester.takeException(), isNull);
  });

  group('repeat-customer count chip', () {
    // Deliberately doesn't contain "Tekrar Tercih" itself — several
    // assertions below search for that substring, and the mechanic's own
    // name (always rendered on the card) would otherwise self-match.
    const name = 'Sayaç Deneme Ustası';
    final businessId = mechanicChatId(name);

    testWidgets('shows the raw count when repeatCustomerCount > 0', (WidgetTester tester) async {
      await firestoreInstance.collection('mechanicAccounts').add({
        'name': name,
        'businessId': businessId,
        'repeatCustomerCount': 7,
      });

      await pumpCard(tester, name);

      expect(find.text('7 Kez Tekrar Tercih Edildi'), findsOneWidget);
    });

    testWidgets('hides the chip entirely when repeatCustomerCount is 0 — not a muted placeholder', (
      WidgetTester tester,
    ) async {
      await firestoreInstance.collection('mechanicAccounts').add({
        'name': name,
        'businessId': businessId,
        'repeatCustomerCount': 0,
      });

      await pumpCard(tester, name);

      expect(find.textContaining('Tekrar Tercih'), findsNothing);
      expect(find.textContaining('Tekrar tercih'), findsNothing);
    });

    testWidgets('hides the chip entirely when no matching mechanicAccounts document exists', (
      WidgetTester tester,
    ) async {
      // No seeding at all — mirrors every other test in this file, which
      // never seeds a matching document either.
      await pumpCard(tester, name);

      expect(find.textContaining('Tekrar Tercih'), findsNothing);
      expect(find.textContaining('Tekrar tercih'), findsNothing);
    });
  });
}
