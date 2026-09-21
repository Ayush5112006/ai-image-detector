import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase configuration for web preview.
///
/// The app is missing a real Firebase project config
/// (google-services.json / firebase_options.dart), which Firebase requires.
/// These dummy values let the app boot so the UI can be previewed, but
/// Google Sign-In will NOT work until real keys are added.
class AppFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    // Android (no google-services.json) needs options too, or the app
    // crashes at startup. Use the same stub on every platform.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXX_PLACEHOLDER_0000000000',
    appId: '1:000000000000:web:000000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'chitravision-preview',
    authDomain: 'chitravision-preview.firebaseapp.com',
    storageBucket: 'chitravision-preview.appspot.com',
  );
}