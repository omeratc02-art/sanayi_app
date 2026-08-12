import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../home/mechanic_home_page.dart';

/// Mechanic-side counterpart to the customer screens/auth/login_page.dart —
/// same visual style and the same small email/password dialog pattern,
/// duplicated locally rather than shared, so the customer LoginPage never
/// has to change for this. Not wired into main.dart/DevModeLauncher yet;
/// DevModeLauncher's "Usta Modu" remains the dev fallback straight into
/// MechanicHomePage.
class MechanicLoginPage extends StatefulWidget {
  const MechanicLoginPage({super.key});

  @override
  State<MechanicLoginPage> createState() => _MechanicLoginPageState();
}

class _MechanicLoginPageState extends State<MechanicLoginPage> {
  void _goToMechanicHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MechanicHomePage()));
  }

  Future<void> _showAuthDialog({required bool isRegister}) {
    return showDialog<void>(
      context: context,
      builder: (_) => _MechanicAuthDialog(isRegister: isRegister, onSuccess: _goToMechanicHome),
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
                'Usta panelinize giriş yapın',
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Smallest possible email/password UI for real Firebase Authentication —
/// mirrors screens/auth/login_page.dart's _AuthDialog (same fields, same
/// Turkish error-message mapping) but is its own local copy so that file
/// never needs to change.
class _MechanicAuthDialog extends StatefulWidget {
  const _MechanicAuthDialog({required this.isRegister, required this.onSuccess});

  final bool isRegister;
  final VoidCallback onSuccess;

  @override
  State<_MechanicAuthDialog> createState() => _MechanicAuthDialogState();
}

class _MechanicAuthDialogState extends State<_MechanicAuthDialog> {
  // Which catalog business (see MockData.allMechanics) this account
  // represents — required at registration so the account can be linked to
  // a business by its stable id (see mechanicChatId), not by re-typing a
  // name that has no guaranteed relationship to any real business.
  Mechanic? _selectedBusiness;
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
        // TEMPORARY diagnostic — surfaces the real FirebaseAuthException
        // code/message for any code not already mapped above, instead of
        // hiding it behind the generic message. Revert once the actual
        // cause of the registration failure is identified.
        return 'Bir hata oluştu (${error.code}): ${error.message}';
    }
  }

  Future<void> _submit() async {
    final selectedBusiness = _selectedBusiness;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty || (widget.isRegister && selectedBusiness == null)) {
      setState(() {
        _errorMessage = widget.isRegister
            ? 'Lütfen usta/işletme adı, e-posta ve şifrenizi girin.'
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
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = credential.user!.uid;
        try {
          // businessId is the stable link to the catalog business this
          // account represents (see MockData.allMechanics / mechanicChatId)
          // — the same id already used as that business's chats/{chatId}
          // document, so chats can be matched by id instead of by
          // comparing free-text names.
          await FirebaseFirestore.instance.collection('mechanicAccounts').doc(uid).set({
            'name': selectedBusiness!.name,
            'businessId': mechanicChatId(selectedBusiness.name),
            'email': email,
            'role': 'mechanic',
            // Bootstrapped from the chosen catalog entry at registration
            // time so the real profile (see MechanicProfileScreen) has
            // something real to show immediately, rather than starting
            // completely empty — this is a one-time copy, not a live link
            // back to MockData; editing a real profile later would only
            // ever touch this document, never the catalog.
            'phone': selectedBusiness.phone,
            'address': selectedBusiness.address,
            'isVerified': selectedBusiness.isVerified,
            'rating': selectedBusiness.rating,
            'reviewCount': selectedBusiness.reviewCount,
          });
        } catch (error) {
          // The Firebase Auth account was already created at this point —
          // don't pretend registration fully succeeded if the mechanic
          // identity mapping couldn't be saved.
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Hesabınız oluşturuldu ancak usta bilgileri kaydedilemedi: $error';
          });
          return;
        }
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
    } catch (error) {
      if (!mounted) return;
      // TEMPORARY diagnostic — same reasoning as the FirebaseAuthException
      // default case above: shows the real thrown error instead of hiding
      // a possible non-FirebaseAuthException failure behind a generic
      // message. Revert once the actual cause is identified.
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Beklenmeyen hata: $error';
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
            DropdownButtonFormField<Mechanic>(
              initialValue: _selectedBusiness,
              decoration: const InputDecoration(labelText: 'Usta / İşletme Adı'),
              items: [
                for (final business in MockData.allMechanics)
                  DropdownMenuItem(value: business, child: Text(business.name)),
              ],
              onChanged: (value) => setState(() => _selectedBusiness = value),
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
