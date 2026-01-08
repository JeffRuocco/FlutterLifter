// Authentication related constants and configurations
class AuthConfig {
  // TODO: Replace with your actual configuration values
  static const String googleClientId = 'your-google-client-id';
  static const String facebookAppId = 'your-facebook-app-id';

  // Password validation rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  // Session timeout (in minutes)
  static const int sessionTimeout = 60;
}

// Authentication result types
enum AuthResult { success, failed, cancelled, networkError, invalidCredentials }

// User authentication state
enum AuthState { unknown, authenticated, unauthenticated, loading }
