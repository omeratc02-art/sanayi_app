// google_sign_in_web's renderButton() relies on dart:js_interop JS-interop
// types (JSString, JSObject, .toJS, ...) that only compile for web targets
// — importing it unconditionally broke `flutter test`, which compiles for
// the native VM by default (unlike `flutter analyze`, which is lenient
// about this, and `flutter run -d chrome`, which actually is a web
// compile). dart.library.js_util (not the newer dart:js_interop, which
// exists as a stub on every platform and so can't discriminate here) is
// the same conditional-export pattern google_sign_in's own example app
// uses for this exact problem — see its example/lib/src/web_wrapper.dart.
export 'google_sign_in_button_stub.dart' if (dart.library.js_util) 'google_sign_in_button_web.dart';
