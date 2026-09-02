import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/home/all_vehicles_page.dart';
import 'package:sanayi_app/screens/home/vehicle_repair_category_page.dart';
import 'package:sanayi_app/utils/firebase_instances.dart';

import 'test_utils/fake_google_sign_in_platform.dart';

/// "Araçlarım" derived from real per-customer appointment history — no
/// mock vehicle list, no separate vehicle store. See MyVehiclesSection's
/// own doc comment for the reasoning.
void main() {
  const customerUid = 'test-customer-uid';

  setUp(() {
    firestoreInstance = FakeFirebaseFirestore();
    GoogleSignInPlatform.instance = FakeGoogleSignInPlatform();
  });

  Future<void> seedAppointment({
    required String id,
    required String vehicleModel,
    required String plate,
    required DateTime createdAt,
  }) {
    return firestoreInstance.collection('randevular').doc(id).set({
      'randevu_kimliği': id,
      'müşteri_kimliği': customerUid,
      'müşteriAdı': 'Test Müşteri',
      'müşteriTelefonu': '5551234567',
      'araçModeli': vehicleModel,
      'plaka': plate,
      'hizmetTürü': 'Lastik Değişimi',
      'randevuTarihi': Timestamp.fromDate(DateTime.utc(2026, 9, 10, 12)),
      'randevu_zamani': '10:00',
      'tahminiSüreDakika': 60,
      'müşteriNotu': '',
      'durum': 'kabul edildi',
      'oluşturulma_tarihi': Timestamp.fromDate(createdAt),
      'mesafe': '',
      'işletme_kimliği': 'hizli-lastikci',
      'kvkkOnaylandi': true,
      'tamamlanmaDurumu': 'beklemede',
    });
  }

  Future<void> pumpApp(WidgetTester tester) async {
    firebaseAuthInstance = MockFirebaseAuth(
      mockUser: MockUser(uid: customerUid, email: 'test@example.com', isEmailVerified: true),
      signedIn: false,
    );
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

  testWidgets('Araçlarım shows the empty state for a customer with no past appointments', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(
      find.text('Henüz aracınız yok. Randevu aldığınızda araçlarınız burada görünecek.'),
      findsOneWidget,
    );
  });

  testWidgets('Araçlarım derives distinct vehicles from real appointment history, deduplicated', (
    WidgetTester tester,
  ) async {
    await seedAppointment(
      id: 'appt-1',
      vehicleModel: 'Renault Clio 2018',
      plate: '34 ABC 123',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await seedAppointment(
      id: 'appt-2',
      vehicleModel: 'Toyota Corolla 2020',
      plate: '06 XYZ 456',
      createdAt: DateTime.utc(2026, 8, 15),
    );
    // Same vehicle as appt-1, booked again later — must not produce a
    // duplicate row.
    await seedAppointment(
      id: 'appt-3',
      vehicleModel: 'Renault Clio 2018',
      plate: '34 ABC 123',
      createdAt: DateTime.utc(2026, 8, 20),
    );

    await pumpApp(tester);

    expect(find.text('Renault Clio 2018'), findsOneWidget);
    expect(find.text('Toyota Corolla 2020'), findsOneWidget);
    expect(find.text('34 ABC 123'), findsOneWidget);
    expect(find.text('06 XYZ 456'), findsOneWidget);
    expect(
      find.text('Henüz aracınız yok. Randevu aldığınızda araçlarınız burada görünecek.'),
      findsNothing,
    );
    // Only 2 distinct vehicles — nothing more to see, so no "Tümünü Gör".
    expect(find.text('Tümünü Gör'), findsNothing);
  });

  testWidgets('With more than 3 vehicles, the home screen shows only the 3 most recent and "Tümünü Gör"', (
    WidgetTester tester,
  ) async {
    await seedAppointment(
      id: 'appt-1',
      vehicleModel: 'Renault Clio 2018',
      plate: '34 ABC 123',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await seedAppointment(
      id: 'appt-2',
      vehicleModel: 'Toyota Corolla 2020',
      plate: '06 XYZ 456',
      createdAt: DateTime.utc(2026, 8, 5),
    );
    await seedAppointment(
      id: 'appt-3',
      vehicleModel: 'Fiat Egea 2019',
      plate: '35 EGE 123',
      createdAt: DateTime.utc(2026, 8, 10),
    );
    // The 2 most recent — these 2 plus the 3 above make 5 distinct
    // vehicles, so only the most recent 3 (Peugeot, Ford, and Fiat Egea)
    // should show on the home screen; Renault/Toyota are pushed off.
    await seedAppointment(
      id: 'appt-4',
      vehicleModel: 'Peugeot 208 2021',
      plate: '42 PEU 456',
      createdAt: DateTime.utc(2026, 8, 15),
    );
    await seedAppointment(
      id: 'appt-5',
      vehicleModel: 'Ford Focus 2017',
      plate: '16 FOR 789',
      createdAt: DateTime.utc(2026, 8, 20),
    );

    await pumpApp(tester);

    // 3 most recent visible on the home screen.
    expect(find.text('Ford Focus 2017'), findsOneWidget);
    expect(find.text('Peugeot 208 2021'), findsOneWidget);
    expect(find.text('Fiat Egea 2019'), findsOneWidget);
    // The 2 oldest are pushed off the preview.
    expect(find.text('Toyota Corolla 2020'), findsNothing);
    expect(find.text('Renault Clio 2018'), findsNothing);

    expect(find.text('Tümünü Gör'), findsOneWidget);
  });

  testWidgets('"Tümünü Gör" opens AllVehiclesPage with every vehicle, and tapping one there still books', (
    WidgetTester tester,
  ) async {
    await seedAppointment(
      id: 'appt-1',
      vehicleModel: 'Renault Clio 2018',
      plate: '34 ABC 123',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await seedAppointment(
      id: 'appt-2',
      vehicleModel: 'Toyota Corolla 2020',
      plate: '06 XYZ 456',
      createdAt: DateTime.utc(2026, 8, 5),
    );
    await seedAppointment(
      id: 'appt-3',
      vehicleModel: 'Fiat Egea 2019',
      plate: '35 EGE 123',
      createdAt: DateTime.utc(2026, 8, 10),
    );
    await seedAppointment(
      id: 'appt-4',
      vehicleModel: 'Peugeot 208 2021',
      plate: '42 PEU 456',
      createdAt: DateTime.utc(2026, 8, 15),
    );

    await pumpApp(tester);

    await tester.tap(find.text('Tümünü Gör'));
    await tester.pumpAndSettle();

    expect(find.byType(AllVehiclesPage), findsOneWidget);
    // Including the one pushed off the homepage's 3-item preview.
    expect(find.text('Renault Clio 2018'), findsOneWidget);
    expect(find.text('Toyota Corolla 2020'), findsOneWidget);
    expect(find.text('Fiat Egea 2019'), findsOneWidget);
    expect(find.text('Peugeot 208 2021'), findsOneWidget);

    // The oldest — the one only reachable from this full list, not the
    // homepage preview — still books through the same real entry point.
    await tester.tap(find.text('Renault Clio 2018'));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleRepairCategoryPage), findsOneWidget);
  });

  testWidgets('Tapping a real vehicle in Araçlarım opens the Araç Tamiri flow', (WidgetTester tester) async {
    await seedAppointment(
      id: 'appt-1',
      vehicleModel: 'Renault Clio 2018',
      plate: '34 ABC 123',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    await pumpApp(tester);

    await tester.tap(find.text('Renault Clio 2018'));
    await tester.pumpAndSettle();

    // Same entry point the homepage's own "Araç Tamiri" card opens — the
    // vehicle tap doesn't invent a separate navigation path.
    expect(find.byType(VehicleRepairCategoryPage), findsOneWidget);
  });
}
