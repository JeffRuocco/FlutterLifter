import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

/// Theme Extensions - Easy access to theme values throughout the app
extension AppThemeExtension on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);

  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;

  // PREFERRED: Use ColorScheme colors (automatically adapts to light/dark mode)
  /// Primary colors
  Color get primaryColor => colorScheme.primary;
  Color get primaryContainer => colorScheme.primaryContainer;
  Color get onPrimary => colorScheme.onPrimary;
  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;

  /// Secondary colors
  Color get secondaryColor => colorScheme.secondary;
  Color get secondaryContainer => colorScheme.secondaryContainer;
  Color get onSecondary => colorScheme.onSecondary;
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;

  /// Surface colors
  Color get surfaceColor => colorScheme.surface;
  Color get surfaceVariant => colorScheme.surfaceContainerHighest;
  Color get onSurface => colorScheme.onSurface;
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;

  /// Background colors (Material 3: background = surface)
  Color get backgroundColor => colorScheme.surface;
  Color get onBackground => colorScheme.onSurface;

  /// Border and outline colors
  Color get outlineColor => colorScheme.outline;
  Color get outlineVariant => colorScheme.outlineVariant;

  /// Error colors
  Color get errorColor => colorScheme.error;
  Color get onError => colorScheme.onError;
  Color get errorContainer => colorScheme.errorContainer;
  Color get onErrorContainer => colorScheme.onErrorContainer;

  /// Custom status colors (manually handled for light/dark mode)
  Color get successColor => isDarkMode
      ? AppColors.successLight // Lighter green for dark mode
      : AppColors.success; // Darker green for light mode

  Color get onSuccessColor => isDarkMode
      ? AppColors.onSuccessLight // Dark text on light background
      : AppColors.onSuccess; // Light text on dark background

  Color get warningColor => isDarkMode
      ? AppColors.warningLight // Lighter amber for dark mode
      : AppColors.warning; // Darker amber for light mode

  Color get onWarningColor => isDarkMode
      ? AppColors.onWarningLight // Dark text on light background
      : AppColors.onWarning; // Light text on dark background

  Color get infoColor => isDarkMode
      ? AppColors.infoLight // Lighter blue for dark mode
      : AppColors.info; // Darker blue for light mode

  Color get onInfoColor => isDarkMode
      ? AppColors.onInfoLight // Dark text on light background
      : AppColors.onInfo; // Light text on dark background

  /// Semantic text colors (use ColorScheme for better theming)
  Color get textPrimary => onSurface;
  Color get textSecondary => onSurfaceVariant;
  Color get textDisabled => onSurface.withValues(alpha: 0.38);

  /// Check if current theme is dark
  bool get isDarkMode => theme.brightness == Brightness.dark;
}

/// Custom Widgets for consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation ?? AppDimensions.cardElevation,
      margin: margin ?? const EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final AppButtonType type;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.type = AppButtonType.elevated,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(text, style: AppTextStyles.buttonText);

    switch (type) {
      case AppButtonType.elevated:
        return icon != null
            ? ElevatedButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              )
            : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              );
      case AppButtonType.outlined:
        return icon != null
            ? OutlinedButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              )
            : OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              );
      case AppButtonType.text:
        return icon != null
            ? TextButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              )
            : TextButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              );
    }
  }
}

enum AppButtonType { elevated, outlined, text }

class AppTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final bool isDense;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final void Function(PointerDownEvent)? onTapOutside;

  const AppTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.suffixText,
    this.isDense = false,
    this.inputFormatters,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      inputFormatters: inputFormatters,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textAlign: textAlign,
      obscureText: obscureText,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      onTapOutside: onTapOutside,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: isDense
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              )
            : null,
        isDense: isDense,
      ),
    );
  }
}

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? AppDimensions.iconMedium,
      height: size ?? AppDimensions.iconMedium,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? context.primaryColor,
        ),
        strokeWidth: strokeWidth ?? 2.0,
      ),
    );
  }
}

class AppSpacingWidget extends StatelessWidget {
  final double size;
  final bool isVertical;

  const AppSpacingWidget.vertical(this.size, {super.key}) : isVertical = true;
  const AppSpacingWidget.horizontal(this.size, {super.key})
      : isVertical = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isVertical ? null : size,
      height: isVertical ? size : null,
    );
  }
}

/// Quick spacing widgets
class VSpace extends AppSpacingWidget {
  const VSpace.xs({super.key}) : super.vertical(AppSpacing.xs);
  const VSpace.sm({super.key}) : super.vertical(AppSpacing.sm);
  const VSpace.md({super.key}) : super.vertical(AppSpacing.md);
  const VSpace.lg({super.key}) : super.vertical(AppSpacing.lg);
  const VSpace.xl({super.key}) : super.vertical(AppSpacing.xl);
  const VSpace.xxl({super.key}) : super.vertical(AppSpacing.xxl);
  const VSpace(super.size, {super.key}) : super.vertical();
}

class HSpace extends AppSpacingWidget {
  const HSpace.xs({super.key}) : super.horizontal(AppSpacing.xs);
  const HSpace.sm({super.key}) : super.horizontal(AppSpacing.sm);
  const HSpace.md({super.key}) : super.horizontal(AppSpacing.md);
  const HSpace.lg({super.key}) : super.horizontal(AppSpacing.lg);
  const HSpace.xl({super.key}) : super.horizontal(AppSpacing.xl);
  const HSpace.xxl({super.key}) : super.horizontal(AppSpacing.xxl);
  const HSpace(super.size, {super.key}) : super.horizontal();
}

/// Helper methods for showing themed status messages
void showSuccessMessage(BuildContext context, String message, {int? duration}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            color: context.onSuccessColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.onSuccessColor),
            ),
          ),
        ],
      ),
      backgroundColor: context.successColor,
      duration: Duration(seconds: duration ?? 4),
      showCloseIcon: true,
    ),
  );
}

void showErrorMessage(BuildContext context, String message, {int? duration}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCancelCircle,
            color: context.onError,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.onError),
              softWrap: true,
            ),
          ),
        ],
      ),
      backgroundColor: context.errorColor,
      duration: Duration(seconds: duration ?? 4),
      showCloseIcon: true,
    ),
  );
}

void showWarningMessage(BuildContext context, String message, {int? duration}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: context.onWarningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.onWarningColor),
            ),
          ),
        ],
      ),
      backgroundColor: context.warningColor,
      duration: Duration(seconds: duration ?? 4),
      showCloseIcon: true,
    ),
  );
}

void showInfoMessage(BuildContext context, String message, {int? duration}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: context.onInfoColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.onInfoColor),
            ),
          ),
        ],
      ),
      backgroundColor: context.infoColor,
      duration: Duration(seconds: duration ?? 4),
      showCloseIcon: true,
    ),
  );
}
