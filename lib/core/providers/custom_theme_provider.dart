import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/theme_repository.dart';
import '../../models/custom_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/preset_themes.dart';

/// Provider for the theme repository
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  throw UnimplementedError(
    'themeRepositoryProvider must be overridden with SharedPreferences',
  );
});

/// Provider for the custom theme state notifier
final customThemeNotifierProvider =
    StateNotifierProvider<CustomThemeNotifier, CustomThemeState>((ref) {
  throw UnimplementedError(
    'customThemeNotifierProvider must be overridden with ThemeRepository',
  );
});

/// Provider for getting dynamic ThemeData based on custom theme
final dynamicLightThemeProvider = Provider<ThemeData>((ref) {
  final customThemeState = ref.watch(customThemeNotifierProvider);
  final activeTheme = customThemeState.activeTheme ?? PresetThemes.defaultTheme;

  return _buildThemeData(activeTheme, Brightness.light);
});

/// Provider for getting dynamic dark ThemeData based on custom theme
final dynamicDarkThemeProvider = Provider<ThemeData>((ref) {
  final customThemeState = ref.watch(customThemeNotifierProvider);
  final activeTheme = customThemeState.activeTheme ?? PresetThemes.defaultTheme;

  return _buildThemeData(activeTheme, Brightness.dark);
});

/// Builds a ThemeData from a CustomTheme
ThemeData _buildThemeData(CustomTheme customTheme, Brightness brightness) {
  final colorScheme = ColorUtils.generateColorScheme(
    primary: customTheme.primaryColor,
    secondary: customTheme.secondaryColor,
    brightness: brightness,
  );

  final baseTheme =
      brightness == Brightness.light ? AppTheme.lightTheme : AppTheme.darkTheme;

  final isDark = brightness == Brightness.dark;

  return baseTheme.copyWith(
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    // Update component themes that use primary/secondary colors
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: baseTheme.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    // Input decoration with custom focused border color
    inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    // Bottom navigation with custom selected color
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor:
          isDark ? AppColors.surfaceContainerDark : colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: isDark ? Colors.white54 : AppColors.textSecondary,
    ),
    // Chip theme with custom selected color
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? AppColors.surfaceContainerHighDark
          : AppColors.surfaceVariant,
      selectedColor: colorScheme.primary,
      disabledColor: isDark ? AppColors.surfaceContainerDark : AppColors.border,
      labelStyle: isDark
          ? AppTextStyles.labelMedium.copyWith(color: Colors.white)
          : AppTextStyles.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
    ),
  );
}

/// StateNotifier for managing custom theme state
class CustomThemeNotifier extends StateNotifier<CustomThemeState> {
  final ThemeRepository _repository;

  CustomThemeNotifier(this._repository)
      : super(CustomThemeState(
          presetThemes: PresetThemes.all,
          isLoading: true,
        )) {
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

/// Creates providers with the given SharedPreferences instance
List<Override> createThemeProviderOverrides(SharedPreferences prefs) {
  final repository = LocalThemeRepository(prefs);

  return [
    themeRepositoryProvider.overrideWithValue(repository),
    customThemeNotifierProvider.overrideWith(
      (ref) => CustomThemeNotifier(repository),
    ),
  ];
}
