import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/dev/dev_mode_launcher.dart';
import 'package:sanayi_app/main.dart';
import 'package:sanayi_app/screens/auth/login_page.dart';

/// resolveAppHome is the real fix for the entry-point gap found in the
/// earlier investigation: DevModeLauncher (a screen literally titled
/// "Geliştirici Test Ekranı") was the app's unconditional home in every
/// build, including a real release build. kDebugMode itself can't be
/// toggled from a test — it's a compile-time constant — so this tests the
/// extracted decision function directly instead, which is exactly what
/// `home: resolveAppHome(isDebugBuild: kDebugMode)` in main.dart evaluates
/// with the real constant at runtime.
void main() {
  test('Debug build: opens on DevModeLauncher, so a developer can still freely switch test flows', () {
    expect(resolveAppHome(isDebugBuild: true), isA<DevModeLauncher>());
  });

  test('Real (non-debug) build: opens on the real customer-facing LoginPage, never the dev picker', () {
    expect(resolveAppHome(isDebugBuild: false), isA<LoginPage>());
    expect(resolveAppHome(isDebugBuild: false), isNot(isA<DevModeLauncher>()));
  });
}
