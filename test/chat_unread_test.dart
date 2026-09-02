import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/data/appointment_request_store.dart';
import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/appointments/customer_conversation_list_page.dart';
import 'package:sanayi_app/screens/appointments/customer_conversation_page.dart';
import 'package:sanayi_app/screens/notifications/notifications_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';
import 'package:sanayi_app/widgets/home/greeting_bar.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

void main() {
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

  /// Seeds a `chats/{chatId}` doc plus one unread message from the
  /// mechanic and, unless [includeOwnMessage] is false, one *already-read*
  /// message the customer themselves sent (senderId == 'test-user-id') —
  /// present specifically to catch the old bug, where the unread count was
  /// compared against a hardcoded 'customer-demo' instead of the real
  /// signed-in id, which would have wrongly counted the customer's own
  /// message as "unread from someone else".
  Future<void> seedChatWithUnreadMechanicMessage({bool includeOwnMessage = true}) async {
    await firestoreInstance.collection('chats').doc('hizli-lastikci-chat').set({
      'mechanicName': 'Hızlı Lastikçi',
      'lastMessageAt': Timestamp.now(),
      'lastMessageText': 'Aracınız hazır, ne zaman gelebilirsiniz?',
      'lastMessageSenderId': 'mechanic-hizli-lastikci',
      'lastMessageSenderRole': 'mechanic',
    });
    final messages = firestoreInstance.collection('chats').doc('hizli-lastikci-chat').collection('messages');
    if (includeOwnMessage) {
      await messages.add({
        'senderId': 'test-user-id',
        'text': 'Merhaba, lastik değişimi için randevu almıştım.',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 10))),
        'isRead': true,
      });
    }
    await messages.add({
      'senderId': 'mechanic-hizli-lastikci',
      'text': 'Aracınız hazır, ne zaman gelebilirsiniz?',
      'createdAt': Timestamp.now(),
      'isRead': false,
    });
  }

  testWidgets('Mesajlar unread badge is computed against the real customer id, not customer-demo', (
    WidgetTester tester,
  ) async {
    await seedChatWithUnreadMechanicMessage();

    await pumpApp(tester);
    await tester.tap(find.text('Mesajlar'));
    await tester.pumpAndSettle();

    // Exactly 1 (the mechanic's message) — the old 'customer-demo' bug
    // would have also wrongly counted the customer's own already-read
    // message above, showing 2 instead. Scoped to the list page itself
    // since the bottom-nav Mesajlar badge also legitimately shows '1'
    // outside this subtree.
    final listScope = find.byType(CustomerConversationListPage);
    expect(find.descendant(of: listScope, matching: find.text('1')), findsOneWidget);
    expect(find.descendant(of: listScope, matching: find.text('2')), findsNothing);
  });

  testWidgets('Opening a conversation marks messages read and the badge count drops', (WidgetTester tester) async {
    await seedChatWithUnreadMechanicMessage(includeOwnMessage: false);

    await pumpApp(tester);
    await tester.tap(find.text('Mesajlar'));
    await tester.pumpAndSettle();

    final listScope = find.byType(CustomerConversationListPage);
    expect(find.descendant(of: listScope, matching: find.text('1')), findsOneWidget);

    await tester.tap(find.text('Hızlı Lastikçi'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerConversationPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.descendant(of: listScope, matching: find.text('1')), findsNothing);
  });

  testWidgets('NotificationsPage shows a message-type card for an unread conversation seeded in Firestore', (
    WidgetTester tester,
  ) async {
    await seedChatWithUnreadMechanicMessage(includeOwnMessage: false);

    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('Hızlı Lastikçi'), findsOneWidget);
    expect(find.text('Aracınız hazır, ne zaman gelebilirsiniz?'), findsOneWidget);
  });

  testWidgets('The bell badge total combines appointment and message notification counts', (
    WidgetTester tester,
  ) async {
    await seedChatWithUnreadMechanicMessage(includeOwnMessage: false);
    await pumpApp(tester);

    // actionNeededCount (the appointment half of the bell total) is
    // deliberately session-local — same scope as the bottom-nav
    // Randevularım badge it mirrors — so this drives a real submission
    // through AppointmentRequestStore itself (a real Firestore write +
    // a real session-local request, exactly like the booking flow does),
    // then simulates the mechanic proposing a time by updating that same
    // randevular document directly. The store's own live per-document
    // listener (started by submit()) picks that up and flips the local
    // request to providerProposed, the same way it would for a real
    // "Başka Saat Öner" from the mechanic side.
    final request = await AppointmentRequestStore.instance.submit(
      mechanicName: 'Master Fren Sistemleri',
      date: DateTime.now().add(const Duration(days: 2)),
      preferredWindowLabel: '13:00 – 15:00',
      serviceLabel: 'Fren Sistemi',
      vehicleLabel: 'Renault Clio',
      customerName: 'Test Müşteri',
      customerPhone: '5551234567',
      kvkkAccepted: true,
    );
    await firestoreInstance.collection('randevular').doc(request.id).update({'randevu_zamani': '14:30'});
    await tester.pumpAndSettle();

    // 1 unread conversation + 1 provider-proposed appointment = 2, shown
    // on the bell's Badge label (GreetingBar, on the Home tab).
    final greetingBarScope = find.byType(GreetingBar);
    expect(find.descendant(of: greetingBarScope, matching: find.text('2')), findsOneWidget);
  });
}
