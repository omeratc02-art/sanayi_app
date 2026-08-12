import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../home/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  void _goToMainShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  Future<void> _showAuthDialog({required bool isRegister}) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AuthDialog(isRegister: isRegister, onSuccess: _goToMainShell),
    );
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.car_repair, size: 48, color: AppColors.primary),
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
                  onPressed: () => _showAuthDialog(isRegister: false),
                  child: const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAuthDialog(isRegister: true),
                  child: const Text('Kayıt Ol'),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _continueAsGuest,
                child: const Text('Misafir olarak devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smallest possible email/password UI for real Firebase Authentication —
/// a single reusable dialog for both "Giriş Yap" (sign in) and "Kayıt Ol"
/// (register), rather than redesigning LoginPage itself with inline
/// fields. Closes and hands control back to LoginPage (via [onSuccess])
/// only on a real successful FirebaseAuth call.
class _AuthDialog extends StatefulWidget {
  const _AuthDialog({required this.isRegister, required this.onSuccess});

  final bool isRegister;
  final VoidCallback onSuccess;

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _messageForError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen en az 6 karakterli bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. Lütfen internet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen e-posta ve şifrenizi girin.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _messageForError(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isRegister ? 'Kayıt Ol' : 'Giriş Yap'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'E-posta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Şifre'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.isRegister ? 'Kayıt Ol' : 'Giriş Yap'),
        ),
      ],
    );
  }
}
