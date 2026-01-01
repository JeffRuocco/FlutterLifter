import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/custom_theme.dart';
import '../../core/theme/preset_themes.dart';

/// Repository for managing custom themes
/// Handles CRUD operations and persistence via SharedPreferences
abstract class ThemeRepository {
  /// Get all preset themes (read-only)
  List<CustomTheme> getPresetThemes();

  /// Get all user-created custom themes
  Future<List<CustomTheme>> getCustomThemes();

  /// Get the currently active theme ID (null for default)
  Future<String?> getActiveThemeId();

  /// Set the active theme by ID
  Future<void> setActiveThemeId(String? themeId);

  /// Get a theme by ID (searches both presets and custom)
  Future<CustomTheme?> getThemeById(String id);

  /// Create a new custom theme
  Future<void> createCustomTheme(CustomTheme theme);

  /// Update an existing custom theme
  Future<void> updateCustomTheme(CustomTheme theme);

  /// Delete a custom theme by ID
  Future<void> deleteCustomTheme(String themeId);

  /// Clear all custom themes
  Future<void> clearAllCustomThemes();

  /// Reset to default theme
  Future<void> resetToDefault();
}

/// Local implementation of ThemeRepository using SharedPreferences
class LocalThemeRepository implements ThemeRepository {
  final SharedPreferences _prefs;

  static const String _customThemesKey = 'custom_themes';
  static const String _activeThemeIdKey = 'active_theme_id';

  LocalThemeRepository(this._prefs);

  @override
  List<CustomTheme> getPresetThemes() {
    return PresetThemes.all;
  }

  @override
  Future<List<CustomTheme>> getCustomThemes() async {
    final jsonString = _prefs.getString(_customThemesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => CustomTheme.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  @override
  Future<String?> getActiveThemeId() async {
    return _prefs.getString(_activeThemeIdKey);
  }

  @override
  Future<void> setActiveThemeId(String? themeId) async {
    if (themeId == null) {
      await _prefs.remove(_activeThemeIdKey);
    } else {
      await _prefs.setString(_activeThemeIdKey, themeId);
    }
  }

  @override
  Future<CustomTheme?> getThemeById(String id) async {
    // Check presets first
    final preset = PresetThemes.getById(id);
    if (preset != null) return preset;

    // Check custom themes
    final customThemes = await getCustomThemes();
    try {
      return customThemes.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createCustomTheme(CustomTheme theme) async {
    if (theme.isPreset) {
      throw ArgumentError('Cannot create a preset theme');
    }

    final customThemes = await getCustomThemes();

    // Check for duplicate ID
    if (customThemes.any((t) => t.id == theme.id)) {
      throw ArgumentError('Theme with ID ${theme.id} already exists');
    }

    customThemes.add(theme);
    await _saveCustomThemes(customThemes);
  }

  @override
  Future<void> updateCustomTheme(CustomTheme theme) async {
    if (theme.isPreset) {
      throw ArgumentError('Cannot update a preset theme');
    }

    final customThemes = await getCustomThemes();
    final index = customThemes.indexWhere((t) => t.id == theme.id);

    if (index == -1) {
      throw ArgumentError('Theme with ID ${theme.id} not found');
    }

    customThemes[index] = theme;
    await _saveCustomThemes(customThemes);
  }

  @override
  Future<void> deleteCustomTheme(String themeId) async {
    if (PresetThemes.isPresetId(themeId)) {
      throw ArgumentError('Cannot delete a preset theme');
    }

    final customThemes = await getCustomThemes();
    customThemes.removeWhere((t) => t.id == themeId);
    await _saveCustomThemes(customThemes);

    // If the deleted theme was active, clear active theme
    final activeId = await getActiveThemeId();
    if (activeId == themeId) {
      await setActiveThemeId(null);
    }
  }

  @override
  Future<void> clearAllCustomThemes() async {
    await _prefs.remove(_customThemesKey);

    // If active theme was custom, reset to default
    final activeId = await getActiveThemeId();
    if (activeId != null && !PresetThemes.isPresetId(activeId)) {
      await setActiveThemeId(null);
    }
  }

  @override
  Future<void> resetToDefault() async {
    await setActiveThemeId(PresetThemes.defaultTheme.id);
  }

  /// Saves the custom themes list to SharedPreferences
  Future<void> _saveCustomThemes(List<CustomTheme> themes) async {
    final jsonList = themes.map((t) => t.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs.setString(_customThemesKey, jsonString);
  }
}
