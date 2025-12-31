import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing theme mode preference
const _themeModeKey = 'theme_mode';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// ThemeMode notifier for managing theme state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  /// Load theme mode from SharedPreferences
  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final modeString = prefs.getString(_themeModeKey);
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set to light mode
  Future<void> setLightMode() async => setThemeMode(ThemeMode.light);

  /// Set to dark mode
  Future<void> setDarkMode() async => setThemeMode(ThemeMode.dark);

  /// Set to system mode
  Future<void> setSystemMode() async => setThemeMode(ThemeMode.system);

  /// Convert ThemeMode to string for storage
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Provider for theme mode state notifier
///
/// Must be overridden with a valid SharedPreferences instance at app startup.
final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  throw UnimplementedError(
    'themeModeNotifierProvider must be overridden with SharedPreferences',
  );
});

/// Convenience provider for checking if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeNotifierProvider);
  switch (themeMode) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
      // This would need platform brightness, return false as fallback
      return false;
  }
});

/// Enum for theme selection in UI
enum ThemeSelection {
  light(ThemeMode.light, 'Light'),
  dark(ThemeMode.dark, 'Dark'),
  system(ThemeMode.system, 'System');

  final ThemeMode mode;
  final String label;

  const ThemeSelection(this.mode, this.label);

  static ThemeSelection fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return ThemeSelection.light;
      case ThemeMode.dark:
        return ThemeSelection.dark;
      case ThemeMode.system:
        return ThemeSelection.system;
    }
  }
}
