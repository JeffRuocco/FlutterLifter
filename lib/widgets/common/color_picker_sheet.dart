import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/color_utils.dart';
import '../../core/theme/theme_extensions.dart';

/// Shows a bottom sheet with a color picker
/// Returns the selected color or null if cancelled
Future<Color?> showColorPickerSheet({
  required BuildContext context,
  required Color initialColor,
  String title = 'Select Color',
  Color? contrastAgainst,
}) async {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ColorPickerSheet(
      initialColor: initialColor,
      title: title,
      contrastAgainst: contrastAgainst,
    ),
  );
}

/// Bottom sheet widget for picking colors
class ColorPickerSheet extends StatefulWidget {
  final Color initialColor;
  final String title;
  final Color? contrastAgainst;

  const ColorPickerSheet({
    super.key,
    required this.initialColor,
    this.title = 'Select Color',
    this.contrastAgainst,
  });

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late Color _selectedColor;
  bool _showContrastWarning = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _checkContrast();
  }

  void _checkContrast() {
    if (widget.contrastAgainst != null) {
      final meetsAA = ContrastUtils.meetsWCAGAA(
        _selectedColor,
        widget.contrastAgainst!,
      );
      setState(() {
        _showContrastWarning = !meetsAA;
      });
    }
  }

  void _onColorChanged(Color color) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedColor = color;
    });
    _checkContrast();
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedColor);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusXLarge),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.outlineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  widget.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Color preview
                _buildColorPreview(context),
                const SizedBox(height: AppSpacing.md),

                // Contrast warning
                if (_showContrastWarning) ...[
                  _buildContrastWarning(context),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Color picker
                ColorPicker(
                  color: _selectedColor,
                  onColorChanged: _onColorChanged,
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  spacing: 8,
                  runSpacing: 8,
                  wheelDiameter: 220,
                  wheelWidth: 20,
                  wheelSquarePadding: 12,
                  wheelSquareBorderRadius: 8,
                  wheelHasBorder: true,
                  heading: null,
                  subheading: Text(
                    'Shade',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  wheelSubheading: Text(
                    'Adjust color',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  showMaterialName: false,
                  showColorName: false,
                  showColorCode: true,
                  colorCodeHasColor: true,
                  copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                    copyButton: true,
                    pasteButton: true,
                    longPressMenu: true,
                  ),
                  pickersEnabled: const <ColorPickerType, bool>{
                    ColorPickerType.wheel: true,
                    ColorPickerType.accent: false,
                    ColorPickerType.primary: true,
                    ColorPickerType.custom: false,
                    ColorPickerType.customSecondary: false,
                  },
                  pickerTypeLabels: const <ColorPickerType, String>{
                    ColorPickerType.wheel: 'Wheel',
                    ColorPickerType.primary: 'Material',
                  },
                  actionButtons: const ColorPickerActionButtons(
                    okButton: false,
                    closeButton: false,
                    dialogActionButtons: false,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        child: const Text('Select'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(BuildContext context) {
    return Row(
      children: [
        // Old color
        Expanded(
          child: Column(
            children: [
              Text(
                'Current',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: widget.initialColor,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: context.outlineColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Arrow
        HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          color: context.textSecondary,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.md),
        // New color
        Expanded(
          child: Column(
            children: [
              Text(
                'New',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: context.outlineColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContrastWarning(BuildContext context) {
    final ratio = ContrastUtils.formatContrastRatio(
      _selectedColor,
      widget.contrastAgainst!,
    );
    final level = ContrastUtils.getContrastLevel(
      _selectedColor,
      widget.contrastAgainst!,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(
          color: context.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: context.warningColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Contrast',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ratio: $ratio (${level.label})',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.warningColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A button that shows the current color and opens the picker when tapped
class ColorPickerButton extends StatelessWidget {
  final Color color;
  final String label;
  final ValueChanged<Color> onColorChanged;
  final Color? contrastAgainst;

  const ColorPickerButton({
    super.key,
    required this.color,
    required this.label,
    required this.onColorChanged,
    this.contrastAgainst,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final newColor = await showColorPickerSheet(
          context: context,
          initialColor: color,
          title: 'Select $label',
          contrastAgainst: contrastAgainst,
        );
        if (newColor != null) {
          onColorChanged(newColor);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Row(
          children: [
            // Color swatch
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusSmall,
                ),
                border: Border.all(color: context.outlineColor),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Label and color code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  Text(
                    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            // Contrast indicator
            if (contrastAgainst != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _buildContrastDot(color, contrastAgainst!),
              ),
            // Edit icon
            HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              color: context.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContrastDot(Color foreground, Color background) {
    final level = ContrastUtils.getContrastLevel(foreground, background);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: level.indicatorColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
