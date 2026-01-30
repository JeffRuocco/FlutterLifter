import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_lifter/core/theme/preset_themes.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
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
import '../services/backup_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';
// dart:typed_data not needed after switching to file_selector

import 'package:file_selector/file_selector.dart';
import '../utils/web_file_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
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
        'Debug mode ${enabled ? 'enabled' : 'disabled'} from main settings',
      );

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
                                  color: context.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.borderRadiusSmall,
                                  ),
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
                                  Text(
                                    'Theme',
                                    style: AppTextStyles.titleMedium,
                                  ),
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
                          context,
                          'Notification settings coming soon',
                        );
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
                  VSpace.lg(),

                  // Import / Export Section
                  _buildSectionTitle(context, 'Import & Export'),
                  _buildSettingsCard(context, [
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedFileExport,
                      title: 'Export Data',
                      subtitle: 'Export your local data to a ZIP file',
                      onTap: () async {
                        await _handleExport();
                      },
                    ),
                    Divider(height: 1, color: context.outlineColor),
                    _buildSettingsTile(
                      context,
                      icon: HugeIcons.strokeRoundedFolderOpen,
                      title: 'Import Data',
                      subtitle: 'Import a previously exported ZIP backup',
                      onTap: () async {
                        await _handleImport();
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
                        AppDimensions.borderRadiusMedium,
                      ),
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

  HugeIconData _getThemeIcon(ThemeSelection selection) {
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
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return AppCard(child: Column(children: children));
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required HugeIconData icon,
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
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSmall,
                    ),
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
                        context.primaryColor,
                      ),
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

  Future<void> _handleExport() async {
    try {
      final bytes = await BackupService.exportBackup();
      final suggestedName =
          'flutterlifter_backup_${DateTime.now().toIso8601String()}.zip'
              .replaceAll(':', '-');

      String? savePath;
      try {
        // Ask user to pick a directory and save file there. Some versions of
        // `file_selector` may not provide a direct save dialog, so we pick a
        // directory and write the suggested filename into it.
        final dirPath = await getDirectoryPath();
        if (dirPath != null && dirPath.isNotEmpty) {
          savePath = '$dirPath/$suggestedName';
        } else {
          savePath = null;
        }
      } on MissingPluginException {
        // Desktop or test environment may not have a registered file selector;
        // fall back to saving in the application documents directory or temp.
        try {
          final dir = await getApplicationDocumentsDirectory();
          savePath = '${dir.path}/$suggestedName';
        } on MissingPluginException {
          final dir = Directory.systemTemp.createTempSync(
            'flutterlifter_export_',
          );
          savePath = '${dir.path}/$suggestedName';
        }
      }

      if (kIsWeb) {
        // If a path was somehow provided on web, still trigger browser download.
        await downloadFileInBrowser(bytes, suggestedName);
        if (mounted) showSuccessMessage(context, 'Download started');
        return;
      } else if (savePath == null || savePath.isEmpty) {
        if (mounted) showInfoMessage(context, 'Export cancelled');
        return;
      }

      final file = File(savePath);
      await file.writeAsBytes(bytes);
      LoggingService.logUserAction('Exported backup to ${file.path}');
      if (mounted) showSuccessMessage(context, 'Export saved to ${file.path}');
    } catch (e, st) {
      LoggingService.logDataError('ui', 'export', e, stackTrace: st);
      if (mounted) showErrorMessage(context, 'Failed to export data');
    }
  }

  Future<void> _handleImport() async {
    try {
      final typeGroup = XTypeGroup(label: 'zip', extensions: ['zip']);
      final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();

      final result = await BackupService.importBackup(bytes);
      if (result.containsKey('error')) {
        if (mounted) {
          showErrorMessage(context, 'Import failed: ${result['error']}');
        }
        return;
      }

      final errors = (result['errors'] as List<dynamic>?) ?? [];
      if (errors.isEmpty) {
        if (mounted) {
          showSuccessMessage(context, 'Import completed successfully');
        }
      } else {
        if (mounted) {
          showWarningMessage(
            context,
            'Import completed with ${errors.length} errors',
          );
        }
      }
    } catch (e, st) {
      LoggingService.logDataError('ui', 'import', e, stackTrace: st);
      if (mounted) showErrorMessage(context, 'Failed to import backup');
    }
  }
}
