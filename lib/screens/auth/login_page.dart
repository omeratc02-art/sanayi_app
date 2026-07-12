import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../home/main_shell.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Çok yakında!')));
  }

  void _continueAsGuest(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.car_repair, size: 48, color: AppColors.red),
              ),
              const SizedBox(height: 24),
              Text(
                'Sanayi App',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aracınız için güvenilir servis ve fiyat karşılaştırma',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showComingSoon(context),
                  child: const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showComingSoon(context),
                  child: const Text('Kayıt Ol'),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => _continueAsGuest(context),
                child: const Text('Misafir olarak devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
