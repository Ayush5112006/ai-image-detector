import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralised authentication service.
/// Wraps Firebase Auth + Google Sign-In so screens stay thin.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // ── Sign Out ────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
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
