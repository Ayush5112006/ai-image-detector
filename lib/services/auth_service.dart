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

  /// Opens the Google account picker, authenticates with Firebase, and returns
  /// the [UserCredential].  Returns `null` if the user cancels the flow.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google account chooser
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      // Obtain the auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Build a Firebase credential from the tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  /// Full Google flow: Firebase Google auth → exchange the ID token for a
  /// ChitraVision backend JWT → cache the profile. Returns the backend user
  /// profile, or `null` if the user cancelled the account picker.
  static Future<Map<String, dynamic>?> signInWithGoogleBackend() async {
    final credential = await signInWithGoogle();
    if (credential == null) return null;

    final idToken = await credential.user!.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw 'Google Sign-In failed. Please try again.';
    }

    final user = await ApiService.signInWithGoogle(idToken: idToken);
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
