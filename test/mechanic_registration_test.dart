import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/mechanic/home/mechanic_home_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
  setUp(() {
    // signedIn: false — createUserWithEmailAndPassword below is what
    // actually signs the mocked user in, same as a real registration.
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-mechanic-uid', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  Future<void> openMechanicRegisterDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SanayiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Usta Modu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıt Ol'));
    await tester.pumpAndSettle();
  }

  Future<void> submitAndWaitForNavigation(WidgetTester tester) async {
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Kayıt Ol')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Registering as Araç Tamiri picks a real catalog business and writes hizmetTürü: tamir', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    // 'tamir' is the default selection — the dropdown is already showing.
    await tester.tap(find.text('Usta / İşletme Adı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızlı Lastikçi').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'tamirci@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await submitAndWaitForNavigation(tester);

    expect(find.byType(MechanicHomePage), findsOneWidget);

    final snapshot = await firestoreInstance.collection('mechanicAccounts').get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();
    expect(data['name'], 'Hızlı Lastikçi');
    expect(data['hizmetTürü'], 'tamir');
    expect(data['email'], 'tamirci@example.com');
    // Bootstrapped from the picked catalog entry, same as before hizmetTürü
    // selection existed.
    expect(data['phone'], isNotNull);
    expect(data['specialty'], isNotNull);
  });

  testWidgets('Registering as Ekspertiz uses a typed business name (no MockData catalog) and writes hizmetTürü: ekspertiz', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    await tester.tap(find.text('Ekspertiz').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'İşletme Adı'), 'Konya Ekspertiz Merkezi');
    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'ekspertiz@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await submitAndWaitForNavigation(tester);

    expect(find.byType(MechanicHomePage), findsOneWidget);

    final snapshot = await firestoreInstance.collection('mechanicAccounts').get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();
    expect(data['name'], 'Konya Ekspertiz Merkezi');
    expect(data['hizmetTürü'], 'ekspertiz');
    expect(data['email'], 'ekspertiz@example.com');
    // No MockData catalog entry exists for a new Ekspertiz business — these
    // fields must not be fabricated, unlike the tamir path above.
    expect(data.containsKey('phone'), isFalse);
    expect(data.containsKey('specialty'), isFalse);
    expect(data.containsKey('hizmetler'), isFalse);
  });

  testWidgets('Submitting without a business name shows an error and does not write to Firestore', (
    WidgetTester tester,
  ) async {
    await openMechanicRegisterDialog(tester);

    await tester.tap(find.text('Ekspertiz').first);
    await tester.pumpAndSettle();
    // Deliberately leave "İşletme Adı" empty.
    await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'ekspertiz@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Kayıt Ol')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lütfen usta/işletme adı, e-posta ve şifrenizi girin.'), findsOneWidget);
    expect((await firestoreInstance.collection('mechanicAccounts').get()).docs, isEmpty);
  });

  group('claiming a script-uploaded business', () {
    // Mirrors exactly what scripts/mechanic_upload/upload_mechanics.js
    // (post this session's fixes) plus add_claimed_by_uid.js actually
    // write: a real business document with no owning Auth account yet,
    // businessId already the correct name-slug, and claimedByUid present
    // but null — the one signal that marks it as claimable.
    Future<void> seedClaimableBusiness({
      required String docId,
      required String name,
      required String businessId,
      String hizmetTuru = 'tamir',
    }) {
      return firestoreInstance.collection('mechanicAccounts').doc(docId).set({
        'businessId': businessId,
        'işletme_kimliği': businessId,
        'name': name,
        'phone': '0555 111 22 33',
        'hizmetTürü': hizmetTuru,
        'hizmetler': ['Motor'],
        'address': 'Test Sanayi Sitesi, Konya',
        'workingHours': 'Pzt-Cmt 08:00-19:00, Pzr Kapalı',
        'acilDurumHizmeti': null,
        'gmail': '',
        'durum': 'onaylandi',
        'isVerified': true, // set by earlier admin-screen testing, same as TOYOPEL in production
        'claimedByUid': null,
      });
    }

    testWidgets(
      'Selecting a claimable business creates a new pending doc for the Auth uid and archives the old one',
      (WidgetTester tester) async {
        await seedClaimableBusiness(
          docId: 'claim-test-doc-id',
          name: 'Claim Test Ustası',
          businessId: 'claim-test-ustasi',
        );
        // A normal registered mechanic (no claimedByUid field at all) —
        // proves the claimable query doesn't accidentally sweep this up too.
        await firestoreInstance.collection('mechanicAccounts').doc('already-registered-uid').set({
          'businessId': 'zaten-kayitli-usta',
          'name': 'Zaten Kayıtlı Usta',
          'hizmetTürü': 'tamir',
          'email': 'kayitli@example.com',
          'role': 'mechanic',
        });

        await openMechanicRegisterDialog(tester);

        await tester.tap(find.text('Usta / İşletme Adı'));
        await tester.pumpAndSettle();
        // Only the claimable entry should be tappable under this name — the
        // already-registered business above is never offered.
        expect(find.text('Zaten Kayıtlı Usta'), findsNothing);
        await tester.tap(find.text('Claim Test Ustası').last);
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'rifat@example.com');
        await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
        await submitAndWaitForNavigation(tester);

        expect(find.byType(MechanicHomePage), findsOneWidget);

        // The new doc's id is a fresh UUID minted by
        // createUserWithEmailAndPassword (firebase_auth_mocks), not the
        // configured MockUser.uid — found by content, not a fixed id.
        final allDocs = await firestoreInstance.collection('mechanicAccounts').get();
        final newDocs = allDocs.docs.where((d) => d.id != 'claim-test-doc-id' && d.id != 'already-registered-uid');
        expect(newDocs, hasLength(1));
        final newDoc = newDocs.single;
        final newData = newDoc.data();
        expect(newData['name'], 'Claim Test Ustası');
        expect(newData['businessId'], 'claim-test-ustasi');
        expect(newData['işletme_kimliği'], 'claim-test-ustasi');
        expect(newData['phone'], '0555 111 22 33');
        expect(newData['address'], 'Test Sanayi Sitesi, Konya');
        expect(newData['hizmetTürü'], 'tamir');
        expect(newData['hizmetler'], ['Motor']);
        expect(newData['workingHours'], 'Pzt-Cmt 08:00-19:00, Pzr Kapalı');
        expect(newData['email'], 'rifat@example.com');
        // The core safeguard: never copied from the old doc's isVerified:
        // true — every claim starts unverified pending real admin
        // re-approval.
        expect(newData['isVerified'], isFalse);
        expect(newData.containsKey('claimedByUid'), isFalse);

        final oldDoc = await firestoreInstance.collection('mechanicAccounts').doc('claim-test-doc-id').get();
        expect(oldDoc.data()!['claimedByUid'], newDoc.id);
        expect(oldDoc.data()!['archived'], isTrue);

        // Untouched — never offered, never claimed.
        final untouched = await firestoreInstance.collection('mechanicAccounts').doc('already-registered-uid').get();
        expect(untouched.data()!.containsKey('claimedByUid'), isFalse);
        expect(untouched.data()!.containsKey('archived'), isFalse);
      },
    );

    testWidgets('Claimable businesses show up for Ekspertiz too, not just Araç Tamiri', (WidgetTester tester) async {
      await seedClaimableBusiness(
        docId: 'claim-test-eksp-id',
        name: 'Claim Test Ekspertiz',
        businessId: 'claim-test-ekspertiz',
        hizmetTuru: 'ekspertiz',
      );

      await openMechanicRegisterDialog(tester);
      await tester.tap(find.text('Ekspertiz').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usta / İşletme Adı'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claim Test Ekspertiz').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'eksperttest@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
      await submitAndWaitForNavigation(tester);

      expect(find.byType(MechanicHomePage), findsOneWidget);
      final allDocs = await firestoreInstance.collection('mechanicAccounts').get();
      final newDocs = allDocs.docs.where((d) => d.id != 'claim-test-eksp-id');
      expect(newDocs, hasLength(1));
      final newData = newDocs.single.data();
      expect(newData['name'], 'Claim Test Ekspertiz');
      expect(newData['hizmetTürü'], 'ekspertiz');
      expect(newData['isVerified'], isFalse);
    });

    testWidgets(
      'Claiming aborts with an error and writes nothing when live chat activity already exists for the business',
      (WidgetTester tester) async {
        await seedClaimableBusiness(
          docId: 'claim-test-conflict-id',
          name: 'Claim Conflict Ustası',
          businessId: 'claim-conflict-ustasi',
        );
        // Real activity already exists under the slug this claim would
        // resolve to — the exact scenario _claimBusiness must refuse, not
        // silently proceed past.
        await firestoreInstance.collection('chats').doc('claim-conflict-ustasi').set({
          'mechanicName': 'Claim Conflict Ustası',
          'lastMessageAt': Timestamp.now(),
        });

        await openMechanicRegisterDialog(tester);
        await tester.tap(find.text('Usta / İşletme Adı'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Claim Conflict Ustası').last);
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'conflict@example.com');
        await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
        await submitAndWaitForNavigation(tester);

        // Never reaches MechanicHomePage — the claim failed, so onSuccess
        // never ran and the dialog stayed open with an error.
        expect(find.byType(MechanicHomePage), findsNothing);
        expect(find.textContaining('zaten bir mesajlaşma kaydı'), findsOneWidget);

        // No new document at all — the seeded claimable one is still the
        // only mechanicAccounts document that exists.
        final allDocs = await firestoreInstance.collection('mechanicAccounts').get();
        expect(allDocs.docs, hasLength(1));

        final oldDoc = await firestoreInstance.collection('mechanicAccounts').doc('claim-test-conflict-id').get();
        expect(oldDoc.data()!['claimedByUid'], isNull);
        expect(oldDoc.data()!.containsKey('archived'), isFalse);
      },
    );

    testWidgets(
      'The double-claim race: if the business is claimed by someone else between selecting it and submitting, '
      'the fresh in-transaction re-check catches it — a distinct error, and nothing overwritten',
      (WidgetTester tester) async {
        // FakeFirebaseFirestore has no real concurrency to race two actual
        // simultaneous transactions against each other — but the exact
        // property that matters is testable directly: does _claimBusiness's
        // transaction trust the option snapshot captured when the claimable
        // list was fetched, or does it genuinely re-read fresh right before
        // writing? Simulating "someone else's claim already landed" as a
        // real Firestore write, injected between selecting the option in
        // the dialog and submitting it, exercises exactly that fresh-read
        // path — the bug this whole fix closes.
        await seedClaimableBusiness(
          docId: 'claim-test-race-id',
          name: 'Claim Race Ustası',
          businessId: 'claim-race-ustasi',
        );

        await openMechanicRegisterDialog(tester);
        await tester.tap(find.text('Usta / İşletme Adı'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Claim Race Ustası').last);
        await tester.pumpAndSettle();

        // A different real mechanic's claim lands first, in the window
        // between this dialog fetching its (now-stale) claimable list and
        // this attempt actually submitting.
        await firestoreInstance.collection('mechanicAccounts').doc('claim-test-race-id').update({
          'claimedByUid': 'first-claimant-uid',
          'archived': true,
        });

        await tester.enterText(find.widgetWithText(TextField, 'E-posta'), 'late-claimant@example.com');
        await tester.enterText(find.widgetWithText(TextField, 'Şifre'), 'password123');
        await submitAndWaitForNavigation(tester);

        // Never reaches MechanicHomePage — the claim failed.
        expect(find.byType(MechanicHomePage), findsNothing);
        // The new, distinct race message — not the chat/appointment-activity
        // wording, which would be actively misleading here.
        expect(find.textContaining('az önce başka biri tarafından talep edildi'), findsOneWidget);
        expect(find.textContaining('zaten bir mesajlaşma kaydı'), findsNothing);
        expect(find.textContaining('zaten randevu kayıtları'), findsNothing);

        // No second mechanicAccounts document was created for the late
        // claimant — the only two documents that exist are the original
        // claimable one (now correctly reflecting the first claimant) and
        // nothing else.
        final allDocs = await firestoreInstance.collection('mechanicAccounts').get();
        expect(allDocs.docs, hasLength(1));

        // The first claimant's own claim was never overwritten by the
        // second, losing attempt.
        final oldDoc = await firestoreInstance.collection('mechanicAccounts').doc('claim-test-race-id').get();
        expect(oldDoc.data()!['claimedByUid'], 'first-claimant-uid');
        expect(oldDoc.data()!['archived'], isTrue);
      },
    );
  });
}
