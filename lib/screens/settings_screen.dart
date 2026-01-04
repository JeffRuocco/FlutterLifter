import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_lifter/core/theme/preset_themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/custom_theme_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../services/logging_service.dart';
import '../widgets/common/theme_preview_card.dart';
import '../widgets/common/theme_selection_sheet.dart';

/// Main settings screen accessible from home page
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _debugModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsAsync = await ref.read(appSettingsServiceProvider.future);
      final debugMode = await settingsAsync.isDebugModeEnabled();

      setState(() {
        _debugModeEnabled = debugMode;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Failed to load settings', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDebugMode(bool enabled) async {
    try {
      final settingsAsync = await ref.read(appSettingsServiceProvider.future);
      await settingsAsync.setDebugModeEnabled(enabled);

      setState(() {
        _debugModeEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Debug mode ${enabled ? 'enabled' : 'disabled'} from main settings');

      if (mounted) {
        if (enabled) {
          showSuccessMessage(context, 'Debug mode enabled');
        } else {
          showWarningMessage(context, 'Debug mode disabled');
        }
      }
    } catch (e) {
      LoggingService.error('Failed to toggle debug mode', e);
      if (mounted) {
        showErrorMessage(context, 'Failed to update debug mode setting');
      }
    }
  }

  void _openDebugSettings() {
    LoggingService.logUserAction('Opened debug settings from main settings');
    context.push(AppRoutes.debugSettings).then((_) {
      // Refresh settings when returning
      _loadSettings();
    });
  }

  void _openWidgetGallery() {
    LoggingService.logUserAction('Opened widget gallery from settings');
    context.push(AppRoutes.widgetGallery);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: AppLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  _buildSectionTitle(context, 'Appearance'),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: context.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadiusSmall),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedPaintBrush01,
                                  color: context.primaryColor,
                                  size: AppDimensions.iconMedium,
                                ),
                              ),
                              HSpace.md(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Theme',
                                      style: AppTextStyles.titleMedium),
                                  Text(
                                    'Choose your preferred appearance',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          VSpace.md(),
                          SegmentedButton<ThemeSelection>(
                            segments: ThemeSelection.values.map((selection) {
                              return ButtonSegment<ThemeSelection>(
                                value: selection,
                                label: Text(selection.label),
                                icon: HugeIcon(
                                  icon: _getThemeIcon(selection),
                                  color: context.onSurface,
                                  size: 18,
                                ),
                              );
                            }).toList(),
                            selected: {ThemeSelection.fromThemeMode(themeMode)},
                            onSelectionChanged: (selection) {
                              themeNotifier.setThemeMode(selection.first.mode);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  VSpace.md(),

                  // Custom Theme Section
                  _buildCustomThemeSection(context, ref),

                  VSpace.lg(),

                  // App Settings Section
                  _buildSectionTitle(context, 'App Settings'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedNotification01,
                      title: 'Notifications',
                      subtitle: 'Workout reminders and updates',
                      onTap: () {
                        showInfoMessage(
                            context, 'Notification settings coming soon');
                      },
                    ),
                    Divider(height: 1, color: context.outlineColor),
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedCloud,
                      title: 'Backup & Sync',
                      subtitle: 'Cloud backup and synchronization',
                      onTap: () {
                        showInfoMessage(context, 'Backup settings coming soon');
                      },
                    ),
                  ]),

                  VSpace.lg(),

                  // Privacy & Security Section
                  _buildSectionTitle(context, 'Privacy & Security'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedSecurityCheck,
                      title: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () {
                        showInfoMessage(context, 'Privacy policy coming soon');
                      },
                    ),
                    Divider(height: 1, color: context.outlineColor),
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedFileExport,
                      title: 'Data Export',
                      subtitle: 'Export your workout data',
                      onTap: () {
                        showInfoMessage(context, 'Data export coming soon');
                      },
                    ),
                  ]),

                  VSpace.lg(),

                  // Developer Options Section
                  _buildSectionTitle(context, 'Developer Options'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                      border: Border.all(
                        color: context.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedAlert01,
                              color: context.warningColor,
                              size: 20,
                            ),
                            HSpace.sm(),
                            Text(
                              'Developer Mode',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.warningColor,
                              ),
                            ),
                          ],
                        ),
                        VSpace.sm(),
                        Text(
                          'Enable debug features and logging tools. Only enable if you need to troubleshoot issues or are developing the app.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VSpace.sm(),
                  _buildSettingsCard(context, [
                    AppSwitchTile(
                      icon: HugeIcons.strokeRoundedCodeSquare,
                      title: 'Enable Debug Mode',
                      subtitle:
                          'Show debug buttons and enable developer features',
                      value: _debugModeEnabled,
                      onChanged: _toggleDebugMode,
                    ),
                    if (_debugModeEnabled) ...[
                      Divider(height: 1, color: context.outlineColor),
                      _buildSettingsTile(
                        context,
                        icon: HugeIcons.strokeRoundedBug01,
                        title: 'Debug Tools',
                        subtitle: 'Advanced logging and debugging tools',
                        onTap: _openDebugSettings,
                      ),
                      Divider(height: 1, color: context.outlineColor),
                      _buildSettingsTile(
                        context,
                        icon: HugeIcons.strokeRoundedDashboardSquare01,
                        title: 'Widget Gallery',
                        subtitle: 'Preview all UI components',
                        onTap: _openWidgetGallery,
                      ),
                    ],
                  ]),

                  VSpace.lg(),

                  // About Section
                  _buildSectionTitle(context, 'About'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      title: 'App Version',
                      subtitle: '1.0.0+1',
                      showChevron: false,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: context.outlineColor),
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {
                        showInfoMessage(context, 'Help & support coming soon');
                      },
                    ),
                  ]),

                  VSpace.xxl(),
                ],
              ),
            ),
    );
  }

  IconData _getThemeIcon(ThemeSelection selection) {
    switch (selection) {
      case ThemeSelection.light:
        return HugeIcons.strokeRoundedSun01;
      case ThemeSelection.dark:
        return HugeIcons.strokeRoundedMoon01;
      case ThemeSelection.system:
        return HugeIcons.strokeRoundedSmartPhone01;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return AppCard(
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: context.primaryColor,
        size: AppDimensions.iconMedium,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: showChevron
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: context.textSecondary,
              size: AppDimensions.iconMedium,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildCustomThemeSection(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(customThemeNotifierProvider);
    final activeTheme = themeState.activeTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.secondaryColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusSmall),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedColors,
                    color: context.secondaryColor,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                HSpace.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Color Theme', style: AppTextStyles.titleMedium),
                      Text(
                        activeTheme?.name ?? 'Default',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeTheme != null)
                  ThemeColorSwatch(
                    primaryColor: activeTheme.primaryColor,
                    secondaryColor: activeTheme.secondaryColor,
                    size: 24,
                  ),
              ],
            ),
            VSpace.md(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showThemeSelection(context, ref),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedPaintBrush01,
                      color: context.primaryColor,
                      size: 18,
                    ),
                    label: const Text('Browse Themes'),
                  ),
                ),
                HSpace.sm(),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.goToThemeEditor(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: ColorUtils.getContrastingTextColor(
                          context.primaryColor),
                      size: 18,
                    ),
                    label: const Text('Create New'),
                  ),
                ),
              ],
            ),
            if (activeTheme != PresetThemes.defaultTheme) ...[
              VSpace.sm(),
              Center(
                child: TextButton(
                  onPressed: () => _resetToDefaultTheme(ref),
                  child: Text(
                    'Reset to Default',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showThemeSelection(BuildContext context, WidgetRef ref) {
    showThemeSelectionSheet(
      context: context,
      ref: ref,
      onCreateNew: () => context.goToThemeEditor(),
      onEditTheme: () {
        final activeTheme = ref.read(customThemeNotifierProvider).activeTheme;
        if (activeTheme != null && !activeTheme.isPreset) {
          context.goToThemeEditor(editThemeId: activeTheme.id);
        }
      },
    );
  }

  Future<void> _resetToDefaultTheme(WidgetRef ref) async {
    await ref.read(customThemeNotifierProvider.notifier).resetToDefault();
  }
}
