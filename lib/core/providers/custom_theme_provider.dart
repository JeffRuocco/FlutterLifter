import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/theme_repository.dart';
import '../../models/custom_theme.dart';
import '../theme/app_theme.dart';
import '../theme/preset_themes.dart';

/// Provider for the theme repository
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  throw UnimplementedError(
    'themeRepositoryProvider must be overridden with SharedPreferences',
  );
});

/// Provider for the custom theme state notifier
final customThemeNotifierProvider =
    NotifierProvider<CustomThemeNotifier, CustomThemeState>(
      CustomThemeNotifier.new,
    );

/// Provider for getting dynamic ThemeData based on custom theme
final dynamicLightThemeProvider = Provider<ThemeData>((ref) {
  final customThemeState = ref.watch(customThemeNotifierProvider);
  final activeTheme = customThemeState.activeTheme ?? PresetThemes.defaultTheme;

  return AppTheme.buildTheme(
    Brightness.light,
    primary: activeTheme.primaryColor,
    secondary: activeTheme.secondaryColor,
  );
});

/// Provider for getting dynamic dark ThemeData based on custom theme
final dynamicDarkThemeProvider = Provider<ThemeData>((ref) {
  final customThemeState = ref.watch(customThemeNotifierProvider);
  final activeTheme = customThemeState.activeTheme ?? PresetThemes.defaultTheme;

  return AppTheme.buildTheme(
    Brightness.dark,
    primary: activeTheme.primaryColor,
    secondary: activeTheme.secondaryColor,
  );
});

/// Notifier for managing custom theme state
class CustomThemeNotifier extends Notifier<CustomThemeState> {
  late ThemeRepository _repository;

  @override
  CustomThemeState build() {
    // Will be overridden with proper repository
    throw UnimplementedError(
      'customThemeNotifierProvider must be overridden with ThemeRepository',
    );
  }

  /// Initialize the notifier with repository
  void init(ThemeRepository repository) {
    _repository = repository;
    _loadInitialState();
  }

  /// Loads the initial state from repository
  Future<void> _loadInitialState() async {
    try {
      final customThemes = await _repository.getCustomThemes();
      final activeThemeId = await _repository.getActiveThemeId();

      CustomTheme? activeTheme;
      if (activeThemeId != null) {
        activeTheme = await _repository.getThemeById(activeThemeId);
      }
      // Default to the Default preset if no theme is set
      activeTheme ??= PresetThemes.defaultTheme;

      state = state.copyWith(
        customThemes: customThemes,
        activeTheme: activeTheme,
        isLoading: false,
      );
    } catch (e) {
      // Even on error, set the default preset
      state = state.copyWith(
        activeTheme: PresetThemes.defaultTheme,
        isLoading: false,
      );
    }
  }

  /// Sets the active theme by ID
  Future<void> setActiveTheme(String? themeId) async {
    if (themeId == null) {
      await _repository.setActiveThemeId(null);
      state = state.copyWith(clearActiveTheme: true);
      return;
    }

    final theme = await _repository.getThemeById(themeId);
    if (theme != null) {
      await _repository.setActiveThemeId(themeId);
      state = state.copyWith(activeTheme: theme);
    }
  }

  /// Creates a new custom theme
  Future<void> createTheme(CustomTheme theme) async {
    await _repository.createCustomTheme(theme);
    final customThemes = await _repository.getCustomThemes();
    state = state.copyWith(customThemes: customThemes);
  }

  /// Creates and sets a new custom theme as active
  Future<void> createAndActivateTheme(CustomTheme theme) async {
    await createTheme(theme);
    await setActiveTheme(theme.id);
  }

  /// Updates an existing custom theme
  Future<void> updateTheme(CustomTheme theme) async {
    await _repository.updateCustomTheme(theme);
    final customThemes = await _repository.getCustomThemes();

    // If the updated theme is active, update the active theme reference
    CustomTheme? activeTheme = state.activeTheme;
    if (activeTheme?.id == theme.id) {
      activeTheme = theme;
    }

    state = state.copyWith(
      customThemes: customThemes,
      activeTheme: activeTheme,
    );
  }

  /// Deletes a custom theme
  Future<void> deleteTheme(String themeId) async {
    final wasActive = state.activeTheme?.id == themeId;
    await _repository.deleteCustomTheme(themeId);
    final customThemes = await _repository.getCustomThemes();

    if (wasActive) {
      // Fall back to default preset when deleting the active theme
      state = state.copyWith(
        customThemes: customThemes,
        activeTheme: PresetThemes.defaultTheme,
      );
    } else {
      state = state.copyWith(customThemes: customThemes);
    }
  }

  /// Resets to default preset theme
  Future<void> resetToDefault() async {
    await _repository.resetToDefault();
    state = state.copyWith(activeTheme: PresetThemes.defaultTheme);
  }

  /// Refreshes the theme list from repository
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadInitialState();
  }
}

/// Subclass that properly initializes with ThemeRepository
class _InitializedCustomThemeNotifier extends CustomThemeNotifier {
  final ThemeRepository _initRepository;

  _InitializedCustomThemeNotifier(this._initRepository);

  @override
  CustomThemeState build() {
    _repository = _initRepository;
    _loadInitialState();
    return CustomThemeState(presetThemes: PresetThemes.all, isLoading: true);
  }
}

/// Creates providers with the given SharedPreferences instance
List<dynamic> createThemeProviderOverrides(SharedPreferences prefs) {
  final repository = LocalThemeRepository(prefs);

  return [
    themeRepositoryProvider.overrideWithValue(repository),
    customThemeNotifierProvider.overrideWith(
      () => _InitializedCustomThemeNotifier(repository),
    ),
  ];
}
