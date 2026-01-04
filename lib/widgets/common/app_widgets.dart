import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_extensions.dart';

// ============================================
// APP CARD
// ============================================

/// Card style variants
enum AppCardStyle {
  /// Standard elevated card with shadow
  elevated,

  /// Card with subtle border outline
  outlined,

  /// Filled card with solid background
  filled,

  /// Glassmorphism card with blur effect
  glass,

  /// Gradient background card
  gradient,
}

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;
  final AppCardStyle style;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;
  final bool enableHaptics;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
    this.style = AppCardStyle.elevated,
    this.gradientColors,
    this.borderRadius,
    this.enableHaptics = true,
  });

  /// Factory for elevated card (default)
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.enableHaptics = true,
  })  : style = AppCardStyle.elevated,
        gradientColors = null;

  /// Factory for outlined card
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.enableHaptics = true,
  })  : style = AppCardStyle.outlined,
        elevation = 0,
        gradientColors = null;

  /// Factory for filled card
  const AppCard.filled({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.enableHaptics = true,
  })  : style = AppCardStyle.filled,
        elevation = 0,
        gradientColors = null;

  /// Factory for glass card
  const AppCard.glass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.enableHaptics = true,
  })  : style = AppCardStyle.glass,
        color = null,
        elevation = 0,
        gradientColors = null;

  /// Factory for gradient card
  const AppCard.gradient({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradientColors,
    this.borderRadius,
    this.enableHaptics = true,
  })  : style = AppCardStyle.gradient,
        color = null,
        elevation = 0;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(AppDimensions.cardBorderRadius);

    final scaleValue = _isPressed ? 0.98 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.diagonal3Values(scaleValue, scaleValue, 1.0),
      transformAlignment: Alignment.center,
      margin: widget.margin ?? const EdgeInsets.all(AppSpacing.sm),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: _buildCard(context, effectiveRadius),
      ),
    );
  }

  Widget _buildCard(BuildContext context, BorderRadius borderRadius) {
    switch (widget.style) {
      case AppCardStyle.elevated:
        return _buildElevatedCard(context, borderRadius);
      case AppCardStyle.outlined:
        return _buildOutlinedCard(context, borderRadius);
      case AppCardStyle.filled:
        return _buildFilledCard(context, borderRadius);
      case AppCardStyle.glass:
        return _buildGlassCard(context, borderRadius);
      case AppCardStyle.gradient:
        return _buildGradientCard(context, borderRadius);
    }
  }

  Widget _buildElevatedCard(BuildContext context, BorderRadius borderRadius) {
    final isDark = context.isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.color ??
            (isDark
                ? AppColors.surfaceContainerHighDark
                : context.surfaceColor),
        borderRadius: borderRadius,
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariantDark
              : AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.08),
            blurRadius: _isPressed ? 4 : 12,
            offset: Offset(0, _isPressed ? 2 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedCard(BuildContext context, BorderRadius borderRadius) {
    final isDark = context.isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.color ??
            (isDark
                ? AppColors.surfaceContainerHighDark
                : context.surfaceColor),
        borderRadius: borderRadius,
        border: Border.all(
          color: _isPressed
              ? context.primaryColor.withValues(alpha: 0.5)
              : (isDark
                  ? AppColors.outlineVariantDark
                  : context.outlineVariant),
          width: _isPressed ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildFilledCard(BuildContext context, BorderRadius borderRadius) {
    final isDark = context.isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.color ??
            (isDark
                ? AppColors.surfaceContainerHighestDark
                : context.surfaceVariant),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, BorderRadius borderRadius) {
    final isDark = context.isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color:
                isDark ? AppColors.glassShadowDark : AppColors.glassShadowLight,
            blurRadius: _isPressed ? 8 : 16,
            offset: Offset(0, _isPressed ? 2 : 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : [
                        Color.lerp(Colors.white, context.primaryColor, 0.04)!
                            .withValues(alpha: 0.9),
                        Color.lerp(
                                Colors.white, context.primaryContainer, 0.06)!
                            .withValues(alpha: 0.75),
                      ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : context.primaryColor.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientCard(BuildContext context, BorderRadius borderRadius) {
    final colors = widget.gradientColors ?? context.primaryGradient;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: _isPressed ? 0.2 : 0.3),
            blurRadius: _isPressed ? 8 : 16,
            offset: Offset(0, _isPressed ? 2 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ============================================
// APP BUTTON
// ============================================

/// Button style variants
enum AppButtonType {
  /// Standard elevated button with shadow
  elevated,

  /// Outlined button with border
  outlined,

  /// Text-only button
  text,

  /// Icon-only button (circular)
  icon,

  /// Pill-shaped button with rounded ends
  pill,

  /// Gradient background button
  gradient,
}

class AppButton extends StatefulWidget {
  final String? text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final AppButtonType type;
  final bool enableHaptics;
  final List<Color>? gradientColors;
  final double? width;
  final double? height;
  final bool expanded;

  const AppButton({
    super.key,
    this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.type = AppButtonType.elevated,
    this.enableHaptics = true,
    this.gradientColors,
    this.width,
    this.height,
    this.expanded = false,
  });

  /// Factory for elevated button
  const AppButton.elevated({
    super.key,
    required String this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.width,
    this.height,
    this.expanded = false,
  })  : type = AppButtonType.elevated,
        gradientColors = null;

  /// Factory for outlined button
  const AppButton.outlined({
    super.key,
    required String this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.width,
    this.height,
    this.expanded = false,
  })  : type = AppButtonType.outlined,
        gradientColors = null;

  /// Factory for text button
  const AppButton.text({
    super.key,
    required String this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.width,
    this.height,
    this.expanded = false,
  })  : type = AppButtonType.text,
        gradientColors = null;

  /// Factory for icon-only button
  const AppButton.icon({
    super.key,
    required Widget this.icon,
    this.onPressed,
    this.style,
    this.isLoading = false,
    this.enableHaptics = true,
    this.width,
    this.height,
  })  : type = AppButtonType.icon,
        text = null,
        expanded = false,
        gradientColors = null;

  /// Factory for pill button
  const AppButton.pill({
    super.key,
    required String this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.width,
    this.height,
    this.expanded = false,
  })  : type = AppButtonType.pill,
        gradientColors = null;

  /// Factory for gradient button
  const AppButton.gradient({
    super.key,
    required String this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.gradientColors,
    this.width,
    this.height,
    this.expanded = false,
  }) : type = AppButtonType.gradient;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _shimmerController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case AppButtonType.elevated:
        return _buildElevatedButton(context);
      case AppButtonType.outlined:
        return _buildOutlinedButton(context);
      case AppButtonType.text:
        return _buildTextButton(context);
      case AppButtonType.icon:
        return _buildIconButton(context);
      case AppButtonType.pill:
        return _buildPillButton(context);
      case AppButtonType.gradient:
        return _buildGradientButton(context);
    }
  }

  Widget _buildLoadingIndicator({Color? color}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? ColorUtils.getContrastingTextColor(context.primaryColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Positioned.fill(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: [
                  _shimmerController.value - 0.3,
                  _shimmerController.value,
                  _shimmerController.value + 0.3,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _wrapWithExpanded(Widget child) {
    if (widget.expanded) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: child,
      );
    }
    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }
    return child;
  }

  Widget _buildElevatedButton(BuildContext context) {
    Widget child = widget.isLoading
        ? _buildLoadingIndicator()
        : Text(widget.text ?? '', style: AppTextStyles.buttonText);

    final button = widget.icon != null && !widget.isLoading
        ? ElevatedButton.icon(
            onPressed: _handleTap,
            style: widget.style,
            icon: widget.icon!,
            label: child,
          )
        : ElevatedButton(
            onPressed: widget.isLoading ? null : _handleTap,
            style: widget.style,
            child: child,
          );

    return _wrapWithExpanded(button);
  }

  Widget _buildOutlinedButton(BuildContext context) {
    Widget child = widget.isLoading
        ? _buildLoadingIndicator(color: context.primaryColor)
        : Text(widget.text ?? '', style: AppTextStyles.buttonText);

    final button = widget.icon != null && !widget.isLoading
        ? OutlinedButton.icon(
            onPressed: _handleTap,
            style: widget.style,
            icon: widget.icon!,
            label: child,
          )
        : OutlinedButton(
            onPressed: widget.isLoading ? null : _handleTap,
            style: widget.style,
            child: child,
          );

    return _wrapWithExpanded(button);
  }

  Widget _buildTextButton(BuildContext context) {
    Widget child = widget.isLoading
        ? _buildLoadingIndicator(color: context.primaryColor)
        : Text(widget.text ?? '', style: AppTextStyles.buttonText);

    final button = widget.icon != null && !widget.isLoading
        ? TextButton.icon(
            onPressed: _handleTap,
            style: widget.style,
            icon: widget.icon!,
            label: child,
          )
        : TextButton(
            onPressed: widget.isLoading ? null : _handleTap,
            style: widget.style,
            child: child,
          );

    return _wrapWithExpanded(button);
  }

  Widget _buildIconButton(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : _handleTap,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: widget.isLoading
                ? _buildLoadingIndicator(color: context.primaryColor)
                : widget.icon,
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton(BuildContext context) {
    return _wrapWithExpanded(
      ElevatedButton(
        onPressed: widget.isLoading ? null : _handleTap,
        style: (widget.style ?? ElevatedButton.styleFrom()).copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null && !widget.isLoading) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            widget.isLoading
                ? _buildLoadingIndicator()
                : Text(widget.text ?? '', style: AppTextStyles.buttonText),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context) {
    final colors = widget.gradientColors ?? context.primaryGradient;
    return _wrapWithExpanded(
      Stack(
        children: [
          Container(
            height: widget.height ?? 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : _handleTap,
                borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null && !widget.isLoading) ...[
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      widget.isLoading
                          ? _buildLoadingIndicator()
                          : Text(
                              widget.text ?? '',
                              style: AppTextStyles.buttonText.copyWith(
                                color: ColorUtils.getContrastingTextColor(
                                    context.primaryColor),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isLoading) _buildShimmerOverlay(),
        ],
      ),
    );
  }
}

// ============================================
// OTHER COMMON WIDGETS
// ============================================

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

// ============================================
// SPACING WIDGETS
// ============================================

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

/// Vertical spacing widget
class VSpace extends AppSpacingWidget {
  const VSpace.xs({super.key}) : super.vertical(AppSpacing.xs);
  const VSpace.sm({super.key}) : super.vertical(AppSpacing.sm);
  const VSpace.md({super.key}) : super.vertical(AppSpacing.md);
  const VSpace.lg({super.key}) : super.vertical(AppSpacing.lg);
  const VSpace.xl({super.key}) : super.vertical(AppSpacing.xl);
  const VSpace.xxl({super.key}) : super.vertical(AppSpacing.xxl);
  const VSpace(super.size, {super.key}) : super.vertical();
}

/// Horizontal spacing widget
class HSpace extends AppSpacingWidget {
  const HSpace.xs({super.key}) : super.horizontal(AppSpacing.xs);
  const HSpace.sm({super.key}) : super.horizontal(AppSpacing.sm);
  const HSpace.md({super.key}) : super.horizontal(AppSpacing.md);
  const HSpace.lg({super.key}) : super.horizontal(AppSpacing.lg);
  const HSpace.xl({super.key}) : super.horizontal(AppSpacing.xl);
  const HSpace.xxl({super.key}) : super.horizontal(AppSpacing.xxl);
  const HSpace(super.size, {super.key}) : super.horizontal();
}

// ============================================
// APP SWITCH TILE
// ============================================

/// A reusable switch list tile widget with consistent styling.
///
/// Use this widget for toggle settings throughout the application.
/// It provides a consistent look with an icon, title, subtitle, and switch.
class AppSwitchTile extends StatelessWidget {
  /// The icon to display on the left side of the tile.
  final IconData icon;

  /// The color of the icon. Defaults to primary color.
  final Color? iconColor;

  /// The main title text.
  final String title;

  /// The subtitle/description text.
  final String subtitle;

  /// The current value of the switch.
  final bool value;

  /// Called when the switch is toggled.
  final ValueChanged<bool>? onChanged;

  /// Whether the tile is enabled. When false, the tile is grayed out.
  final bool enabled;

  const AppSwitchTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = enabled
        ? (iconColor ?? context.primaryColor)
        : context.textSecondary.withValues(alpha: 0.5);

    return SwitchListTile(
      secondary: HugeIcon(
        icon: icon,
        color: effectiveIconColor,
        size: AppDimensions.iconMedium,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: enabled ? context.textPrimary : context.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: enabled
              ? context.textSecondary
              : context.textSecondary.withValues(alpha: 0.5),
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

// ============================================
// SNACKBAR HELPERS
// ============================================

/// Shows a success snackbar message
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

/// Shows an error snackbar message
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

/// Shows a warning snackbar message
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

/// Shows an info snackbar message
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
