import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/models/mechanic.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/screens/search/search_tab.dart';
import 'package:sanayi_app/utils/chat_id.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';
import 'test_utils/mechanic_seed.dart';

void main() {
  setUp(() async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-user-id', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
    // SearchTab now queries mechanicAccounts directly instead of MockData.
    await seedMechanicAccounts(firestoreInstance);
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

    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Giriş Yap')),
    );
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
    expect(find.descendant(of: detailScope, matching: find.text('42')), findsOneWidget);
    // No distance assertion: real mechanicAccounts have no real geolocation
    // data yet, so the distance stat tile was removed from this page.
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

  testWidgets(
    'Repeat-customer tile is hidden entirely (not a muted placeholder) when repeatCustomerCount is 0/absent, '
    'and the price tile takes the full row alone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // No mechanicAccounts document at all for this business — same
      // "no data yet" case fetchRepeatCustomerCount returns null for.
      await tester.pumpWidget(
        const MaterialApp(
          home: MechanicDetailPage(
            mechanic: Mechanic(
              name: 'Yeni Usta',
              rating: 0,
              reviewCount: 0,
              phone: '5551234567',
              address: 'Test Adres',
              priceMin: 200,
              priceMax: 400,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tekrar Müşteri'), findsNothing);
      expect(find.textContaining('Tekrar Tercih'), findsNothing);
      // The price tile still renders correctly, alone.
      expect(find.text('Fiyat Aralığı'), findsOneWidget);
      expect(find.text('₺200 - ₺400'), findsOneWidget);
    },
  );

  testWidgets('Opening the detail page as a real signed-in customer records a real profile view', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();

    final searchScope = find.byType(SearchTab);
    await tester.tap(find.descendant(of: searchScope, matching: find.text('Hızlı Lastikçi')));
    await tester.pumpAndSettle();

    expect(find.byType(MechanicDetailPage), findsOneWidget);

    // recordProfileView's transaction runs as a real (non-faked) async
    // write kicked off from initState — pumpAndSettle above already let it
    // resolve, but this confirms it against the real seeded document
    // rather than trusting timing alone.
    final matches = await firestoreInstance
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: 'hizli-lastikci')
        .get();
    expect(matches.docs, hasLength(1));
    expect((matches.docs.single.data()['profileViewCount'] as num?)?.toInt(), 1);
  });

  testWidgets('Opening the detail page while signed out does not record a profile view', (
    WidgetTester tester,
  ) async {
    firebaseAuthInstance = MockFirebaseAuth(signedIn: false);
    firestoreInstance = FakeFirebaseFirestore();
    await seedMechanicAccounts(firestoreInstance);

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MechanicDetailPage(
          mechanic: Mechanic(
            name: 'Hızlı Lastikçi',
            rating: 4.7,
            reviewCount: 96,
            phone: '0212 667 45 09',
            address: 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
            priceMin: 200,
            priceMax: 380,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final matches = await firestoreInstance
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: 'hizli-lastikci')
        .get();
    expect((matches.docs.single.data()['profileViewCount'] as num?)?.toInt() ?? 0, 0);
  });

  group('Cover photo and gallery', () {
    // Distinct business names/ids from seedMechanicAccounts' own 4 seeded
    // businesses, and from each other — avoids the exact real businessId
    // collision this app once had in production data (two documents
    // sharing one businessId), which would make fetchProfileByBusinessId's
    // query non-deterministic.
    Future<void> pumpDetailPage(
      WidgetTester tester, {
      required String name,
      String? coverPhotoUrl,
      List<String?>? galleryPhotoUrls,
    }) async {
      await firestoreInstance.collection('mechanicAccounts').add({
        'businessId': mechanicChatId(name),
        'name': name,
        'email': 'usta@example.com',
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
        if (galleryPhotoUrls != null) 'galleryPhotoUrls': galleryPhotoUrls,
      });

      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MechanicDetailPage(
            mechanic: Mechanic(
              name: name,
              rating: 4.5,
              reviewCount: 10,
              phone: '0212 000 00 00',
              address: 'Test Adres',
              priceMin: 200,
              priceMax: 400,
            ),
          ),
        ),
      );
      // Same reasoning as mechanic_profile_screen_test.dart's own cover
      // photo test: not pumpAndSettle — Image.network never resolves
      // against a real network here, and its loadingBuilder's
      // indeterminate spinner would make pumpAndSettle time out. A few
      // bounded pumps are enough for the profile fetch itself (a plain
      // Future) to resolve and the Image widgets to be built.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('Shows the real cover photo and real gallery photos when both exist', (WidgetTester tester) async {
      const coverUrl = 'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_covers/foto-galeri-test-ustasi/cover.jpg';
      const galleryUrl0 = 'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_gallery/foto-galeri-test-ustasi/0.jpg';
      const galleryUrl2 = 'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_gallery/foto-galeri-test-ustasi/2.jpg';

      await pumpDetailPage(
        tester,
        name: 'Foto Galeri Test Ustası',
        coverPhotoUrl: coverUrl,
        // Only 2 of 3 slots real — proves the strip shows exactly the
        // real photos and nothing for the empty middle slot, never a
        // placeholder tile (unlike MechanicProfileScreen's own management
        // view, which deliberately does show all 3 slots).
        galleryPhotoUrls: [galleryUrl0, null, galleryUrl2],
      );

      final urls = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as NetworkImage).url)
          .toSet();
      expect(urls, {coverUrl, galleryUrl0, galleryUrl2});
      // Exactly 3 — nothing rendered for the null middle gallery slot.
      expect(find.byType(Image), findsNWidgets(3));
    });

    testWidgets('Shows the gradient fallback (no Image) and no gallery strip when neither exists', (
      WidgetTester tester,
    ) async {
      await pumpDetailPage(tester, name: 'Foto Yok Test Ustası');

      expect(find.byType(Image), findsNothing);
    });
  });
}
