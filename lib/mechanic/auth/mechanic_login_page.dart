import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../auth/social_auth.dart';
import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/firebase_instances.dart';
import '../home/mechanic_home_page.dart';

/// The mechanicAccounts write for a new registration — shared by both entry
/// points (_MechanicAuthDialogState's email/password register, and
/// _BusinessPickerDialogState's post-signin picker for Google/Phone).
///
/// 'tamir' bootstraps from a picked MockData catalog entry, exactly as
/// before hizmetTürü selection existed — every catalog business is a repair
/// shop, so this is the same real data those fields always had.
///
/// 'ekspertiz' has no catalog to bootstrap from (MockData has no Ekspertiz
/// businesses) — only what the mechanic actually typed (name) is set;
/// phone/address/isVerified/rating/reviewCount/specialty/hizmetler are left
/// unset rather than fabricated, same "don't invent data" pattern already
/// used for priceMin/priceMax/workingHours elsewhere in this app.
Map<String, dynamic> _mechanicAccountData({
  required String hizmetTuru,
  required String email,
  Mechanic? selectedBusiness,
  String? businessName,
}) {
  if (hizmetTuru == 'tamir') {
    final business = selectedBusiness!;
    return {
      'name': business.name,
      'businessId': mechanicChatId(business.name),
      'email': email,
      'role': 'mechanic',
      'phone': business.phone,
      'address': business.address,
      'isVerified': business.isVerified,
      'rating': business.rating,
      'reviewCount': business.reviewCount,
      'specialty': business.specialty,
      'hizmetTürü': 'tamir',
      'hizmetler': business.categories,
    };
  }
  final name = businessName!;
  return {
    'name': name,
    'businessId': mechanicChatId(name),
    'email': email,
    'role': 'mechanic',
    'hizmetTürü': hizmetTuru,
  };
}

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

  void _goToMechanicHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MechanicHomePage()));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Shared by both the Google and Phone flows below — unlike email/password,
  // neither is a distinct register/sign-in action, so "does this uid
  // already have a mechanicAccounts document" is what decides whether the
  // business-picker step (see _BusinessPickerDialog) still needs to run.
  Future<void> _continueAfterMechanicSignIn(User user) async {
    final doc = await firestoreInstance.collection('mechanicAccounts').doc(user.uid).get();
    if (!mounted) return;
    if (doc.exists) {
      _goToMechanicHome();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BusinessPickerDialog(uid: user.uid, email: user.email ?? '', onSuccess: _goToMechanicHome),
    );
  }

  Future<void> _handleWebGoogleSignIn(GoogleSignInAccount account) async {
    setState(() => _isGoogleSigningIn = true);
    try {
      final credential = await signInAccountWithFirebase(account);
      await _continueAfterMechanicSignIn(credential.user!);
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
      final credential = await signInWithGoogle();
      await _continueAfterMechanicSignIn(credential.user!);
    } on GoogleSignInException catch (error, stack) {
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
      builder: (_) => _MechanicPhoneAuthDialog(onSignedIn: _continueAfterMechanicSignIn),
    );
  }

  // Debug-only quick sign-in — reuses the exact same FirebaseAuth call and
  // post-login navigation as the manual _MechanicAuthDialog form. Never
  // reachable outside kDebugMode (see the gated call site in build() below).
  Future<void> _debugSignIn(String email, String password) async {
    try {
      await firebaseAuthInstance.signInWithEmailAndPassword(email: email, password: password);
      _goToMechanicHome();
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
    const debugEmail = 'cupriacorp@gmail.com';
    const debugPassword = '123456';
    return Column(
      children: [
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _debugSignIn(debugEmail, debugPassword),
          child: const Text(
            'Test: Usta Girişi',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
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
  // 'tamir' | 'ekspertiz' — sigorta stays excluded per kSigortaEnabled, not
  // offered here at all. Only meaningful while widget.isRegister.
  String _hizmetTuru = 'tamir';

  // Which catalog business (see MockData.allMechanics) this account
  // represents, when _hizmetTuru == 'tamir' — required so the account can
  // be linked to a business by its stable id (see mechanicChatId), not by
  // re-typing a name that has no guaranteed relationship to any real
  // business. MockData has no Ekspertiz businesses, so 'ekspertiz'
  // registrations use _businessNameController instead — see build().
  Mechanic? _selectedBusiness;
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
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
    final businessName = _businessNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final hasBusiness = _hizmetTuru == 'tamir' ? selectedBusiness != null : businessName.isNotEmpty;
    if (email.isEmpty || password.isEmpty || (widget.isRegister && !hasBusiness)) {
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
        final credential = await firebaseAuthInstance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final uid = credential.user!.uid;
        try {
          await firestoreInstance.collection('mechanicAccounts').doc(uid).set(
            _mechanicAccountData(
              hizmetTuru: _hizmetTuru,
              email: email,
              selectedBusiness: selectedBusiness,
              businessName: businessName,
            ),
          );
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
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tamir', label: Text('Araç Tamiri')),
                ButtonSegment(value: 'ekspertiz', label: Text('Ekspertiz')),
              ],
              selected: {_hizmetTuru},
              onSelectionChanged: (selection) => setState(() {
                _hizmetTuru = selection.first;
                // Cross-type state left over from switching back and forth
                // shouldn't silently ride along into the write.
                _selectedBusiness = null;
                _businessNameController.clear();
              }),
            ),
            const SizedBox(height: 12),
            if (_hizmetTuru == 'tamir')
              DropdownButtonFormField<Mechanic>(
                initialValue: _selectedBusiness,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Usta / İşletme Adı'),
                items: [
                  for (final business in MockData.allMechanics)
                    DropdownMenuItem(
                      value: business,
                      child: Text(business.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedBusiness = value),
              )
            else
              // No MockData catalog exists for Ekspertiz — a real,
              // mechanic-typed name, not a pick from a fake list.
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'İşletme Adı'),
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

/// Shown after a Google or Phone sign-in for a uid with no mechanicAccounts
/// document yet — the equivalent of [_MechanicAuthDialog]'s register step,
/// just triggered by "does this account already exist" instead of an
/// explicit isRegister flag, since neither Google nor Phone has a separate
/// register action to hang that off of. barrierDismissible: false at the
/// call site — the Firebase Auth account already exists by this point, so
/// dismissing without picking a business would leave a signed-in user with
/// no usable mechanic profile; "Vazgeç" below signs back out instead,
/// which is the one clean way out of that state.
class _BusinessPickerDialog extends StatefulWidget {
  const _BusinessPickerDialog({required this.uid, required this.email, required this.onSuccess});

  final String uid;
  final String email;
  final VoidCallback onSuccess;

  @override
  State<_BusinessPickerDialog> createState() => _BusinessPickerDialogState();
}

class _BusinessPickerDialogState extends State<_BusinessPickerDialog> {
  String _hizmetTuru = 'tamir';
  Mechanic? _selectedBusiness;
  final _businessNameController = TextEditingController();
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await firebaseAuthInstance.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final selectedBusiness = _selectedBusiness;
    final businessName = _businessNameController.text.trim();
    final hasBusiness = _hizmetTuru == 'tamir' ? selectedBusiness != null : businessName.isNotEmpty;
    if (!hasBusiness) {
      setState(() => _errorMessage = 'Lütfen usta/işletme adınızı seçin.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Same shared write as _MechanicAuthDialogState._submit's register
      // path — see _mechanicAccountData's doc comment.
      await firestoreInstance.collection('mechanicAccounts').doc(widget.uid).set(
        _mechanicAccountData(
          hizmetTuru: _hizmetTuru,
          email: widget.email,
          selectedBusiness: selectedBusiness,
          businessName: businessName,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Usta bilgileri kaydedilemedi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İşletmenizi Seçin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tamir', label: Text('Araç Tamiri')),
              ButtonSegment(value: 'ekspertiz', label: Text('Ekspertiz')),
            ],
            selected: {_hizmetTuru},
            onSelectionChanged: (selection) => setState(() {
              _hizmetTuru = selection.first;
              _selectedBusiness = null;
              _businessNameController.clear();
            }),
          ),
          const SizedBox(height: 12),
          if (_hizmetTuru == 'tamir')
            DropdownButtonFormField<Mechanic>(
              initialValue: _selectedBusiness,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Usta / İşletme Adı'),
              items: [
                for (final business in MockData.allMechanics)
                  DropdownMenuItem(value: business, child: Text(business.name)),
              ],
              onChanged: (value) => setState(() => _selectedBusiness = value),
            )
          else
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'İşletme Adı'),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _cancel,
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Devam Et'),
        ),
      ],
    );
  }
}

enum _MechanicPhoneAuthStep { phone, code }

/// Phone/OTP sign-in for the mechanic side — mirrors
/// screens/auth/login_page.dart's _PhoneAuthDialog (same two phone/code
/// steps, same error mapping) but stops there: unlike the customer version's
/// third "name" step, deciding whether a business still needs to be picked
/// is [_MechanicLoginPageState._continueAfterMechanicSignIn]'s job, run
/// after this dialog closes — see [onSignedIn].
class _MechanicPhoneAuthDialog extends StatefulWidget {
  const _MechanicPhoneAuthDialog({required this.onSignedIn});

  final Future<void> Function(User user) onSignedIn;

  @override
  State<_MechanicPhoneAuthDialog> createState() => _MechanicPhoneAuthDialogState();
}

class _MechanicPhoneAuthDialogState extends State<_MechanicPhoneAuthDialog> {
  final _phoneController = TextEditingController(text: '+90');
  final _codeController = TextEditingController();

  var _step = _MechanicPhoneAuthStep.phone;
  var _isSubmitting = false;
  String? _errorMessage;
  PhoneSignInSession? _session;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
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

  Future<void> _afterSignedIn(User user) async {
    if (!mounted) return;
    Navigator.of(context).pop();
    await widget.onSignedIn(user);
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
      final autoCredential = session.autoSignedInCredential;
      if (autoCredential != null) {
        await _afterSignedIn(autoCredential.user!);
        return;
      }
      setState(() {
        _session = session;
        _step = _MechanicPhoneAuthStep.code;
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
      final credential = await _session!.confirm!(code);
      await _afterSignedIn(credential.user!);
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
      title: Text(_step == _MechanicPhoneAuthStep.phone ? 'Telefon ile Devam Et' : 'Kodu Doğrulayın'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == _MechanicPhoneAuthStep.phone)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon Numarası', hintText: '+90 5xx xxx xx xx'),
            ),
          if (_step == _MechanicPhoneAuthStep.code)
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Doğrulama Kodu'),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : (_step == _MechanicPhoneAuthStep.phone ? _sendCode : _confirmCode),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_step == _MechanicPhoneAuthStep.phone ? 'Kod Gönder' : 'Doğrula'),
        ),
      ],
    );
  }
}
