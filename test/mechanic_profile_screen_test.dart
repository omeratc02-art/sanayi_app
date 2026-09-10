import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/mechanic/auth/mechanic_login_page.dart';
import 'package:sanayi_app/mechanic/profile/mechanic_profile_screen.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/common/premium_surface.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

/// MechanicProfileScreen shows a mechanic their own completed-job and
/// repeat-customer counts as an always-visible, unthresholded motivational
/// signal — deliberately different from VerifiedJobsBadge (shown to
/// customers on MechanicDetailPage, hidden below its own minThreshold: 10)
/// and from ServiceCenterCard/MechanicDetailPage's own hide-when-zero
/// repeat-customer chip, neither of which this file touches.
///
/// The redesigned layout combines Tamamlanan İş/Tekrar Eden Müşteri/
/// Değerlendirme into one single stats card instead of three stacked
/// "label: value" rows — these tests assert the value and its label as
/// separate real widgets (matching the new _StatColumn structure) rather
/// than the old combined string.
void main() {
  const uid = 'test-mechanic-uid';
  const businessId = 'test-usta-isletmesi';

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: uid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: true,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  Future<void> seedProfile({
    int? repeatCustomerCount,
    List<String>? hizmetler,
    String? coverPhotoUrl,
    List<String?>? galleryPhotoUrls,
  }) {
    return firestoreInstance.collection('mechanicAccounts').doc(uid).set({
      'businessId': businessId,
      'name': 'Test Usta İşletmesi',
      'email': 'usta@example.com',
      'phone': '5551234567',
      'address': 'Test Sanayi Sitesi, Konya',
      'isVerified': true,
      if (repeatCustomerCount != null) 'repeatCustomerCount': repeatCustomerCount,
      if (hizmetler != null) 'hizmetler': hizmetler,
      if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
      if (galleryPhotoUrls != null) 'galleryPhotoUrls': galleryPhotoUrls,
    });
  }

  Future<void> seedCompletedAppointment(String id) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'işletme_kimliği': businessId,
      'tamamlanmaDurumu': 'dogrulanmis_tamamlandi',
    });
  }

  // Tall by default (matches the convention already used in
  // mechanic_home_screen_test.dart) — this screen's redesigned body (cover
  // header, stats card, contact cards, services chips) is taller than the
  // 800x600 default test viewport, so anything below the fold (e.g. a
  // "Tümünü Gör" tap target) needs real room to actually be hit-testable.
  Future<void> pumpScreen(WidgetTester tester, {double width = 400, double height = 2000}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MechanicProfileScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Shows both stats as a real 0, not hidden, when there is no completed-job or repeat-customer data yet',
    (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      expect(find.text('Tamamlanan İş'), findsOneWidget);
      expect(find.text('Tekrar Eden Müşteri'), findsOneWidget);
      // Both stats resolve to a real 0 (not hidden, not "...") — two
      // separate "0" value widgets.
      expect(find.text('0'), findsNWidgets(2));
      // VerifiedJobsBadge no longer appears on this screen at all — its
      // own rendered text, not just the widget type, since that's what a
      // regression here would actually show.
      expect(find.textContaining('Doğrulanmış İş'), findsNothing);
    },
  );

  testWidgets('Shows real non-zero counts once completed-job and repeat-customer data exist', (
    WidgetTester tester,
  ) async {
    await seedProfile(repeatCustomerCount: 5);
    await seedCompletedAppointment('appt-1');
    await seedCompletedAppointment('appt-2');
    await seedCompletedAppointment('appt-3');
    await pumpScreen(tester);

    expect(find.text('Tamamlanan İş'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Tekrar Eden Müşteri'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets(
    'The three stats render inside exactly one PremiumSurface card, not three separate cards',
    (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      // One card contains all three stat labels — proven by checking each
      // label is a descendant of the SAME single PremiumSurface instance
      // that directly wraps the stats Row (the "İletişim Bilgileri"
      // contact cards below also use PremiumSurface, so this checks
      // descendance from one specific instance, not just the widget type
      // count).
      final statsCard = find.ancestor(of: find.text('Tamamlanan İş'), matching: find.byType(PremiumSurface)).first;
      expect(find.descendant(of: statsCard, matching: find.text('Tekrar Eden Müşteri')), findsOneWidget);
      expect(find.descendant(of: statsCard, matching: find.text('Değerlendirme')), findsOneWidget);
    },
  );

  testWidgets('Değerlendirme shows a real "—" (never a fabricated 0.0) when there is no rating yet', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('—'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('Shows real contact info cards for phone, email, and address', (WidgetTester tester) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Telefon Numarası'), findsOneWidget);
    expect(find.text('5551234567'), findsOneWidget);
    expect(find.text('E-posta'), findsOneWidget);
    expect(find.text('usta@example.com'), findsOneWidget);
    expect(find.text('Adres'), findsOneWidget);
    // The real address renders twice by design — once as the header's
    // location line (under the business name), once again in the "Adres"
    // contact card below — not a duplicate-rendering bug.
    expect(find.text('Test Sanayi Sitesi, Konya'), findsNWidgets(2));
  });

  testWidgets('Shows real hizmetler as chips, and hides the section entirely when there are none', (
    WidgetTester tester,
  ) async {
    await seedProfile(hizmetler: ['Periyodik Bakım', 'Motor', 'Fren Sistemi']);
    await pumpScreen(tester);

    expect(find.text('Hizmetler'), findsOneWidget);
    expect(find.text('Periyodik Bakım'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('Fren Sistemi'), findsOneWidget);
  });

  testWidgets('No "Hizmetler" section at all when the account has no real services listed', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Hizmetler'), findsNothing);
  });

  testWidgets('"Tümünü Gör" reveals the rest of the services in place when there are more than 6', (
    WidgetTester tester,
  ) async {
    await seedProfile(
      hizmetler: ['Motor', 'Fren Sistemi', 'Klima', 'Elektrik', 'Süspansiyon', 'Egzoz', 'Yağ Değişimi'],
    );
    await pumpScreen(tester);

    expect(find.text('Yağ Değişimi'), findsNothing);
    expect(find.text('Tümünü Gör (7)'), findsOneWidget);

    await tester.tap(find.text('Tümünü Gör (7)'));
    await tester.pumpAndSettle();

    expect(find.text('Yağ Değişimi'), findsOneWidget);
    expect(find.text('Tümünü Gör (7)'), findsNothing);
  });

  testWidgets('No "Ustaya Sor"/"Randevu Al" buttons or promotional content on this screen', (
    WidgetTester tester,
  ) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.text('Ustaya Sor'), findsNothing);
    expect(find.text('Randevu Al'), findsNothing);
    expect(find.textContaining('tercih edilme'), findsNothing);
    expect(find.textContaining('kupon'), findsNothing);
  });

  testWidgets('No copy-to-clipboard or open-in-maps icons anywhere on the screen', (WidgetTester tester) async {
    await seedProfile();
    await pumpScreen(tester);

    expect(find.byIcon(Icons.copy), findsNothing);
    expect(find.byIcon(Icons.copy_outlined), findsNothing);
    expect(find.byIcon(Icons.content_copy), findsNothing);
    expect(find.byIcon(Icons.map), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });

  group('Cover photo', () {
    testWidgets('Shows the gradient fallback header (no Image widget) when no cover photo has been uploaded yet', (
      WidgetTester tester,
    ) async {
      await seedProfile();
      await pumpScreen(tester);

      expect(find.byType(Image), findsNothing);
      // The gradient fallback's own decorative icon avatar (the only
      // storefront icon in this state — the photo variant's separate
      // overlapping avatar only exists once a real photo is shown).
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      // The upload trigger is present even in the fallback state — an
      // upload has to be able to start from "no photo yet".
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('Displays the real cover photo (a real NetworkImage at the real uploaded URL) when coverPhotoUrl exists', (
      WidgetTester tester,
    ) async {
      const url = 'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_covers/test-usta-isletmesi/cover.jpg';
      await seedProfile(coverPhotoUrl: url);

      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MechanicProfileScreen()));
      // Not pumpAndSettle: Image.network never resolves against a real
      // network in this test environment, and its loadingBuilder's
      // indeterminate CircularProgressIndicator would spin forever and
      // make pumpAndSettle time out. A few bounded pumps are enough for
      // the profile fetch (a plain Future, not the network image itself)
      // to resolve and the Image widget to be built and inspectable —
      // checking its configured NetworkImage URL doesn't require the
      // fetch to actually complete.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, url);
      // The overlapping circular avatar only exists in this photo variant.
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });
  });

  group('Gallery photos', () {
    const galleryUrl0 =
        'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_gallery/test-mechanic-uid/0.jpg';
    const galleryUrl2 =
        'https://storage.googleapis.com/sanayi-omer-tr.firebasestorage.app/mechanic_gallery/test-mechanic-uid/2.jpg';

    testWidgets('Shows the real photo for a filled gallery slot', (WidgetTester tester) async {
      await seedProfile(galleryPhotoUrls: [galleryUrl0, null, null]);
      await pumpScreen(tester);

      expect(find.text('Fotoğraflar'), findsOneWidget);
      // No cover photo seeded, so this is the only real Image on screen —
      // proves it's specifically the gallery slot rendering it, not some
      // other photo.
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(1));
      expect(images.single.image, isA<NetworkImage>());
      expect((images.single.image as NetworkImage).url, galleryUrl0);
    });

    testWidgets('Shows the "Fotoğraf Ekle" add tile for every empty gallery slot', (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      // No cover photo and no gallery photos seeded — all 3 gallery slots
      // are empty, and (same as the cover photo's own gradient-fallback
      // test) that means no Image widget anywhere on screen at all.
      expect(find.byType(Image), findsNothing);
      expect(find.text('Fotoğraf Ekle'), findsNWidgets(3));
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNWidgets(3));
    });

    testWidgets(
      'A removed slot stays a real empty gap at its own index — the remaining photos are not shifted to fill it',
      (WidgetTester tester) async {
        // Simulates the real Firestore state right after removing the
        // middle (index 1) photo via removeGalleryPhoto: index 0 and 2
        // still have their own real photos, index 1 is a real null.
        // (removeGalleryPhoto's own Storage-delete call isn't exercised
        // here — there is no fake Storage in this project's test
        // dependencies yet, same gap already documented for the upload
        // flow — this test covers the resulting *display* state, which is
        // what "without shifting others" is actually about.)
        await seedProfile(galleryPhotoUrls: [galleryUrl0, null, galleryUrl2]);
        await pumpScreen(tester);

        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        expect(images, hasLength(2));
        expect((images[0].image as NetworkImage).url, galleryUrl0);
        expect((images[1].image as NetworkImage).url, galleryUrl2);

        // Positional proof, not just presence: the empty slot's "Fotoğraf
        // Ekle" tile sits strictly BETWEEN the two real photos left to
        // right — if removal had instead shifted the photos together, the
        // empty tile would be pushed to the rightmost slot instead.
        final firstPhotoX = tester
            .getCenter(
              find.byWidgetPredicate(
                (widget) => widget is Image && widget.image is NetworkImage && (widget.image as NetworkImage).url == galleryUrl0,
              ),
            )
            .dx;
        final emptyTileX = tester.getCenter(find.text('Fotoğraf Ekle')).dx;
        final secondPhotoX = tester
            .getCenter(
              find.byWidgetPredicate(
                (widget) => widget is Image && widget.image is NetworkImage && (widget.image as NetworkImage).url == galleryUrl2,
              ),
            )
            .dx;
        expect(firstPhotoX, lessThan(emptyTileX));
        expect(emptyTileX, lessThan(secondPhotoX));
      },
    );
  });

  group('İşletme Hakkında', () {
    testWidgets('Renders the real template sentence for the seeded profile', (WidgetTester tester) async {
      await seedProfile(hizmetler: ['Lastik Değişimi', 'Balans Ayarı']);
      await pumpScreen(tester);

      expect(find.text('İşletme Hakkında'), findsOneWidget);
      expect(
        find.text(
          "Test Usta İşletmesi, Konya'da hizmet veren bir özel servistir. "
          'Lastik Değişimi ve Balans Ayarı hizmetleri sunmaktadır.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('The sentence genuinely changes for a different profile (different name/location/services)', (
      WidgetTester tester,
    ) async {
      await firestoreInstance.collection('mechanicAccounts').doc(uid).set({
        'businessId': businessId,
        'name': 'Öztürk Elektrik',
        'email': 'usta@example.com',
        'address': 'Beyhekim Mah. Akücüler Sok. No:11, İstanbul',
        'hizmetler': ['Akü Değişimi', 'Far Ayarı'],
      });
      await pumpScreen(tester);

      expect(
        find.text("Öztürk Elektrik, İstanbul'da hizmet veren bir özel servistir. Akü Değişimi ve Far Ayarı hizmetleri sunmaktadır."),
        findsOneWidget,
      );
      // Not a stale/fixed sentence from the other test's profile.
      expect(find.textContaining('Test Usta İşletmesi'), findsNothing);
      expect(find.textContaining('Konya'), findsNothing);
    });

    testWidgets('Still renders (with the location clause gracefully omitted) when there is no real address', (
      WidgetTester tester,
    ) async {
      await firestoreInstance.collection('mechanicAccounts').doc(uid).set({
        'businessId': businessId,
        'name': 'Yeni Usta',
        'email': 'usta@example.com',
      });
      await pumpScreen(tester);

      expect(find.text('Yeni Usta, hizmet veren bir özel servistir.'), findsOneWidget);
    });
  });

  group('businessAboutText (unit)', () {
    test('Includes the real city (parsed from the address) and a natural join of real hizmetler', () {
      final text = businessAboutText(
        businessName: 'Hızlı Lastikçi',
        address: 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
        hizmetler: const ['Lastik Değişimi', 'Balans Ayarı'],
      );
      expect(
        text,
        "Hızlı Lastikçi, Konya'da hizmet veren bir özel servistir. Lastik Değişimi ve Balans Ayarı hizmetleri sunmaktadır.",
      );
    });

    test('Omits the location clause gracefully (no dangling "da) when there is no real address', () {
      final text = businessAboutText(businessName: 'Test Usta', address: null, hizmetler: const []);
      expect(text, 'Test Usta, hizmet veren bir özel servistir.');
    });

    test('Omits the second sentence entirely when hizmetler is empty', () {
      final text = businessAboutText(businessName: 'Test Usta', address: 'Merkez, İstanbul', hizmetler: const []);
      expect(text, "Test Usta, İstanbul'da hizmet veren bir özel servistir.");
    });

    test('Two different real profiles produce genuinely different sentences, not a fixed template output', () {
      final a = businessAboutText(businessName: 'Hızlı Lastikçi', address: 'Konya', hizmetler: const ['Lastik Değişimi']);
      final b = businessAboutText(
        businessName: 'Öztürk Elektrik',
        address: 'İstanbul',
        hizmetler: const ['Akü', 'Far Ayarı', 'Kablo Tesisatı'],
      );

      expect(a, isNot(equals(b)));
      expect(a, contains('Hızlı Lastikçi'));
      expect(a, contains('Konya'));
      expect(b, contains('Öztürk Elektrik'));
      expect(b, contains('İstanbul'));
      // 3+ items join with commas between all but the last two, "ve"
      // between the last two — real natural-list phrasing, not a flat join.
      expect(b, contains('Akü, Far Ayarı ve Kablo Tesisatı'));
    });
  });

  group('Çıkış Yap (sign out)', () {
    testWidgets('Button is present on the profile screen', (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);
      await tester.scrollUntilVisible(find.text('Çıkış Yap'), 300);

      expect(find.text('Çıkış Yap'), findsOneWidget);
    });

    testWidgets('Tapping it shows a real confirmation dialog before signing out', (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);
      await tester.scrollUntilVisible(find.text('Çıkış Yap'), 300);

      await tester.tap(find.text('Çıkış Yap'));
      await tester.pumpAndSettle();

      expect(find.text('Çıkış yapmak istediğinize emin misiniz?'), findsOneWidget);
      // Not signed out yet — only the confirmation dialog is up so far.
      expect(firebaseAuthInstance.currentUser, isNotNull);
    });

    testWidgets('Confirming (Evet) signs out and navigates to MechanicLoginPage, clearing the stack', (
      WidgetTester tester,
    ) async {
      await seedProfile();
      await pumpScreen(tester);
      await tester.scrollUntilVisible(find.text('Çıkış Yap'), 300);

      await tester.tap(find.text('Çıkış Yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet'));
      await tester.pumpAndSettle();

      expect(firebaseAuthInstance.currentUser, isNull);
      expect(find.byType(MechanicLoginPage), findsOneWidget);
      expect(find.byType(MechanicProfileScreen), findsNothing);

      // The stack was genuinely cleared, not just pushed on top — there is
      // nothing left to pop back into a signed-out session with.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('Cancelling (Hayır) neither signs out nor navigates away', (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);
      await tester.scrollUntilVisible(find.text('Çıkış Yap'), 300);

      await tester.tap(find.text('Çıkış Yap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hayır'));
      await tester.pumpAndSettle();

      expect(firebaseAuthInstance.currentUser, isNotNull);
      expect(find.byType(MechanicProfileScreen), findsOneWidget);
      expect(find.byType(MechanicLoginPage), findsNothing);
      expect(find.text('Çıkış yapmak istediğinize emin misiniz?'), findsNothing);
    });
  });
}
