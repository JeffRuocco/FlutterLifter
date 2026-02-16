import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/auth_config.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';

// ------------------------------------------------------------------
// Auth Service provider
// ------------------------------------------------------------------

/// Provides the [AuthService] backed by Firebase Auth.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

// ------------------------------------------------------------------
// Firebase auth-state stream
// ------------------------------------------------------------------

/// Reactive stream of the Firebase [User] (null = signed out).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ------------------------------------------------------------------
// Auth notifier (main auth state machine)
// ------------------------------------------------------------------

/// Manages the app-level [AuthState] and auth operations.
///
/// Guest mode is tracked locally without any Firebase call.
class AuthNotifier extends Notifier<AuthState> {
  bool _isGuest = false;

  @override
  AuthState build() {
    final asyncUser = ref.watch(authStateChangesProvider);

    return asyncUser.when(
      data: (user) {
        if (user != null) {
          _isGuest = false;
          return AuthState.authenticated;
        }
        // Preserve guest state across rebuilds
        return _isGuest ? AuthState.authenticated : AuthState.unauthenticated;
      },
      loading: () => AuthState.loading,
      error: (_, _) => AuthState.unauthenticated,
    );
  }

  /// Whether the current session is guest mode (no Firebase account).
  bool get isGuest => _isGuest;

  /// Enter guest mode — sets state to authenticated without Firebase.
  void continueAsGuest() {
    _isGuest = true;
    state = AuthState.authenticated;
  }

  /// Sign in with email and password.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    state = AuthState.loading;
    final result = await ref
        .read(authServiceProvider)
        .signInWithEmail(email, password);
    if (result != AuthResult.success) {
      state = AuthState.unauthenticated;
    }
    return result;
  }

  /// Register with email and password.
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = AuthState.loading;
    final result = await ref
        .read(authServiceProvider)
        .signUpWithEmail(email, password, displayName: displayName);
    if (result != AuthResult.success) {
      state = AuthState.unauthenticated;
    }
    return result;
  }

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle() async {
    state = AuthState.loading;
    final result = await ref.read(authServiceProvider).signInWithGoogle();
    if (result != AuthResult.success) {
      state = AuthState.unauthenticated;
    }
    return result;
  }

  /// Sign out (Firebase + Google + clear guest flag).
  Future<void> signOut() async {
    _isGuest = false;
    await ref.read(authServiceProvider).signOut();
    state = AuthState.unauthenticated;
  }
}

/// Provider for auth state and operations.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ------------------------------------------------------------------
// Current user (derived)
// ------------------------------------------------------------------

/// Provides the current [AppUser] or null when unauthenticated.
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState != AuthState.authenticated) return null;

  final notifier = ref.read(authNotifierProvider.notifier);
  if (notifier.isGuest) return AppUser.guest();

  final firebaseUser = ref.watch(authStateChangesProvider).value;
  if (firebaseUser == null) return null;

  return AppUser(
    uid: firebaseUser.uid,
    email: firebaseUser.email,
    displayName: firebaseUser.displayName,
    photoURL: firebaseUser.photoURL,
    authProvider: _inferProvider(firebaseUser),
    createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
  );
});

/// Convenience provider: `true` when the current user is a guest.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isGuest ?? false;
});

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

/// Infers [AuthProvider] from a Firebase [User].
AuthProvider _inferProvider(User user) {
  for (final info in user.providerData) {
    if (info.providerId == 'google.com') return AuthProvider.google;
  }
  return AuthProvider.email;
}
