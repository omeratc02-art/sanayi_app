import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dev/dev_mode_launcher.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: firebase_options.dart currently holds placeholder values (see
  // that file) — this will throw/fail to connect until real Firebase
  // project credentials are generated via `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
