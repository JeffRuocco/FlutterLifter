import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/accessibility_provider.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';

/// A gradient button with animated effects
class GradientButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;
  final double? width;
  final double height;
  final bool isLoading;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradientColors,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  ConsumerState<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends ConsumerState<GradientButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  List<Color> _getColors(BuildContext context) =>
      widget.gradientColors ?? context.primaryGradient;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final colors = _getColors(context);

    Widget button = GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()
          ..setEntry(0, 0, _isPressed ? 0.97 : 1.0)
          ..setEntry(1, 1, _isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? colors
                : colors.map((c) => c.withValues(alpha: 0.5)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: widget.borderRadius ??
              BorderRadius.circular(AppDimensions.borderRadiusMedium),
          boxShadow: isEnabled && !_isPressed
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
            onTap: widget.onPressed,
            splashColor:
                ColorUtils.getContrastingTextColor(context.primaryColor)
                    .withValues(alpha: 0.2),
            highlightColor:
                ColorUtils.getContrastingTextColor(context.primaryColor)
                    .withValues(alpha: 0.1),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: context.onPrimary,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: context.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    // Add entrance animation if motion is allowed
    if (!reduceMotion) {
      button = button
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .scaleXY(
            begin: 0.95,
            end: 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          );
    }

    return button;
  }
}

/// A secondary outline button variant
class GradientOutlineButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final double? width;
  final double height;
  final bool isLoading;
  final BorderRadius? borderRadius;

  const GradientOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.borderColor,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  ConsumerState<GradientOutlineButton> createState() =>
      _GradientOutlineButtonState();
}

class _GradientOutlineButtonState extends ConsumerState<GradientOutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveBorderColor =
        widget.borderColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()
          ..setEntry(0, 0, _isPressed ? 0.97 : 1.0)
          ..setEntry(1, 1, _isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed
              ? effectiveBorderColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: widget.borderRadius ??
              BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: isEnabled
                ? effectiveBorderColor
                : effectiveBorderColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
            onTap: widget.onPressed,
            splashColor: effectiveBorderColor.withValues(alpha: 0.2),
            highlightColor: effectiveBorderColor.withValues(alpha: 0.1),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveBorderColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: effectiveBorderColor,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: effectiveBorderColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
