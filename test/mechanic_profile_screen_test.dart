import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/profile/mechanic_profile_screen.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

/// MechanicProfileScreen shows a mechanic their own completed-job and
/// repeat-customer counts as an always-visible, unthresholded motivational
/// signal — deliberately different from VerifiedJobsBadge (shown to
/// customers on MechanicDetailPage, hidden below its own minThreshold: 10)
/// and from ServiceCenterCard/MechanicDetailPage's own hide-when-zero
/// repeat-customer chip, neither of which this file touches.
void main() {
  const uid = 'test-mechanic-uid';
  const businessId = 'test-usta-isletmesi';

  setUp(() {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: uid, email: 'usta@example.com', isEmailVerified: true),
      signedIn: true,
    );
    firestoreInstance = FakeFirebaseFirestore();
  });

  Future<void> seedProfile({int? repeatCustomerCount}) {
    return firestoreInstance.collection('mechanicAccounts').doc(uid).set({
      'businessId': businessId,
      'name': 'Test Usta İşletmesi',
      'email': 'usta@example.com',
      'phone': '5551234567',
      'address': 'Test Sanayi Sitesi, Konya',
      'isVerified': true,
      if (repeatCustomerCount != null) 'repeatCustomerCount': repeatCustomerCount,
    });
  }

  Future<void> seedCompletedAppointment(String id) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'işletme_kimliği': businessId,
      'tamamlanmaDurumu': 'dogrulanmis_tamamlandi',
    });
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MechanicProfileScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Shows both stats as 0, not hidden, when there is no completed-job or repeat-customer data yet',
    (WidgetTester tester) async {
      await seedProfile();
      await pumpScreen(tester);

      expect(find.text('Tamamlanan İş: 0'), findsOneWidget);
      expect(find.text('Tekrar Eden Müşteri: 0'), findsOneWidget);
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

    expect(find.text('Tamamlanan İş: 3'), findsOneWidget);
    expect(find.text('Tekrar Eden Müşteri: 5'), findsOneWidget);
  });
}
