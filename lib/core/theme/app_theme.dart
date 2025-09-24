import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

/// Main theme configuration for FlutterLifter
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      cardTheme: _cardTheme,
      dividerTheme: _dividerTheme,
      snackBarTheme: _snackBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      chipTheme: _chipTheme,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarThemeDark,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationThemeDark,
      cardTheme: _cardThemeDark,
      dividerTheme: _dividerThemeDark,
      snackBarTheme: _snackBarTheme,
      bottomNavigationBarTheme: _bottomNavigationBarThemeDark,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      chipTheme: _chipThemeDark,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
    );
  }

  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryLight,
    surface: AppColors.surface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    error: AppColors.error,
    onPrimary: AppColors.onPrimary,
    onSecondary: AppColors.onSecondary,
    onSurface: AppColors.onSurface,
    onError: Colors.white,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryLight,
    primaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondaryLight,
    secondaryContainer: AppColors.secondaryDark,
    surface: AppColors.surfaceDark,
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    error: AppColors.error,
    onPrimary: AppColors.onPrimary,
    onSecondary: AppColors.onSecondary,
    onSurface: AppColors.onSurfaceLight,
    onError: Colors.white,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
  );

  // Text Theme
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

  // AppBar Theme
  static const AppBarTheme _appBarTheme = AppBarTheme(
    centerTitle: true,
    shadowColor: Colors.black26,
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.onSurface,
    titleTextStyle: AppTextStyles.titleLarge,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.surface,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  static const AppBarTheme _appBarThemeDark = AppBarTheme(
    centerTitle: true,
    shadowColor: Colors.black54,
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: Colors.white,
    titleTextStyle: AppTextStyles.titleLarge,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.surfaceDark,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Button Themes
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(88, AppDimensions.buttonHeightMedium),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      textStyle: AppTextStyles.buttonText,
      elevation: 1,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(88, AppDimensions.buttonHeightMedium),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      textStyle: AppTextStyles.buttonText,
      side: const BorderSide(color: AppColors.border),
    ),
  );

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

  // Input Decoration Theme
  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle:
        AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
  );

  static final InputDecorationTheme _inputDecorationThemeDark =
      InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
  );

  // Card Theme
  static final CardThemeData _cardTheme = CardThemeData(
    elevation: AppDimensions.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
    ),
    margin: const EdgeInsets.all(AppSpacing.sm),
  );

  static final CardThemeData _cardThemeDark = CardThemeData(
    elevation: AppDimensions.cardElevation,
    color: const Color(0xFF2C2C2C),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
    ),
    margin: const EdgeInsets.all(AppSpacing.sm),
  );

  // Other Component Themes
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.border,
    thickness: 1,
  );

  static const DividerThemeData _dividerThemeDark = DividerThemeData(
    color: Color(0xFF4A4A4A),
    thickness: 1,
  );

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
    ),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
  );

  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
  );

  static const BottomNavigationBarThemeData _bottomNavigationBarThemeDark =
      BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    backgroundColor: Color(0xFF2C2C2C),
    selectedItemColor: AppColors.primaryLight,
    unselectedItemColor: Colors.white54,
  );

  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(
    elevation: 4,
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
  );

  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.surfaceVariant,
    selectedColor: AppColors.primary,
    disabledColor: AppColors.border,
    labelStyle: AppTextStyles.labelMedium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
    ),
  );

  static final ChipThemeData _chipThemeDark = ChipThemeData(
    backgroundColor: const Color(0xFF4A4A4A),
    selectedColor: AppColors.primaryLight,
    disabledColor: const Color(0xFF2C2C2C),
    labelStyle: AppTextStyles.labelMedium.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusRound),
    ),
  );

  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.textSecondary;
    }),
  );

  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return null;
    }),
  );

  static final RadioThemeData _radioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return null;
    }),
  );

  static final SliderThemeData _sliderTheme = SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.border,
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withValues(alpha: 0.12),
  );
}
