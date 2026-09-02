import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// GoogleSignInPlatform.instance defaults to a placeholder that throws
/// UnimplementedError for every member — real apps never notice, since
/// Flutter's plugin registration replaces it with a real platform
/// implementation before main() runs. Widget tests never go through that
/// registration step, so LoginPage/MechanicLoginPage's unconditional
/// GoogleSignIn.instance.supportsAuthenticate() call (see
/// social_auth.dart's supportsImperativeGoogleSignIn) crashes their whole
/// build() the moment any test reaches those pages — install this in
/// setUp() first, mirroring firebaseAuthInstance/firestoreInstance's own
/// overridable-seam pattern (see utils/firebase_instances.dart).
///
/// Only supportsAuthenticate() is actually exercised by the widgets under
/// test today (a plain build/render never signs in) — it returns true so
/// tests see the same tappable-button branch a real Android/iOS/desktop
/// app would render, matching what these tests already assert against.
/// Everything else throws if a test ever calls far enough to reach it,
/// which should be treated as a sign that this fake needs a real
/// implementation for that member, not silently returning a made-up value.
class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  @override
  bool supportsAuthenticate() => true;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) {
    throw UnimplementedError('FakeGoogleSignInPlatform.authenticate is not implemented for tests.');
  }

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) {
    throw UnimplementedError(
      'FakeGoogleSignInPlatform.clientAuthorizationTokensForScopes is not implemented for tests.',
    );
  }

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) {
    throw UnimplementedError(
      'FakeGoogleSignInPlatform.serverAuthorizationTokensForScopes is not implemented for tests.',
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}
