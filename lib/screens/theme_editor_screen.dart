import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/custom_theme_provider.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/color_utils.dart';
import '../core/theme/preset_themes.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../models/custom_theme.dart';
import '../widgets/common/color_picker_sheet.dart';
import '../widgets/common/theme_preview_card.dart';

/// Screen for creating or editing a custom theme
class ThemeEditorScreen extends ConsumerStatefulWidget {
  /// If provided, edit this theme; otherwise create a new one
  final String? editThemeId;

  const ThemeEditorScreen({
    super.key,
    this.editThemeId,
  });

  @override
  ConsumerState<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends ConsumerState<ThemeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Color? _primaryColor;
  Color? _secondaryColor;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _colorsInitialized = false;
  CustomTheme? _existingTheme;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editThemeId != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_colorsInitialized) {
      _initializeColors();
      _colorsInitialized = true;
    }

    if (_isEditing && _existingTheme == null) {
      _loadExistingTheme();
    }
  }

  void _initializeColors() {
    // Use active theme colors as the starting point for new themes
    final themeState = ref.read(customThemeNotifierProvider);
    final activeTheme = themeState.activeTheme ?? PresetThemes.defaultTheme;
    _primaryColor = activeTheme.primaryColor;
    _secondaryColor = activeTheme.secondaryColor;
  }

  void _loadExistingTheme() {
    final themeState = ref.read(customThemeNotifierProvider);
    final theme = themeState.allThemes.firstWhere(
      (t) => t.id == widget.editThemeId,
      orElse: () => PresetThemes.defaultTheme,
    );

    setState(() {
      _existingTheme = theme;
      _nameController.text = theme.name;
      _primaryColor = theme.primaryColor;
      _secondaryColor = theme.secondaryColor;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveThem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(customThemeNotifierProvider.notifier);

      if (_isEditing && _existingTheme != null) {
        // Update existing theme
        final updatedTheme = _existingTheme!.copyWith(
          name: _nameController.text.trim(),
          primaryColor: _primaryColor!,
          secondaryColor: _secondaryColor!,
        );
        await notifier.updateTheme(updatedTheme);

        if (mounted) {
          showSuccessMessage(context, 'Theme updated');
          context.pop();
        }
      } else {
        // Create new theme
        final newTheme = CustomTheme.create(
          name: _nameController.text.trim(),
          primaryColor: _primaryColor!,
          secondaryColor: _secondaryColor!,
        );
        await notifier.createAndActivateTheme(newTheme);

        if (mounted) {
          showSuccessMessage(context, 'Theme created and applied');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to save theme');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate contrast using current theme's surface color
    final surfaceColor = context.surfaceColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Theme' : 'Create Theme'),
        centerTitle: true,
        actions: [
          if (_isEditing && _existingTheme?.isPreset == false)
            IconButton(
              onPressed: _confirmDelete,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: context.errorColor,
                size: 24,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Theme name
              _buildSectionTitle('Theme Name'),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter a name for your theme',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a theme name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Colors section
              _buildSectionTitle('Colors'),
              const SizedBox(height: AppSpacing.sm),

              // Primary color picker
              ColorPickerButton(
                color: _primaryColor!,
                label: 'Primary Color',
                onColorChanged: (color) {
                  HapticFeedback.selectionClick();
                  setState(() => _primaryColor = color);
                },
                contrastAgainst: surfaceColor,
              ),

              const SizedBox(height: AppSpacing.md),

              // Secondary color picker
              ColorPickerButton(
                color: _secondaryColor!,
                label: 'Secondary Color',
                onColorChanged: (color) {
                  HapticFeedback.selectionClick();
                  setState(() => _secondaryColor = color);
                },
                contrastAgainst: surfaceColor,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Preview section
              _buildSectionTitle('Preview'),
              const SizedBox(height: AppSpacing.sm),

              // Light/Dark mode toggle
              _buildModeToggle(context),
              const SizedBox(height: AppSpacing.md),

              // Theme preview
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Light Mode',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ThemePreviewCard(
                          primaryColor: _primaryColor,
                          secondaryColor: _secondaryColor,
                          isDarkMode: false,
                          expanded: true,
                          theme: CustomTheme(
                            id: 'preview',
                            name: _nameController.text.isEmpty
                                ? 'Preview'
                                : _nameController.text,
                            primaryColor: _primaryColor!,
                            secondaryColor: _secondaryColor!,
                            createdAt: DateTime.now(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ThemePreviewCard(
                          primaryColor: _primaryColor,
                          secondaryColor: _secondaryColor,
                          isDarkMode: true,
                          expanded: true,
                          theme: CustomTheme(
                            id: 'preview',
                            name: _nameController.text.isEmpty
                                ? 'Preview'
                                : _nameController.text,
                            primaryColor: _primaryColor!,
                            secondaryColor: _secondaryColor!,
                            createdAt: DateTime.now(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Contrast info
              _buildContrastInfo(context, surfaceColor),

              const SizedBox(height: AppSpacing.xxl),

              // Save button
              AppButton.gradient(
                text: _isEditing ? 'Save Changes' : 'Create Theme',
                onPressed: _isSaving ? null : _saveThem,
                isLoading: _isSaving,
                expanded: true,
                gradientColors: [_primaryColor!, _secondaryColor!],
              ),

              const SizedBox(height: AppSpacing.md),

              // Cancel button
              AppButton.outlined(
                text: 'Cancel',
                onPressed: () => context.pop(),
                expanded: true,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Row(
      children: [
        Text(
          'Test in:',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode, size: 16),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode, size: 16),
            ),
          ],
          selected: {
            themeMode == ThemeMode.system ? ThemeMode.light : themeMode
          },
          onSelectionChanged: (selection) {
            themeNotifier.setThemeMode(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildContrastInfo(BuildContext context, Color surfaceColor) {
    final primaryContrast =
        ContrastUtils.getContrastLevel(_primaryColor!, surfaceColor);
    final secondaryContrast =
        ContrastUtils.getContrastLevel(_secondaryColor!, surfaceColor);

    return AppCard.outlined(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedEye,
                color: context.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Accessibility',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContrastRow('Primary', _primaryColor!, primaryContrast),
          const SizedBox(height: AppSpacing.sm),
          _buildContrastRow('Secondary', _secondaryColor!, secondaryContrast),
          if (!primaryContrast.passesMinimum ||
              !secondaryContrast.passesMinimum) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Low contrast colors may be hard to see for some users.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.warningColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContrastRow(String label, Color color, ContrastLevel level) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: level.indicatorColor.withValues(alpha: 0.1),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
          child: Text(
            level.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: level.indicatorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content:
            Text('Are you sure you want to delete "${_existingTheme?.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref
          .read(customThemeNotifierProvider.notifier)
          .deleteTheme(_existingTheme!.id);

      if (mounted) {
        showSuccessMessage(context, 'Theme deleted');
        context.pop();
      }
    }
  }
}
