// Authentication related constants and configurations
class AuthConfig {
  /// Google OAuth Client ID, injected at build time via:
  ///   `flutter build web --dart-define=GOOGLE_CLIENT_ID=<value>`
  ///
  /// In CI, set the GOOGLE_CLIENT_ID GitHub Actions secret.
  /// For local development, pass it directly or use a launch configuration.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  // Password validation rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  // Session timeout (in minutes)
  static const int sessionTimeout = 60;
}

/// Authentication method used to sign in
enum AuthProvider { email, google, guest }

/// Result of an authentication operation
enum AuthResult {
  success,
  failed,
  cancelled,
  networkError,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  userNotFound,
  tooManyRequests,
}

/// User authentication state
enum AuthState { unknown, authenticated, unauthenticated, loading }
