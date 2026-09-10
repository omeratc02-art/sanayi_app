import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/services/push_notification_service.dart';

/// Covers exactly what's testable in this project's widget-test sandbox for
/// the notification-permission soft-ask (see PushNotificationService's own
/// doc comment on why): the pure "should we even ask" decision, and the
/// dialog widget itself — deliberately kept free of any FirebaseMessaging
/// dependency so they can be. PushNotificationService.maybeAskForPermission
/// itself — the real FirebaseMessaging.instance.getNotificationSettings()/
/// requestPermission() glue around these two — is not exercised here; there
/// is no fake/mock platform-channel implementation for firebase_messaging
/// in this project's test dependencies (the same real gap already
/// documented for image_picker/image_cropper/firebase_storage).
void main() {
  group('shouldAskForNotificationPermission (unit)', () {
    test('true for a brand-new appointment id when not yet authorized', () {
      final result = shouldAskForNotificationPermission(
        alreadyAskedAppointmentIds: {},
        appointmentId: 'appt-1',
        alreadyAuthorized: false,
      );
      expect(result, isTrue);
    });

    test('false once this exact appointment has already been asked about, regardless of the answer', () {
      final result = shouldAskForNotificationPermission(
        alreadyAskedAppointmentIds: {'appt-1'},
        appointmentId: 'appt-1',
        alreadyAuthorized: false,
      );
      expect(result, isFalse);
    });

    test('false when the OS has already granted authorization, even for a never-asked appointment', () {
      final result = shouldAskForNotificationPermission(
        alreadyAskedAppointmentIds: {},
        appointmentId: 'appt-1',
        alreadyAuthorized: true,
      );
      expect(result, isFalse);
    });

    test('true for a different, later appointment id when still not authorized — a decline is per-appointment, not permanent', () {
      final result = shouldAskForNotificationPermission(
        alreadyAskedAppointmentIds: {'appt-1'},
        appointmentId: 'appt-2',
        alreadyAuthorized: false,
      );
      expect(result, isTrue);
    });
  });

  group('showNotificationPermissionSoftAsk (widget)', () {
    Future<void> pumpTrigger(WidgetTester tester, ValueChanged<bool> onResult) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showNotificationPermissionSoftAsk(context);
                onResult(result);
              },
              child: const Text('trigger'),
            ),
          ),
        ),
      );
    }

    testWidgets('Shows the real Turkish prompt with Evet/Hayır', (WidgetTester tester) async {
      await pumpTrigger(tester, (_) {});

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Bildirim İzni'), findsOneWidget);
      expect(find.text('Randevunuz tamamlandığında sizi bilgilendirelim mi?'), findsOneWidget);
      expect(find.text('Evet'), findsOneWidget);
      expect(find.text('Hayır'), findsOneWidget);
    });

    testWidgets('Tapping Evet resolves true and dismisses the dialog', (WidgetTester tester) async {
      bool? result;
      await pumpTrigger(tester, (value) => result = value);

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Bildirim İzni'), findsNothing);
    });

    testWidgets('Tapping Hayır resolves false and dismisses the dialog', (WidgetTester tester) async {
      bool? result;
      await pumpTrigger(tester, (value) => result = value);

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hayır'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Bildirim İzni'), findsNothing);
    });
  });
}
