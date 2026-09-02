import 'package:flutter/widgets.dart';

/// Stub for the web-only renderButton — see google_sign_in_button.dart for
/// why google_sign_in_web has to be kept behind a conditional export rather
/// than imported directly from social_auth.dart.
Widget renderButton() {
  throw StateError('renderButton() should only be called on web');
}
