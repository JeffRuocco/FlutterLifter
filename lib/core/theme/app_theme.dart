import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';
import 'color_utils.dart';

/// Main theme configuration for FlutterLifter.
///
/// ## Architecture
/// This class provides base ThemeData for light and dark modes.
/// Custom themes are applied on top via `custom_theme_provider.dart`.
///
/// ## Usage
/// ```dart
/// // In MaterialApp:
/// theme: AppTheme.lightTheme,
/// darkTheme: AppTheme.darkTheme,
/// ```
class AppTheme {
  AppTheme._();

  /// Default primary color (Warm Coral)
  static const Color defaultPrimary = Color(0xFFFF6B4A);

  /// Default secondary color (Teal)
  static const Color defaultSecondary = Color(0xFF26A69A);

  /// Light theme with default colors
  static ThemeData get lightTheme => buildTheme(Brightness.light);

  /// Dark theme with default colors
  static ThemeData get darkTheme => buildTheme(Brightness.dark);

  /// Build a theme with custom colors
  static ThemeData buildTheme(
    Brightness brightness, {
    Color primary = defaultPrimary,
    Color secondary = defaultSecondary,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(
      brightness: brightness,
      primary: primary,
      secondary: secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: _buildAppBarTheme(isDark, colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _buildInputDecorationTheme(isDark, colorScheme),
      cardTheme: _buildCardTheme(isDark),
      dividerTheme: _buildDividerTheme(isDark),
      snackBarTheme: _snackBarTheme,
      bottomNavigationBarTheme: _buildBottomNavTheme(isDark, colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      chipTheme: _buildChipTheme(isDark, colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }

  // ============================================
  // COLOR SCHEME
  // ============================================

  static ColorScheme _buildColorScheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
  }) {
    final isDark = brightness == Brightness.dark;

    // Generate complete color sets with proper contrast
    final primarySet = ColorUtils.getColorSet(primary, forDarkTheme: isDark);
    final secondarySet =
        ColorUtils.getColorSet(secondary, forDarkTheme: isDark);

    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        primaryContainer: primarySet.container,
        onPrimary: primarySet.onColor,
        onPrimaryContainer: primarySet.onContainer,
        secondary: secondary,
        secondaryContainer: secondarySet.container,
        onSecondary: secondarySet.onColor,
        onSecondaryContainer: secondarySet.onContainer,
        surface: AppColors.surfaceDark,
        surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
        surfaceContainerLow: AppColors.surfaceContainerLowDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerHigh: AppColors.surfaceContainerHighDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineVariantDark,
        error: AppColors.error,
        onError: Colors.white,
      );
    } else {
      return ColorScheme.light(
        primary: primary,
        primaryContainer: primarySet.container,
        onPrimary: primarySet.onColor,
        onPrimaryContainer: primarySet.onContainer,
        secondary: secondary,
        secondaryContainer: secondarySet.container,
        onSecondary: secondarySet.onColor,
        onSecondaryContainer: secondarySet.onContainer,
        surface: AppColors.surface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: Colors.white,
      );
    }
  }

  // ============================================
  // TEXT THEME
  // ============================================

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );

  // ============================================
  // COMPONENT THEMES
  // ============================================

  static AppBarTheme _buildAppBarTheme(bool isDark, ColorScheme colorScheme) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(
        color: colorScheme.onSurface,
      ),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
      ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, AppDimensions.buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        textStyle: AppTextStyles.buttonText,
        elevation: 1,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, AppDimensions.buttonHeightMedium),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        textStyle: AppTextStyles.buttonText,
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(88, AppDimensions.buttonHeightMedium),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      textStyle: AppTextStyles.buttonText,
    ),
  );

  static InputDecorationTheme _buildInputDecorationTheme(
      bool isDark, ColorScheme colorScheme) {
    final fillColor =
        isDark ? AppColors.surfaceContainerHighDark : AppColors.surface;
    final borderColor =
        isDark ? AppColors.outlineVariantDark : AppColors.outlineVariant;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textHintDark : AppColors.textHint,
      ),
    );
  }

  static CardThemeData _buildCardTheme(bool isDark) {
    return CardThemeData(
      elevation: AppDimensions.cardElevation,
      color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        side: BorderSide(
          color: isDark
              ? AppColors.outlineVariantDark
              : AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    );
  }

  static DividerThemeData _buildDividerTheme(bool isDark) {
    return DividerThemeData(
      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariant,
      thickness: 1,
    );
  }

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
    ),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
  );

  static BottomNavigationBarThemeData _buildBottomNavTheme(
      bool isDark, ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  static ChipThemeData _buildChipTheme(bool isDark, ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: isDark
          ? AppColors.surfaceContainerHighDark
          : AppColors.surfaceContainerHigh,
      selectedColor: colorScheme.primary,
      disabledColor:
          isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
      ),
    );
  }

  /// Builds the theme for Switch (button) widgets
  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha: 0.5);
        }
        return null;
      }),
      thumbIcon:
          WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return const Icon(Icons.close);
        }
        if (states.contains(WidgetState.selected)) {
          return const Icon(HugeIcons.strokeRoundedTick02);
        }
        return null;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
    );
  }

  static RadioThemeData _buildRadioTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
    );
  }

  static SliderThemeData _buildSliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.outlineVariant,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
    );
  }
}
