import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for ChitraVision AI.
///
/// Values match the committed `android/app/google-services.json` for the
/// Android app (`com.chitravisionai.app`). Other platforms have no real
/// config yet — Google Sign-In stays hidden there (see
/// `AuthService.firebaseReady`) until real keys are added.
class AppFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwXljmyHTTIvT8f81BWVLGrVw6jgIneDo',
    appId: '1:711374283130:android:a5a5f621383a1a740776c3',
    messagingSenderId: '711374283130',
    projectId: 'chitravisionai-de611',
    storageBucket: 'chitravisionai-de611.firebasestorage.app',
  );

  /// Android is the only platform with a real Firebase config so far; the
  /// app's Google Sign-In target.
  static FirebaseOptions get currentPlatform => android;
}