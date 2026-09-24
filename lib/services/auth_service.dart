import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Centralised authentication service.
/// Wraps Firebase Auth + Google Sign-In so screens stay thin.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Set during startup (see `main.dart`). Google Sign-In is only available
  /// when a real Firebase project / `google-services.json` is configured;
  /// otherwise the Google button is hidden and email auth still works.
  static bool firebaseReady = false;

  // ── Stream ──────────────────────────────────────────────────────────────────

  /// Emits [User] when signed in, `null` when signed out.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user (may be null).
  static User? get currentUser => _auth.currentUser;

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  /// Full Google flow: Google account picker → send the **raw Google ID token**
  /// to the backend (which verifies it against Google and mints the
  /// ChitraVision JWT) → cache the profile. Returns the backend user profile,
  /// or `null` if the user cancelled the account picker.
  ///
  /// Firebase signs the user in too (so sign-out / auth state stay coherent),
  /// but the token sent to the backend is the Google token, not Firebase's —
  /// the backend verifies Google tokens via `google-auth-library`.
  static Future<Map<String, dynamic>?> signInWithGoogleBackend() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final googleIdToken = googleAuth.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw 'Google Sign-In failed. Please try again.';
    }

    try {
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleIdToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    }

    final user = await ApiService.signInWithGoogle(idToken: googleIdToken);
    final prefs = await SharedPreferences.getInstance();
    if (user['name'] != null) {
      await prefs.setString('profile_name', user['name'].toString());
    }
    if (user['email'] != null) {
      await prefs.setString('profile_email', user['email'].toString());
    }
    return user;
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await ApiService.clearSession();
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _friendlyError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }
}
