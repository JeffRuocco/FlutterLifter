import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/color_utils.dart';
import '../../models/custom_theme.dart';

/// A preview card showing how a theme looks with sample colors and text
class ThemePreviewCard extends StatelessWidget {
  /// The theme to preview
  final CustomTheme? theme;

  /// Primary color to preview (overrides theme if provided)
  final Color? primaryColor;

  /// Secondary color to preview (overrides theme if provided)
  final Color? secondaryColor;

  /// Whether to show dark mode preview
  final bool isDarkMode;

  /// Whether this preview is selected
  final bool isSelected;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Whether to show an expanded preview with more details
  final bool expanded;

  const ThemePreviewCard({
    super.key,
    this.theme,
    this.primaryColor,
    this.secondaryColor,
    this.isDarkMode = false,
    this.isSelected = false,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? theme?.primaryColor ?? Colors.blue;
    final secondary = secondaryColor ?? theme?.secondaryColor ?? Colors.teal;

    final backgroundColor =
        isDarkMode ? AppColors.surfaceDark : AppColors.surface;
    final surfaceColor = isDarkMode
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainer;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF212121);
    final secondaryTextColor =
        isDarkMode ? Colors.white70 : const Color(0xFF616161);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDarkMode
                    ? const Color(0xFF404040)
                    : const Color(0xFFCED4DA)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppDimensions.cardBorderRadius - 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color swatches header
              _buildColorHeader(primary, secondary),

              // Content preview
              Padding(
                padding:
                    EdgeInsets.all(expanded ? AppSpacing.md : AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sample headline
                    Text(
                      theme?.name ?? 'Custom Theme',
                      style: (expanded
                              ? AppTextStyles.titleMedium
                              : AppTextStyles.titleSmall)
                          .copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (expanded) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sample body text to preview readability',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSampleButton(primary, textColor, surfaceColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorHeader(Color primary, Color secondary) {
    return SizedBox(
      height: expanded ? 48 : 32,
      child: Row(
        children: [
          Expanded(
            child: Container(color: primary),
          ),
          Expanded(
            child: Container(color: secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleButton(
      Color primary, Color textColor, Color surfaceColor) {
    return Row(
      children: [
        // Primary button preview
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: primary,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
          child: Text(
            'Button',
            style: AppTextStyles.labelMedium.copyWith(
              color: ColorUtils.getContrastingTextColor(primary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Secondary button preview
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: primary),
          ),
          child: Text(
            'Outlined',
            style: AppTextStyles.labelMedium.copyWith(color: primary),
          ),
        ),
      ],
    );
  }
}

/// A compact color swatch showing primary and secondary colors
class ThemeColorSwatch extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const ThemeColorSwatch({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size,
      child: Stack(
        children: [
          // Secondary color (behind)
          Positioned(
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Primary color (in front)
          Positioned(
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row showing contrast information between two colors
class ContrastIndicator extends StatelessWidget {
  final Color foreground;
  final Color background;
  final bool showLabel;

  const ContrastIndicator({
    super.key,
    required this.foreground,
    required this.background,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = ContrastUtils.getContrastLevel(foreground, background);
    final ratio = ContrastUtils.formatContrastRatio(foreground, background);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: level.indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            '$ratio (${level.label})',
            style: AppTextStyles.labelSmall.copyWith(
              color: level.indicatorColor,
            ),
          ),
        ],
      ],
    );
  }
}
