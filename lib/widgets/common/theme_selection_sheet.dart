import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/providers/custom_theme_provider.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_utils.dart';
import '../../models/custom_theme.dart';
import 'theme_preview_card.dart';

/// Shows a bottom sheet for selecting a theme
/// Returns the selected theme ID or null if cancelled
Future<String?> showThemeSelectionSheet({
  required BuildContext context,
  required WidgetRef ref,
  VoidCallback? onCreateNew,
  VoidCallback? onEditTheme,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ThemeSelectionSheet(
      onCreateNew: onCreateNew,
      onEditTheme: onEditTheme,
    ),
  );
}

/// Bottom sheet widget for selecting themes
class ThemeSelectionSheet extends ConsumerStatefulWidget {
  final VoidCallback? onCreateNew;
  final VoidCallback? onEditTheme;

  const ThemeSelectionSheet({
    super.key,
    this.onCreateNew,
    this.onEditTheme,
  });

  @override
  ConsumerState<ThemeSelectionSheet> createState() =>
      _ThemeSelectionSheetState();
}

class _ThemeSelectionSheetState extends ConsumerState<ThemeSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final themeState = ref.watch(customThemeNotifierProvider);
    final activeThemeId = themeState.activeTheme?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.borderRadiusXLarge),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Theme lists
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // Preset themes section
                    _buildSectionHeader(context, 'Default Themes'),
                    const SizedBox(height: AppSpacing.sm),
                    ...themeState.presetThemes.map((theme) => _buildThemeItem(
                          context,
                          theme,
                          isSelected: theme.id == activeThemeId,
                        )),

                    const SizedBox(height: AppSpacing.lg),

                    // Custom themes section
                    _buildSectionHeader(
                      context,
                      'My Themes',
                      trailing: _buildCreateButton(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (themeState.customThemes.isEmpty)
                      _buildEmptyCustomThemes(context)
                    else
                      ...themeState.customThemes.map((theme) => _buildThemeItem(
                            context,
                            theme,
                            isSelected: theme.id == activeThemeId,
                            canDelete: true,
                            canEdit: true,
                          )),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
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

          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Theme',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: context.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        widget.onCreateNew?.call();
      },
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedAdd01,
        color: context.primaryColor,
        size: 18,
      ),
      label: Text(
        'Create New',
        style: AppTextStyles.labelMedium.copyWith(
          color: context.primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyCustomThemes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedPaintBrush01,
            color: context.textSecondary,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No custom themes yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap "Create New" to design your own',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItem(
    BuildContext context,
    CustomTheme theme, {
    bool isSelected = false,
    bool canDelete = false,
    bool canEdit = false,
  }) {
    return Dismissible(
      key: Key(theme.id),
      direction:
          canDelete ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        return await _confirmDelete(context, theme);
      },
      onDismissed: (direction) => _deleteTheme(theme),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.errorColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: InkWell(
        onTap: () => _selectTheme(theme.id),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
            border: Border.all(
              color: isSelected ? context.primaryColor : context.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Theme preview mini card
              SizedBox(
                width: 80,
                child: ThemePreviewCard(
                  theme: theme,
                  isDarkMode: context.isDarkMode,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Theme info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (theme.isPreset)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  context.secondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusSmall,
                              ),
                            ),
                            child: Text(
                              'Preset',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: context.secondaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ThemeColorSwatch(
                      primaryColor: theme.primaryColor,
                      secondaryColor: theme.secondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
              // Edit button (for custom themes)
              if (canEdit)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onEditTheme?.call();
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit02,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
              // Selection indicator
              if (isSelected)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: context.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTheme(String? themeId) async {
    HapticFeedback.selectionClick();
    await ref
        .read(customThemeNotifierProvider.notifier)
        .setActiveTheme(themeId);
    if (mounted) {
      Navigator.of(context).pop(themeId);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, CustomTheme theme) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
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
    return result ?? false;
  }

  Future<void> _deleteTheme(CustomTheme theme) async {
    HapticFeedback.mediumImpact();
    await ref.read(customThemeNotifierProvider.notifier).deleteTheme(theme.id);
    if (mounted) {
      showSuccessMessage(context, 'Theme deleted');
    }
  }
}
