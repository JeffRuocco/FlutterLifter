import 'package:flutter/material.dart';
import '../../models/custom_theme.dart';

/// Built-in preset themes that users can choose from
/// These are read-only and cannot be modified or deleted
class PresetThemes {
  PresetThemes._();

  /// Default app theme (Coral/Teal)
  static final defaultTheme = CustomTheme.preset(
    id: 'preset_default',
    name: 'Default',
    primaryColor: const Color(0xFFFF6B4A), // Warm Coral
    secondaryColor: const Color(0xFF26A69A), // Teal
  );

  /// Ocean theme (Deep Blue/Cyan)
  static final oceanTheme = CustomTheme.preset(
    id: 'preset_ocean',
    name: 'Ocean',
    primaryColor: const Color(0xFF0077B6), // Deep Blue
    secondaryColor: const Color(0xFF00B4D8), // Cyan
  );

  /// Sunset theme (Orange/Pink)
  static final sunsetTheme = CustomTheme.preset(
    id: 'preset_sunset',
    name: 'Sunset',
    primaryColor: const Color(0xFFFF7B54), // Warm Orange
    secondaryColor: const Color(0xFFFF4081), // Pink
  );

  /// Forest theme (Green/Brown)
  static final forestTheme = CustomTheme.preset(
    id: 'preset_forest',
    name: 'Forest',
    primaryColor: const Color(0xFF2E7D32), // Forest Green
    secondaryColor: const Color(0xFF8D6E63), // Brown
  );

  /// Midnight theme (Deep Purple/Indigo)
  static final midnightTheme = CustomTheme.preset(
    id: 'preset_midnight',
    name: 'Midnight',
    primaryColor: const Color(0xFF5E35B1), // Deep Purple
    secondaryColor: const Color(0xFF3F51B5), // Indigo
  );

  /// Lavender theme (Purple/Rose)
  static final lavenderTheme = CustomTheme.preset(
    id: 'preset_lavender',
    name: 'Lavender',
    primaryColor: const Color(0xFF9C27B0), // Purple
    secondaryColor: const Color(0xFFE91E63), // Rose
  );

  /// Material 3 theme (Purple/Rose)
  static final material3Theme = CustomTheme.preset(
    id: 'preset_material3',
    name: 'Material 3',
    primaryColor: const Color(0xFF6750A4),
    secondaryColor: const Color(0xFF625B71),
  );

  /// Material 3 dark theme (Purple/Rose)
  static final material3DarkTheme = CustomTheme.preset(
    id: 'preset_material3_dark',
    name: 'Material 3 Dark',
    primaryColor: const Color(0xFFD0BCFF),
    secondaryColor: const Color(0xFFCCC2DC),
  );

  /// White and Gold theme (White/Gold)
  static final whiteAndGoldTheme = CustomTheme.preset(
    id: 'preset_white_and_gold',
    name: 'White and Gold',
    primaryColor: const Color.fromARGB(255, 255, 204, 0), // Gold
    secondaryColor: const Color(0xFFFFFFFF), // White
  );

  /// All preset themes
  static List<CustomTheme> get all => [
        defaultTheme,
        oceanTheme,
        sunsetTheme,
        forestTheme,
        midnightTheme,
        lavenderTheme,
        material3Theme,
        material3DarkTheme,
        whiteAndGoldTheme,
      ];

  /// Get a preset theme by ID
  static CustomTheme? getById(String id) {
    try {
      return all.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if an ID belongs to a preset theme
  static bool isPresetId(String id) => id.startsWith('preset_');
}
