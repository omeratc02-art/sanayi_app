import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/screens/appointments/customer_conversation_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

void main() {
  group('quickReplyQuestions', () {
    test('phrases the price question around the real service name when context is given', () {
      final questions = quickReplyQuestions('10.000–20.000 km Bakımı');

      expect(questions.first, '10.000–20.000 km Bakımı için fiyatınız nedir?');
      expect(questions, isNot(contains('Fiyat bilgisi alabilir miyim?')));
      // Count is unaffected by whether context exists.
      expect(questions.length, 4);
    });

    test('falls back to the generic set when there is no service context', () {
      final questions = quickReplyQuestions(null);

      expect(questions, [
        'Fiyat bilgisi alabilir miyim?',
        'Bugün müsait misiniz?',
        'İşlem ne kadar sürer?',
        'Randevu almadan gelebilir miyim?',
      ]);
    });

    test('blank/whitespace-only context is treated the same as no context', () {
      expect(quickReplyQuestions('   ').first, 'Fiyat bilgisi alabilir miyim?');
    });
  });

  group('CustomerConversationPage quick-reply chips', () {
    const chatId = 'hizli-lastikci-chat';

    setUp(() {
      firebaseAuthInstance = MockFirebaseAuth(signedIn: false);
      firestoreInstance = FakeFirebaseFirestore();
    });

    Future<void> pumpConversation(WidgetTester tester, {String? serviceContext}) async {
      // A realistic phone width — the chip row is horizontally scrollable
      // by design (see _QuickReplyChips), so tests that tap a later chip
      // need to scroll it into view first, same as a real user would.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerConversationPage(
            chatId: chatId,
            mechanicName: 'Hızlı Lastikçi',
            serviceContext: serviceContext,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the service-specific chip and hides the generic price chip when context is given', (
      WidgetTester tester,
    ) async {
      await pumpConversation(tester, serviceContext: '10.000–20.000 km Bakımı');

      expect(find.text('10.000–20.000 km Bakımı için fiyatınız nedir?'), findsOneWidget);
      expect(find.text('Fiyat bilgisi alabilir miyim?'), findsNothing);
      // The rest of the generic set is still present alongside it.
      expect(find.text('Bugün müsait misiniz?'), findsOneWidget);
      expect(find.text('İşlem ne kadar sürer?'), findsOneWidget);
      expect(find.text('Randevu almadan gelebilir miyim?'), findsOneWidget);
    });

    testWidgets('shows the full generic set when no service context exists', (WidgetTester tester) async {
      await pumpConversation(tester);

      expect(find.text('Fiyat bilgisi alabilir miyim?'), findsOneWidget);
      expect(find.text('Bugün müsait misiniz?'), findsOneWidget);
      expect(find.text('İşlem ne kadar sürer?'), findsOneWidget);
      expect(find.text('Randevu almadan gelebilir miyim?'), findsOneWidget);
    });

    testWidgets('tapping a chip fills the reply field but does not send a message', (WidgetTester tester) async {
      await pumpConversation(tester);

      await tester.ensureVisible(find.text('Bugün müsait misiniz?'));
      await tester.tap(find.text('Bugün müsait misiniz?'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Bugün müsait misiniz?');

      final messages = await firestoreInstance.collection('chats').doc(chatId).collection('messages').get();
      expect(messages.docs, isEmpty);
    });

    testWidgets('a filled chip can still be edited and sent through the normal send flow', (
      WidgetTester tester,
    ) async {
      await pumpConversation(tester);

      await tester.ensureVisible(find.text('İşlem ne kadar sürer?'));
      await tester.tap(find.text('İşlem ne kadar sürer?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'İşlem ne kadar sürer? (lastik değişimi için)');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final messages = await firestoreInstance.collection('chats').doc(chatId).collection('messages').get();
      expect(messages.docs, hasLength(1));
      expect(messages.docs.first.data()['text'], 'İşlem ne kadar sürer? (lastik değişimi için)');
    });
  });
}
