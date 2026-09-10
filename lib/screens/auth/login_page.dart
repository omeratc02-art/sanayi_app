import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../auth/social_auth.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';
import '../home/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _isGoogleSigningIn = false;
  StreamSubscription<GoogleSignInAccount>? _googleSignInSubscription;

  @override
  void initState() {
    super.initState();
    // Web has no app-triggered sign-in call (see social_auth.dart's
    // supportsImperativeGoogleSignIn) — completion instead arrives here,
    // once the user finishes the flow through Google's own rendered button.
    if (kIsWeb) {
      _googleSignInSubscription = googleSignInAccounts.listen(_handleWebGoogleSignIn);
    }
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    super.dispose();
  }

  void _goToMainShell() {
    if (!mounted) return;
    // Every real customer sign-in path in this file (Google, phone,
    // email/password, the debug quick sign-in) funnels through here — the
    // single chokepoint where resolveCustomerId() first becomes meaningful
    // for this session, so it's where device-token capture starts too.
    // Not awaited: a slow/failed token write must never delay or block
    // actually taking the customer to MainShell.
    unawaited(PushNotificationService.instance.onCustomerSignedIn());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleWebGoogleSignIn(GoogleSignInAccount account) async {
    setState(() => _isGoogleSigningIn = true);
    try {
      await signInAccountWithFirebase(account);
      _goToMainShell();
    } catch (error, stack) {
      debugPrint('Google sign-in failed: $error\n$stack');
      _showError('Google ile giriş başarısız oldu.');
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSigningIn = true);
    try {
      await signInWithGoogle();
      _goToMainShell();
    } on GoogleSignInException catch (error, stack) {
      // canceled: the user closed the account picker — not an error worth
      // surfacing as a SnackBar, unlike every other failure case here.
      if (error.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('Google sign-in failed: $error\n$stack');
        _showError('Google ile giriş başarısız oldu.');
      }
    } catch (error, stack) {
      debugPrint('Google sign-in failed: $error\n$stack');
      _showError('Google ile giriş başarısız oldu.');
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  Future<void> _showPhoneAuthDialog() {
    return showDialog<void>(
      context: context,
      builder: (_) => _PhoneAuthDialog(onSuccess: _goToMainShell),
    );
  }

  // Debug-only quick sign-in — reuses the exact same FirebaseAuth call and
  // post-login navigation as the manual _AuthDialog form. Never reachable
  // outside kDebugMode (see the gated call site in build() below).
  Future<void> _debugSignIn(String email, String password) async {
    try {
      await firebaseAuthInstance.signInWithEmailAndPassword(email: email, password: password);
      _goToMainShell();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test girişi başarısız: $error')),
      );
    }
  }

  // Credentials are declared here, inside a method only ever invoked from
  // the kDebugMode-gated branch in build() — dead-code-eliminated in
  // release builds along with everything else in this method.
  Widget _debugLoginButton() {
    const debugEmail = 'omeratc02@gmail.com';
    const debugPassword = '123456';
    return Column(
      children: [
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _debugSignIn(debugEmail, debugPassword),
          child: const Text(
            'Test: Müşteri Girişi',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
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
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('veya', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              // Web has no app-triggered popup — supportsImperativeGoogleSignIn
              // is false there, so Google's own rendered button takes over
              // (see social_auth.dart's googleSignInButton doc comment).
              if (supportsImperativeGoogleSignIn)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleSigningIn ? null : _signInWithGoogle,
                    icon: _isGoogleSigningIn
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text('Google ile Devam Et'),
                  ),
                )
              else if (kIsWeb)
                Center(child: googleSignInButton()),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showPhoneAuthDialog,
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Telefon ile Devam Et'),
                ),
              ),
              if (kDebugMode) _debugLoginButton(),
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
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
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty || (widget.isRegister && fullName.isEmpty)) {
      setState(() {
        _errorMessage = widget.isRegister
            ? 'Lütfen ad soyad, e-posta ve şifrenizi girin.'
            : 'Lütfen e-posta ve şifrenizi girin.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.isRegister) {
        final credential = await firebaseAuthInstance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Sets the real display name customer-side chat notifications now
        // read (see ChatRepository.sendMessage) instead of a hardcoded
        // placeholder. reload() refreshes the cached currentUser object so
        // displayName is immediately available to the rest of the app in
        // this same session, not just after a future sign-in.
        await credential.user?.updateProfile(displayName: fullName);
        await credential.user?.reload();
      } else {
        await firebaseAuthInstance.signInWithEmailAndPassword(email: email, password: password);
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
          if (widget.isRegister) ...[
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
          ],
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

enum _PhoneAuthStep { phone, code, name }

/// Phone/OTP sign-in — a single dialog with three possible steps rather
/// than a register/sign-in split like [_AuthDialog]: Firebase treats phone
/// auth as one unified action (an unrecognized number just becomes a new
/// account), so there's no separate "register" entry point to begin with.
/// The name step only appears for a brand-new account that still has no
/// displayName — Google Sign-In doesn't need this (the account already
/// carries one), which is why it isn't reused there.
class _PhoneAuthDialog extends StatefulWidget {
  const _PhoneAuthDialog({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_PhoneAuthDialog> createState() => _PhoneAuthDialogState();
}

class _PhoneAuthDialogState extends State<_PhoneAuthDialog> {
  final _phoneController = TextEditingController(text: '+90');
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  var _step = _PhoneAuthStep.phone;
  var _isSubmitting = false;
  String? _errorMessage;
  PhoneSignInSession? _session;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _messageForError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası. Ülke koduyla girin (ör. +90...).';
      case 'invalid-verification-code':
        return 'Doğrulama kodu hatalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. Lütfen internet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  // Shared by both the auto-verified (Android) and manually-confirmed
  // paths — decides whether this account still needs a display name before
  // handing control back to LoginPage.
  void _afterSignedIn() {
    final needsName = (firebaseAuthInstance.currentUser?.displayName ?? '').trim().isEmpty;
    if (needsName) {
      setState(() {
        _isSubmitting = false;
        _step = _PhoneAuthStep.name;
      });
      return;
    }
    Navigator.of(context).pop();
    widget.onSuccess();
  }

  Future<void> _sendCode() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() => _errorMessage = 'Lütfen telefon numaranızı girin.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await startPhoneSignIn(phoneNumber);
      if (!mounted) return;
      if (session.autoSignedInCredential != null) {
        _afterSignedIn();
        return;
      }
      setState(() {
        _session = session;
        _step = _PhoneAuthStep.code;
        _isSubmitting = false;
      });
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

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Lütfen doğrulama kodunu girin.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _session!.confirm!(code);
      if (!mounted) return;
      _afterSignedIn();
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

  Future<void> _saveNameAndFinish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Lütfen adınızı girin.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await firebaseAuthInstance.currentUser?.updateDisplayName(name);
      await firebaseAuthInstance.currentUser?.reload();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
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
    final title = switch (_step) {
      _PhoneAuthStep.phone => 'Telefon ile Devam Et',
      _PhoneAuthStep.code => 'Kodu Doğrulayın',
      _PhoneAuthStep.name => 'Adınızı Girin',
    };
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == _PhoneAuthStep.phone)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon Numarası', hintText: '+90 5xx xxx xx xx'),
            ),
          if (_step == _PhoneAuthStep.code)
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Doğrulama Kodu'),
            ),
          if (_step == _PhoneAuthStep.name)
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
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
          onPressed: _isSubmitting
              ? null
              : switch (_step) {
                  _PhoneAuthStep.phone => _sendCode,
                  _PhoneAuthStep.code => _confirmCode,
                  _PhoneAuthStep.name => _saveNameAndFinish,
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(switch (_step) {
                  _PhoneAuthStep.phone => 'Kod Gönder',
                  _PhoneAuthStep.code => 'Doğrula',
                  _PhoneAuthStep.name => 'Devam Et',
                }),
        ),
      ],
    );
  }
}
