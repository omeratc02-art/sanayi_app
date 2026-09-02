import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/notifications/notifications_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

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

  testWidgets('A notification from a prior session (Firestore only, never submitted this session) shows up', (
    WidgetTester tester,
  ) async {
    // Seeded directly into randevular — never went through
    // AppointmentRequestStore.submit(), so the store's in-memory _requests
    // list stays empty for this session. müşteri_kimliği matches the uid
    // MockFirebaseAuth signs the customer in as above. durum: 'beklemede'
    // with a real (non-'00:00') randevu_zamani is exactly the shape a
    // mechanic's "Başka Saat Öner" produces — see MechanicAppointmentsScreen
    // — so this simulates a proposal made in an earlier session/on another
    // device, not one this app session
    // created or is tracking a live listener for.
    await firestoreInstance.collection('randevular').doc('prior-session-appt').set({
      'randevu_kimliği': 'prior-session-appt',
      'müşteri_kimliği': 'test-user-id',
      'müşteriAdı': 'Test Müşteri',
      'müşteriTelefonu': '5551234567',
      'araçModeli': 'Renault Clio',
      'plaka': '34ABC123',
      'hizmetTürü': 'Lastik & Balans',
      'randevuTarihi': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
      'randevu_zamani': '14:30',
      'tahminiSüreDakika': 60,
      'müşteriNotu': 'Tercih edilen saat aralığı: 13:00 – 15:00',
      'durum': 'beklemede',
      'oluşturulma_tarihi': Timestamp.fromDate(DateTime.now()),
      'mesafe': '',
      // Matches mechanicChatId('Hızlı Lastikçi') so the notification
      // resolves a real display name instead of falling back to the slug.
      'işletme_kimliği': 'hizli-lastikci',
      'kvkkOnaylandi': true,
      'tamamlanmaDurumu': 'beklemede',
    });

    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('Bildiriminiz yok'), findsNothing);
    expect(find.text('Hızlı Lastikçi'), findsOneWidget);
    expect(find.text('Size yeni bir randevu saati önerdi.'), findsOneWidget);
    expect(find.text('Kabul Et'), findsOneWidget);
  });

  testWidgets('A prior-session decline (Firestore only) also shows up', (WidgetTester tester) async {
    await firestoreInstance.collection('randevular').doc('prior-session-decline').set({
      'randevu_kimliği': 'prior-session-decline',
      'müşteri_kimliği': 'test-user-id',
      'müşteriAdı': 'Test Müşteri',
      'müşteriTelefonu': '5551234567',
      'araçModeli': 'Renault Clio',
      'plaka': '34ABC123',
      'hizmetTürü': 'Fren & Süspansiyon',
      'randevuTarihi': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
      'randevu_zamani': '00:00',
      'tahminiSüreDakika': 60,
      'müşteriNotu': 'Tercih edilen saat aralığı: 10:00 – 12:00',
      'durum': 'reddedildi',
      'oluşturulma_tarihi': Timestamp.fromDate(DateTime.now()),
      'mesafe': '',
      // Matches mechanicChatId('Master Fren Sistemleri').
      'işletme_kimliği': 'master-fren-sistemleri',
      'kvkkOnaylandi': true,
      'tamamlanmaDurumu': 'beklemede',
    });

    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Master Fren Sistemleri'), findsOneWidget);
    expect(find.text('Usta randevu talebinizi reddetti.'), findsOneWidget);
  });
}
