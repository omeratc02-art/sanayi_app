import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/appointments/customer_conversation_page.dart';
import 'package:sanayi_app/screens/booking/appointment_request_page.dart';
import 'package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
  const chatId = 'hizli-lastikci-chat';

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: 'test-user-id', email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
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

  Future<void> seedChatAndOpenConversation(WidgetTester tester) async {
    await firestoreInstance.collection('chats').doc(chatId).set({
      'mechanicName': 'Hızlı Lastikçi',
      'lastMessageAt': Timestamp.now(),
      'lastMessageText': 'Merhaba, aracınız için ne zaman uygunsunuz?',
      'lastMessageSenderId': 'mechanic-hizli-lastikci',
      'lastMessageSenderRole': 'mechanic',
    });
    await firestoreInstance.collection('chats').doc(chatId).collection('messages').add({
      'senderId': 'mechanic-hizli-lastikci',
      'text': 'Merhaba, aracınız için ne zaman uygunsunuz?',
      'createdAt': Timestamp.now(),
      'isRead': true,
    });

    await pumpApp(tester);
    await tester.tap(find.text('Mesajlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızlı Lastikçi'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerConversationPage), findsOneWidget);
  }

  Future<void> seedMechanicAccount() {
    return firestoreInstance.collection('mechanicAccounts').add({
      'name': 'Hızlı Lastikçi',
      'businessId': chatId,
      'specialty': 'Lastik & Balans',
      'hizmetTürü': 'tamir',
      'hizmetler': ['Lastik & Jant'],
      'rating': 4.7,
      'reviewCount': 96,
      'priceMin': 200,
      'priceMax': 380,
      'isVerified': true,
      'repeatCustomerRate': 84,
      'workingHours': 'Her gün: 09:00 - 20:00',
      'phone': '0212 667 45 09',
      'address': 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
    });
  }

  testWidgets('Randevu Al in chat fetches the real mechanic and opens the booking page', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedChatAndOpenConversation(tester);

    await tester.tap(find.text('Randevu Al'));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentRequestPage), findsOneWidget);
    // serviceLabel falls back to mechanic.specialtyLabel, same as
    // MechanicDetailPage's own call site — shown in the summary card.
    expect(find.text('Lastik & Balans'), findsWidgets);
  });

  testWidgets('Randevu Al shows an error and does not navigate when no matching business exists', (
    WidgetTester tester,
  ) async {
    // Deliberately no mechanicAccounts doc with businessId == chatId.
    await seedChatAndOpenConversation(tester);

    await tester.tap(find.text('Randevu Al'));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentRequestPage), findsNothing);
    expect(find.text('Usta bilgileri alınamadı. Lütfen tekrar deneyin.'), findsOneWidget);
  });

  testWidgets('Tapping the mechanic name in the AppBar opens the real MechanicDetailPage', (
    WidgetTester tester,
  ) async {
    await seedMechanicAccount();
    await seedChatAndOpenConversation(tester);

    await tester.tap(find.text('Hızlı Lastikçi').last);
    await tester.pumpAndSettle();

    expect(find.byType(MechanicDetailPage), findsOneWidget);
  });

  testWidgets('Doğrulanmış Usta badge shows for a real verified mechanic', (WidgetTester tester) async {
    await seedMechanicAccount(); // isVerified: true
    await seedChatAndOpenConversation(tester);

    expect(find.text('Doğrulanmış Usta'), findsOneWidget);
  });

  // Covers both "no matching business" and, structurally, the loading
  // state before _resolveMechanic() completes: build() computes
  // isVerified as `_resolvedMechanic?.isVerified ?? false`, so a null
  // _resolvedMechanic — whether because the fetch hasn't resolved yet or
  // because fetchByBusinessId genuinely found nothing — renders identically
  // (badge hidden). There's no separate "loading" branch that could show a
  // speculative "Doğrulanmış Usta" before the real value is known; the two
  // states share one code path, so this single assertion covers both.
  // (A literal timing-race pump() between mount and resolution isn't
  // reliably observable in this harness — fake_cloud_firestore resolves via
  // microtasks fast enough that even a single extra pump() already shows
  // the settled result.)
  testWidgets('Badge is hidden when no matching mechanicAccounts document exists', (WidgetTester tester) async {
    // No seedMechanicAccount() — fetchByBusinessId returns null.
    await seedChatAndOpenConversation(tester);

    expect(find.text('Doğrulanmış Usta'), findsNothing);
  });
}
