import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/auth_config.dart';
import 'logging_service.dart';

/// Service wrapping Firebase Auth operations.
///
/// All authentication methods return [AuthResult] so callers can display
/// user-friendly error messages without leaking Firebase internals.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService(this._firebaseAuth, {GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of Firebase auth state changes (null = signed out).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _firebaseAuth.currentUser;

  // ------------------------------------------------------------------
  // Email / Password
  // ------------------------------------------------------------------

  /// Sign in with email and password.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      LoggingService.logUserAction('Signed in with email');
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      LoggingService.warning('Email sign-in failed: ${e.code}');
      return _mapFirebaseError(e.code);
    } catch (e) {
      LoggingService.error('Unexpected email sign-in error', e);
      return AuthResult.failed;
    }
  }

  /// Register a new user with email, password, and optional display name.
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      LoggingService.logUserAction('Signed up with email');
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      LoggingService.warning('Email sign-up failed: ${e.code}');
      return _mapFirebaseError(e.code);
    } catch (e) {
      LoggingService.error('Unexpected email sign-up error', e);
      return AuthResult.failed;
    }
  }

  // ------------------------------------------------------------------
  // Google Sign-In
  // ------------------------------------------------------------------

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker
        return AuthResult.cancelled;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      LoggingService.logUserAction('Signed in with Google');
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      LoggingService.warning('Google sign-in failed: ${e.code}');
      return _mapFirebaseError(e.code);
    } catch (e) {
      LoggingService.error('Unexpected Google sign-in error', e);
      return AuthResult.failed;
    }
  }

  // ------------------------------------------------------------------
  // Sign Out
  // ------------------------------------------------------------------

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      LoggingService.logUserAction('Signed out');
    } catch (e) {
      LoggingService.error('Sign-out error', e);
    }
  }

  // ------------------------------------------------------------------
  // Password Reset
  // ------------------------------------------------------------------

  /// Send a password-reset email.
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      LoggingService.logUserAction('Password reset email sent');
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      LoggingService.warning('Password reset failed: ${e.code}');
      return _mapFirebaseError(e.code);
    } catch (e) {
      LoggingService.error('Unexpected password-reset error', e);
      return AuthResult.failed;
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Maps Firebase error codes to application-level [AuthResult].
  AuthResult _mapFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AuthResult.invalidCredentials;
      case 'user-not-found':
        return AuthResult.userNotFound;
      case 'email-already-in-use':
        return AuthResult.emailAlreadyInUse;
      case 'weak-password':
        return AuthResult.weakPassword;
      case 'network-request-failed':
        return AuthResult.networkError;
      case 'too-many-requests':
        return AuthResult.tooManyRequests;
      case 'user-disabled':
      default:
        return AuthResult.failed;
    }
  }
}
