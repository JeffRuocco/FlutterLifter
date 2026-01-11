/// App-wide configuration settings for development and production.
///
/// Toggle these settings to change app behavior during development.
class AppConfig {
  // ============================================
  // Storage Configuration
  // ============================================

  /// Controls which storage backend is used for data persistence.
  ///
  /// - [StorageMode.hive]: Persistent local storage using Hive (recommended for testing persistence)
  /// - [StorageMode.inMemory]: In-memory storage that resets on app restart (fast for UI development)
  ///
  /// **Change this value to switch storage modes during development.**
  static const StorageMode storageMode = StorageMode.hive;

  // ============================================
  // Mock Data Configuration
  // ============================================

  /// Whether to use mock/sample data for programs.
  ///
  /// When true, sample programs are available for testing.
  /// When false, the app starts with no programs (production-like).
  static const bool useMockProgramData = true;

  // ============================================
  // Debug Configuration
  // ============================================

  /// Whether to show debug information in the UI.
  static const bool showDebugInfo = false;

  /// Whether to log storage operations to console.
  static const bool logStorageOperations = false;
}

/// Storage backend mode for the app.
enum StorageMode {
  /// Persistent local storage using Hive.
  /// Data persists across app restarts.
  /// Uses IndexedDB on web, file-based storage on mobile/desktop.
  hive,

  /// In-memory storage that resets on app restart.
  /// Useful for rapid UI development without persisted state.
  /// Each app launch starts fresh.
  inMemory,
}
