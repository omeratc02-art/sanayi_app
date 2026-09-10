import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../utils/firebase_instances.dart';

/// Pure decision: should the soft in-app "may we notify you?" ask (see
/// [showNotificationPermissionSoftAsk]) be shown right now for
/// [appointmentId]? No, if the OS has already granted authorization —
/// there's nothing left to ask for. No, if this exact appointment has
/// already triggered the ask once this session, regardless of the
/// customer's answer (this app's confirmed design: a decline only
/// suppresses re-asking for *that* appointment — a different appointment
/// getting confirmed later, while still unauthorized, asks again). Kept as
/// a standalone function (not a PushNotificationService method) so it's
/// directly unit-testable without any Firebase dependency at all.
bool shouldAskForNotificationPermission({
  required Set<String> alreadyAskedAppointmentIds,
  required String appointmentId,
  required bool alreadyAuthorized,
}) {
  if (alreadyAuthorized) return false;
  if (alreadyAskedAppointmentIds.contains(appointmentId)) return false;
  return true;
}

/// The soft, in-app ask itself — shown before ever triggering the real OS
/// permission prompt, so that prompt (which iOS in particular only really
/// gives you one good shot at) isn't spent on a blind guess. A plain
/// Evet/Hayır dialog with no FirebaseMessaging dependency of its own, so
/// it's directly widget-testable in isolation from the real permission
/// plumbing around it (see PushNotificationService.maybeAskForPermission,
/// which is what actually calls FirebaseMessaging and can't be exercised
/// in a widget test).
Future<bool> showNotificationPermissionSoftAsk(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Bildirim İzni'),
      content: const Text('Randevunuz tamamlandığında sizi bilgilendirelim mi?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Hayır')),
        ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Evet')),
      ],
    ),
  );
  return result ?? false;
}

/// Real FCM plumbing for the appointment completion-confirmation reminder —
/// capturing/refreshing the signed-in customer's device token
/// (customers/{uid}.fcmToken, read by functions/src/completionReminder.ts),
/// the soft-ask -> real OS permission prompt flow, and foreground/
/// background/terminated notification handling. Android only, per this
/// app's confirmed scope — no APNs/iOS-specific setup exists anywhere here;
/// see main.dart's own note on why iOS still compiles regardless.
///
/// None of the FirebaseMessaging-calling methods below are exercised by
/// this project's widget tests — there is no fake/mock platform-channel
/// implementation for firebase_messaging in this project's test
/// dependencies (the same real gap already documented for
/// image_picker/image_cropper/firebase_storage). What IS tested is the
/// pure decision logic above and the plain dialog widget — deliberately
/// kept outside this class so they can be.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _customersCollection = 'customers';

  final Set<String> _askedAppointmentIds = {};
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Called once, at app startup (see main.dart) — sets up the parts of FCM
  /// that don't depend on a signed-in customer: the foreground message
  /// listener, the background-tap listener, and (for a cold start via a
  /// notification tap) the one-time initial-message check. Safe to call
  /// even for a customer who has never granted notification permission —
  /// none of this requires authorization, only actually *displaying* a
  /// system notification does, which is the OS's own concern.
  Future<void> initialize({
    required void Function(RemoteMessage message) onForegroundMessage,
    required void Function() onNotificationTapped,
  }) async {
    FirebaseMessaging.onMessage.listen(onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onNotificationTapped());

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) onNotificationTapped();
  }

  /// Called once per real sign-in (see LoginPage._goToMainShell, the single
  /// chokepoint every customer sign-in path already funnels through) —
  /// captures the current device token immediately (harmless even if the
  /// customer hasn't granted display permission yet; token generation and
  /// notification display are separate concerns on Android) and keeps it
  /// current for the rest of the session via onTokenRefresh, since FCM can
  /// rotate a token at any time, not just on reinstall.
  Future<void> onCustomerSignedIn() async {
    await _captureAndStoreToken();
    try {
      unawaited(_tokenRefreshSubscription?.cancel());
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        _storeToken,
        onError: (Object error) => debugPrint('PUSH NOTIFICATION TOKEN REFRESH ERROR: $error'),
      );
    } catch (error) {
      debugPrint('PUSH NOTIFICATION TOKEN REFRESH SUBSCRIBE ERROR: $error');
    }
  }

  Future<void> _captureAndStoreToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _storeToken(token);
    } catch (error) {
      debugPrint('PUSH NOTIFICATION TOKEN CAPTURE ERROR: $error');
    }
  }

  Future<void> _storeToken(String token) async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return;
    try {
      await firestoreInstance.collection(_customersCollection).doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('PUSH NOTIFICATION TOKEN STORE ERROR: $error');
    }
  }

  /// The soft-ask entry point — called after AppointmentRequestStore.accept()
  /// succeeds (see AppointmentDetailPage/NotificationsPage). Never throws:
  /// wrapped end to end, since this runs alongside a real appointment
  /// confirmation that must succeed regardless of anything notification-
  /// related going wrong (missing plugin, no platform channel in a test
  /// environment, a denied/undetermined OS state, etc).
  Future<void> maybeAskForPermission(BuildContext context, {required String appointmentId}) async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final alreadyAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized;
      final shouldAsk = shouldAskForNotificationPermission(
        alreadyAskedAppointmentIds: _askedAppointmentIds,
        appointmentId: appointmentId,
        alreadyAuthorized: alreadyAuthorized,
      );
      if (!shouldAsk) return;
      _askedAppointmentIds.add(appointmentId);

      if (!context.mounted) return;
      final wantsNotifications = await showNotificationPermissionSoftAsk(context);
      if (!wantsNotifications) return;

      final result = await FirebaseMessaging.instance.requestPermission();
      if (result.authorizationStatus == AuthorizationStatus.authorized) {
        await _captureAndStoreToken();
      }
    } catch (error) {
      debugPrint('PUSH NOTIFICATION PERMISSION ASK ERROR: $error');
    }
  }
}
