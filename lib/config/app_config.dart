/// App-wide configuration settings for development and production.
///
/// Toggle these settings to change app behavior during development.
/// All providers and repositories respect these settings automatically.
///
/// **Quick Reference:**
/// - Production:  storageMode=hive, useMockProgramData=false
/// - UI Dev:      storageMode=inMemory, useMockProgramData=true
/// - Persistence: storageMode=hive, useMockProgramData=false
class AppConfig {
  // ============================================
  // Storage Configuration
  // ============================================

  /// Controls which storage backend is used for ALL data persistence.
  ///
  /// - [StorageMode.hive]: Persistent local storage using Hive
  ///   - Programs, workout sessions, exercises persist across app restarts
  ///   - Uses IndexedDB on web, file-based storage on mobile/desktop
  ///   - **Recommended for production and testing persistence**
  ///
  /// - [StorageMode.inMemory]: In-memory storage that resets on app restart
  ///   - Fast startup, no persisted state between launches
  ///   - **Recommended for rapid UI development**
  ///
  /// **All repositories automatically respect this setting.**
  static const StorageMode storageMode = StorageMode.hive;

  // ============================================
  // Mock Data Configuration
  // ============================================

  /// Whether to use mock/sample data for programs.
  ///
  /// - `true`: Sample programs available for testing features
  /// - `false`: App starts with only default programs (production-like)
  ///
  /// Default programs (5x5, PPL, etc.) are always available regardless
  /// of this setting. This only affects additional mock/test data.
  static const bool useMockProgramData = false;

  // ============================================
  // Debug Configuration
  // ============================================

  /// Whether to show debug information in the UI.
  ///
  /// When enabled, displays debug overlays and diagnostic information.
  static const bool showDebugInfo = false;

  // ============================================
  // Feature Flags
  // ============================================

  /// Whether remote API syncing is enabled.
  ///
  /// When true, repositories will attempt to sync with remote APIs.
  /// Currently not implemented - always use false.
  static const bool enableRemoteSync = false;

  // ============================================
  // Computed Properties
  // ============================================

  /// Returns true if using persistent storage (Hive).
  static bool get isPersistentStorage => storageMode == StorageMode.hive;

  /// Returns true if using in-memory storage.
  static bool get isInMemoryStorage => storageMode == StorageMode.inMemory;

  /// Returns true if in development/debug mode.
  static bool get isDevelopmentMode =>
      showDebugInfo || useMockProgramData || isInMemoryStorage;
}

/// Storage backend mode for the app.
enum StorageMode {
  /// Persistent local storage using Hive.
  ///
  /// Data persists across app restarts:
  /// - Programs and custom modifications
  /// - Workout sessions and history
  /// - Exercises and user preferences
  /// - User settings
  ///
  /// Uses IndexedDB on web, file-based storage on mobile/desktop.
  hive,

  /// In-memory storage that resets on app restart.
  ///
  /// Useful for rapid UI development without persisted state.
  /// Each app launch starts fresh with default programs only.
  ///
  /// **Note:** Data is lost when the app is closed or restarted.
  inMemory,
}
