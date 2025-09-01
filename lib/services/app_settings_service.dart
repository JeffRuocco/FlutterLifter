import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing application settings and preferences
class AppSettingsService {
  static const String _debugLoggingKey = 'debug_logging_enabled';
  static const String _debugModeKey = 'debug_mode_enabled';

  late SharedPreferences _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if debug logging is enabled
  Future<bool> isDebugLoggingEnabled() async {
    return _prefs.getBool(_debugLoggingKey) ?? false;
  }

  /// Enable or disable debug logging
  Future<void> setDebugLoggingEnabled(bool enabled) async {
    await _prefs.setBool(_debugLoggingKey, enabled);
  }

  /// Check if debug mode is enabled in app settings
  Future<bool> isDebugModeEnabled() async {
    return _prefs.getBool(_debugModeKey) ?? false;
  }

  /// Enable or disable debug mode in app settings
  Future<void> setDebugModeEnabled(bool enabled) async {
    await _prefs.setBool(_debugModeKey, enabled);
  }

  /// Clear all settings (useful for testing)
  Future<void> clearSettings() async {
    await _prefs.clear();
  }
}
