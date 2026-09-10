import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/social_auth.dart';
import 'dev/dev_mode_launcher.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

/// Lets a notification tap (see [_handleNotificationTap]) act on the app
/// from outside any widget's own BuildContext — pop back to the root route
/// (in case the customer was mid-navigation in some pushed screen when they
/// tapped a backgrounded notification) and show a foreground in-app banner.
/// MaterialApp below is the only thing that actually owns these; nothing
/// else in this app has needed a global key like this before now.
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Set by [_handleNotificationTap] (a background-tap or a cold-start via
/// getInitialMessage — see PushNotificationService.initialize), consumed
/// once by MainShell to jump straight to the Randevularım tab, since
/// that's exactly where the real completion-confirmation banner this
/// notification is about already lives (see AppointmentsTab's own
/// _CompletionVerificationCard) — there's no more specific per-appointment
/// anchor to deep-link to. A plain ValueNotifier rather than a Stream: it
/// only ever needs to hold "the most recent pending request, if any",
/// which is exactly what a mounted MainShell reads once at startup and any
/// currently-mounted one reacts to immediately.
final pendingAppointmentsTabRequest = ValueNotifier<Object?>(null);

void _handleNotificationTap() {
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
  // A fresh Object() each time (not e.g. `true`) so setting it twice in a
  // row — two notification taps before MainShell ever consumes the first —
  // still notifies listeners both times; ValueNotifier only fires on a
  // value that's actually different from the last one.
  pendingAppointmentsTabRequest.value = Object();
}

void _showForegroundNotificationBanner(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(notification.body ?? notification.title ?? '')));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: firebase_options.dart currently holds placeholder values (see
  // that file) — this will throw/fail to connect until real Firebase
  // project credentials are generated via `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidPlayIntegrityProvider(),
    providerApple: const AppleAppAttestProvider(),
    providerWeb: ReCaptchaEnterpriseProvider('6LcvaaAtAAAAAJjqAqHXht9BRbJXxwZ34790veCu'),
  );
  // Must complete before any GoogleSignIn.instance call — both LoginPage
  // and MechanicLoginPage rely on this having already run.
  await initializeGoogleSignIn();
  // Android only, per this app's confirmed scope — nothing here is iOS/APNs
  // aware, and none of it requires notification permission to have been
  // granted yet (see PushNotificationService's own doc comment). Real
  // token capture only starts once a customer actually signs in (see
  // LoginPage._goToMainShell), not here.
  await PushNotificationService.instance.initialize(
    onForegroundMessage: _showForegroundNotificationBanner,
    onNotificationTapped: _handleNotificationTap,
  );
  runApp(const SanayiApp());
}

class SanayiApp extends StatelessWidget {
  const SanayiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sanayi App',
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      // Needed so showDatePicker (and any other Material widget) can be
      // rendered in Turkish — see the calendar icon in
      // MechanicAppointmentsScreen.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      // TODO: Once authentication/user roles exist, pick the home screen
      // based on the logged-in user's role directly — MainShell
      // (screens/home/main_shell.dart) for customers, MechanicHomePage
      // (mechanic/home/mechanic_home_page.dart) for mechanics.
      // DevModeLauncher (dev/dev_mode_launcher.dart) is the dev-only manual
      // picker used until that real role-based routing exists — its "Usta
      // Modu" button leads to MechanicLoginPage, so real Firebase mechanic
      // sign-in is still exercised end-to-end.
      home: const DevModeLauncher(),
    );
  }
}
