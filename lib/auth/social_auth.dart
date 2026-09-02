import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/firebase_instances.dart';
import 'google_sign_in_button.dart' as google_sign_in_button;

/// Google Sign-In must be initialized exactly once, before any other
/// GoogleSignIn.instance call, per the package's own contract — done once
/// here (called from main.dart) rather than lazily per call site, since
/// both LoginPage and MechanicLoginPage need it ready. No clientId is
/// passed: Android/iOS resolve their OAuth client from
/// google-services.json/GoogleService-Info.plist automatically, and web
/// resolves it from the google-signin-client_id meta tag in web/index.html.
Future<void> initializeGoogleSignIn() => GoogleSignIn.instance.initialize();

/// Whether [signInWithGoogle] can be called directly to pop a system
/// account picker — true on Android/iOS/desktop, false on web. Callers
/// check this to decide between a normal app-triggered button
/// ([signInWithGoogle]) and Google's own rendered button
/// ([googleSignInButton]) — see the package's own README, which documents
/// this exact branch. Calling [signInWithGoogle] where this is false throws
/// UnimplementedError (confirmed the hard way — see the conversation this
/// code was born from).
bool get supportsImperativeGoogleSignIn => GoogleSignIn.instance.supportsAuthenticate();

/// Google's own rendered sign-in button — the only supported way to start a
/// user-initiated Google sign-in on web; there is no equivalent of a native
/// account-picker popup there. Only call this behind a `kIsWeb` check (it
/// asserts the platform is web internally). Tapping it doesn't return a
/// value the way [signInWithGoogle] does — completion arrives through
/// [googleSignInAccounts] instead.
Widget googleSignInButton() => google_sign_in_button.renderButton();

/// Fires once per completed Google sign-in, however it was triggered —
/// [signInWithGoogle]'s own call on platforms that support it, or the user
/// completing the flow through [googleSignInButton] on web. Web-only
/// callers (LoginPage/MechanicLoginPage) listen to this instead of awaiting
/// a call, since [googleSignInButton]'s tap isn't observable directly.
Stream<GoogleSignInAccount> get googleSignInAccounts => GoogleSignIn.instance.authenticationEvents
    .where((event) => event is GoogleSignInAuthenticationEventSignIn)
    .map((event) => (event as GoogleSignInAuthenticationEventSignIn).user);

/// Signs in with Google — one unified action for both new and returning
/// users (Firebase creates the account automatically on first use here,
/// unlike email/password's separate register/sign-in calls). Only call
/// where [supportsImperativeGoogleSignIn] is true; use [googleSignInButton]
/// + [googleSignInAccounts] otherwise (web). Throws GoogleSignInException
/// (e.g. the user cancelled the account picker) or FirebaseAuthException on
/// failure — callers handle both.
Future<UserCredential> signInWithGoogle() async {
  final account = await GoogleSignIn.instance.authenticate();
  return signInAccountWithFirebase(account);
}

/// Exchanges an already-authenticated [GoogleSignInAccount] for a Firebase
/// credential — the shared second half of both [signInWithGoogle] and the
/// web button flow (via [googleSignInAccounts]), so both paths produce an
/// identical Firebase sign-in.
Future<UserCredential> signInAccountWithFirebase(GoogleSignInAccount account) {
  final idToken = account.authentication.idToken;
  final credential = GoogleAuthProvider.credential(idToken: idToken);
  return firebaseAuthInstance.signInWithCredential(credential);
}

/// One outcome of [startPhoneSignIn]: either the code was already confirmed
/// automatically (Android's SMS auto-retrieval — [autoSignedInCredential]
/// is set and there's nothing left for the caller to do), or the caller
/// must collect the SMS code from the user and call [confirm] with it.
/// Exactly one of the two is non-null.
class PhoneSignInSession {
  const PhoneSignInSession._({this.autoSignedInCredential, this.confirm});

  final UserCredential? autoSignedInCredential;
  final Future<UserCredential> Function(String smsCode)? confirm;
}

/// Strips everything but digits and a leading '+' from [input]. Firebase's
/// phone endpoints require strict E.164 (no spaces/dashes/parens) — the
/// dialogs' hint text ('+90 5xx xxx xx xx') encourages typing with spaces,
/// which sent as-is produced a 400 from accounts:sendVerificationCode.
/// Normalizing here, not in each dialog, so every caller is covered.
String _toE164(String input) {
  final trimmed = input.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// Starts a phone sign-in, sending an SMS code to [phoneNumber] (must
/// include the country code, e.g. '+90...'). Unifies firebase_auth's two
/// separate phone APIs — signInWithPhoneNumber (web only, Future-based) and
/// verifyPhoneNumber (mobile/desktop only, callback-based, with Android's
/// own automatic SMS retrieval able to short-circuit the whole flow) —
/// behind one awaitable call so LoginPage/MechanicLoginPage don't need
/// their own platform branching.
Future<PhoneSignInSession> startPhoneSignIn(String rawPhoneNumber) async {
  final phoneNumber = _toE164(rawPhoneNumber);
  if (kIsWeb) {
    final confirmationResult = await firebaseAuthInstance.signInWithPhoneNumber(phoneNumber);
    return PhoneSignInSession._(confirm: confirmationResult.confirm);
  }

  final completer = Completer<PhoneSignInSession>();
  await firebaseAuthInstance.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (credential) async {
      if (completer.isCompleted) return;
      try {
        final userCredential = await firebaseAuthInstance.signInWithCredential(credential);
        completer.complete(PhoneSignInSession._(autoSignedInCredential: userCredential));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    },
    verificationFailed: (error) {
      if (!completer.isCompleted) completer.completeError(error);
    },
    codeSent: (verificationId, _) {
      // Real code entry is now possible; auto-verification (above) can
      // still race ahead of this on Android, hence the isCompleted guard —
      // whichever callback fires first for a given attempt wins.
      if (completer.isCompleted) return;
      completer.complete(
        PhoneSignInSession._(
          confirm: (smsCode) => firebaseAuthInstance.signInWithCredential(
            PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode),
          ),
        ),
      );
    },
    codeAutoRetrievalTimeout: (_) {},
  );
  return completer.future;
}
