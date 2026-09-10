import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/social_auth.dart';
import 'dev/dev_mode_launcher.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/main_shell.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/firebase_instances.dart';

/// The app's real entry point — a plain function (not inlined into
/// MaterialApp.home) so the decision itself is directly unit-testable
/// without needing to toggle the actual compile-time kDebugMode constant
/// or a live FirebaseAuth session (see test/app_home_routing_test.dart). In
/// a debug build, DevModeLauncher stays exactly as it always has, letting a
/// developer freely switch between the customer/mechanic flows while
/// testing — [hasSignedInCustomer] is ignored in that branch. In every
/// other build: a customer who already has a real, persisted session goes
/// straight to MainShell (the exact same destination LoginPage._goToMainShell
/// itself navigates to on a fresh sign-in — see that method) rather than
/// signing in again every time they reopen the app; anyone else (including
/// the 'customer-demo' guest fallback, which is never a real FirebaseAuth
/// session — see resolveCustomerId — so it can never make
/// [hasSignedInCustomer] true) sees LoginPage, same as before. A mechanic
/// reaches registration from LoginPage via its own "İşletmeni Ekle" link,
/// not through this dev picker — untouched by this customer-only check.
Widget resolveAppHome({required bool isDebugBuild, required bool hasSignedInCustomer}) {
  if (isDebugBuild) return const DevModeLauncher();
  return hasSignedInCustomer ? const MainShell() : const LoginPage();
}

/// Resolves [resolveAppHome] for real — synchronous and instant in a debug
/// build (no reason to ever wait on auth state just to show DevModeLauncher,
/// and no change to today's behavior there), but genuinely asynchronous in a
/// real build: firebaseAuthInstance.currentUser can't be trusted
/// immediately after Firebase.initializeApp() completes — the native SDK's
/// persisted-session restore runs asynchronously and may not have finished
/// yet, so reading currentUser synchronously here could wrongly show
/// LoginPage to an already-signed-in customer. authStateChanges()'s first
/// emission is the reliable signal that restoration has actually finished,
/// with either the real restored user or a genuine null — this only ever
/// reads that first emission (a one-time decision on the app's very first
/// frame), not a live listener for the app's whole lifetime: once
/// LoginPage/MainShell takes over via their own pushReplacement navigation,
/// this widget is gone from the tree, same as this app's existing
/// pushReplacement-based flow control everywhere else. A later, real
/// sign-out (once a customer-facing sign-out action exists — none does yet
/// anywhere in this app) is that action's own job to navigate back to
/// LoginPage explicitly, exactly like DevModeLauncher's own "Müşteri Modu"
/// button already does today.
class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return resolveAppHome(isDebugBuild: true, hasSignedInCustomer: false);
    }
    return CustomerSessionGate(authStateChanges: firebaseAuthInstance.authStateChanges());
  }
}

/// The real (non-debug) startup gate, split out from [_AppHome] and made
/// public specifically so it's directly widget-testable with a fake stream
/// (see test/app_home_routing_test.dart) — kDebugMode is always true inside
/// `flutter test`, so _AppHome's own real-vs-debug branch can never
/// actually reach this otherwise. Waits for [authStateChanges]'s first
/// emission (see resolveAppHome's own doc comment for why that, not
/// currentUser, is the reliable signal) before resolving to MainShell or
/// LoginPage.
class CustomerSessionGate extends StatelessWidget {
  const CustomerSessionGate({super.key, required this.authStateChanges});

  final Stream<User?> authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AppStartupSplash();
        }
        return resolveAppHome(isDebugBuild: false, hasSignedInCustomer: snapshot.data != null);
      },
    );
  }
}

/// Shown only for the brief moment a real build spends waiting on
/// authStateChanges()'s first emission (see _AppHome) — plain and minimal
/// since this is expected to resolve almost immediately, not a real loading
/// state anyone should notice.
class _AppStartupSplash extends StatelessWidget {
  const _AppStartupSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

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
      home: const _AppHome(),
    );
  }
}
