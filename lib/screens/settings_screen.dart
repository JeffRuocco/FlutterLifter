import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/providers/accessibility_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_provider.dart';
import '../core/theme/theme_utils.dart';
import '../services/logging_service.dart';

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
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  _buildSectionTitle(context, 'Appearance'),
                  AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(AppSpacing.sm),
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

                  // Accessibility Section
                  _buildSettingsCard(context, [
                    Consumer(
                      builder: (context, ref, child) {
                        final accessibilityState =
                            ref.watch(accessibilityNotifierProvider);
                        final accessibilityNotifier =
                            ref.read(accessibilityNotifierProvider.notifier);

                        return SwitchListTile(
                          secondary: HugeIcon(
                            icon: HugeIcons.strokeRoundedSlowWinds,
                            color: context.primaryColor,
                            size: AppDimensions.iconMedium,
                          ),
                          title: const Text('Reduce Motion'),
                          subtitle: const Text(
                            'Minimize animations for accessibility',
                          ),
                          value: accessibilityState.reduceMotion,
                          onChanged: (value) {
                            accessibilityNotifier.setReduceMotion(value);
                            if (value) {
                              showInfoMessage(context, 'Animations reduced');
                            } else {
                              showInfoMessage(context, 'Animations enabled');
                            }
                          },
                        );
                      },
                    ),
                  ]),

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
                    padding: EdgeInsets.all(AppSpacing.md),
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
                    SwitchListTile(
                      secondary: HugeIcon(
                        icon: HugeIcons.strokeRoundedCodeSquare,
                        color: context.primaryColor,
                        size: AppDimensions.iconMedium,
                      ),
                      title: const Text('Enable Debug Mode'),
                      subtitle: const Text(
                          'Show debug buttons and enable developer features'),
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
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
}
