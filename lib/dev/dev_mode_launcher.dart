import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../mechanic/auth/mechanic_login_page.dart';
import '../screens/auth/login_page.dart';

/// Development-only launcher — lets whoever is running the app locally pick
/// which side to open (customer vs. mechanic) instead of hardcoding either
/// one as the app's entry point. Not part of the real product: there's no
/// authentication/role system yet (see the TODO in main.dart), so this
/// stands in for that during development only.
class DevModeLauncher extends StatelessWidget {
  const DevModeLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Geliştirici Test Ekranı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Test etmek istediğiniz kullanıcı tipini seçin.',
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Prevents a lingering Firebase Auth session (e.g.
                      // from testing "Usta Modu" earlier in this same app
                      // run) from silently carrying into customer mode —
                      // Müşteri Modu should always start at a clean,
                      // unauthenticated login screen, never skip straight
                      // past it via a stale session. This only affects
                      // this one transition; mechanic sign-in/out is
                      // untouched.
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text('👤 Müşteri Modu'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MechanicLoginPage()),
                    ),
                    child: const Text('🔧 Usta Modu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
