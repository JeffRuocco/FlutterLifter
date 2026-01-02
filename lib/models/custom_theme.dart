import 'package:flutter/material.dart';

/// Represents a custom theme with user-defined colors
/// Can be either a preset (read-only) or user-created theme
class CustomTheme {
  /// Unique identifier for the theme
  final String id;

  /// Display name for the theme
  final String name;

  /// Primary color used for main UI elements
  final Color primaryColor;

  /// Secondary color used for accents
  final Color secondaryColor;

  /// Whether this is a built-in preset theme (read-only)
  final bool isPreset;

  /// When the theme was created
  final DateTime createdAt;

  /// When the theme was last modified (null for presets)
  final DateTime? modifiedAt;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    this.isPreset = false,
    required this.createdAt,
    this.modifiedAt,
  });

  /// Creates a new user theme with auto-generated ID
  factory CustomTheme.create({
    required String name,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return CustomTheme(
      id: _generateId(),
      name: name,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      isPreset: false,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a preset theme (read-only)
  CustomTheme.preset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  })  : isPreset = true,
        createdAt = DateTime.fromMillisecondsSinceEpoch(0),
        modifiedAt = null;

  /// Generates a unique ID using timestamp and random hash
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (UniqueKey().hashCode & 0xFFFFFF).toRadixString(16);
    return 'theme_${timestamp}_$random';
  }

  /// Creates a CustomTheme from JSON
  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    return CustomTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      isPreset: json['isPreset'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
    );
  }

  /// Converts CustomTheme to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'isPreset': isPreset,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  /// Creates a copy with updated values
  CustomTheme copyWith({
    String? id,
    String? name,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isPreset,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTheme &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CustomTheme{id: $id, name: $name, isPreset: $isPreset}';
  }
}

/// Represents the current theme state for the app
class CustomThemeState {
  /// The currently active theme (null means default app theme)
  final CustomTheme? activeTheme;

  /// All available preset themes
  final List<CustomTheme> presetThemes;

  /// All user-created custom themes
  final List<CustomTheme> customThemes;

  /// Whether the theme system is loading
  final bool isLoading;

  const CustomThemeState({
    this.activeTheme,
    this.presetThemes = const [],
    this.customThemes = const [],
    this.isLoading = false,
  });

  /// All themes combined (presets first, then custom)
  List<CustomTheme> get allThemes => [...presetThemes, ...customThemes];

  /// Whether a custom theme is currently active
  bool get hasCustomTheme => activeTheme != null;

  /// Creates a copy with updated values
  CustomThemeState copyWith({
    CustomTheme? activeTheme,
    List<CustomTheme>? presetThemes,
    List<CustomTheme>? customThemes,
    bool? isLoading,
    bool clearActiveTheme = false,
  }) {
    return CustomThemeState(
      activeTheme: clearActiveTheme ? null : (activeTheme ?? this.activeTheme),
      presetThemes: presetThemes ?? this.presetThemes,
      customThemes: customThemes ?? this.customThemes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
