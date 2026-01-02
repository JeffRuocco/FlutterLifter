import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/providers/settings_provider.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_extensions.dart';
import '../widgets/common/app_widgets.dart';
import '../services/logging_service.dart';

/// Debug settings screen for development and troubleshooting
class DebugSettingsScreen extends ConsumerStatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  ConsumerState<DebugSettingsScreen> createState() =>
      _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends ConsumerState<DebugSettingsScreen> {
  bool _debugLoggingEnabled = false;
  bool _verboseLoggingEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsAsync = await ref.read(appSettingsServiceProvider.future);
      final debugLogging = await settingsAsync.isDebugLoggingEnabled();
      final verboseLogging = await settingsAsync.isVerboseLoggingEnabled();

      setState(() {
        _debugLoggingEnabled = debugLogging;
        _verboseLoggingEnabled = verboseLogging;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Failed to load debug settings', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDebugLogging(bool enabled) async {
    try {
      final settingsAsync = await ref.read(appSettingsServiceProvider.future);
      await settingsAsync.setDebugLoggingEnabled(enabled);
      await LoggingService.updateDebugLogging(enabled);

      setState(() {
        _debugLoggingEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Debug logging ${enabled ? 'enabled' : 'disabled'}');

      if (mounted) {
        if (enabled) {
          showSuccessMessage(context, 'Debug logging enabled');
        } else {
          showWarningMessage(context, 'Debug logging disabled');
        }
      }
    } catch (e) {
      LoggingService.error('Failed to toggle debug logging', e);
      if (mounted) {
        showErrorMessage(context, 'Failed to update debug logging setting');
      }
    }
  }

  Future<void> _toggleVerboseLogging(bool enabled) async {
    try {
      final settingsAsync = await ref.read(appSettingsServiceProvider.future);
      await settingsAsync.setVerboseLoggingEnabled(enabled);
      await LoggingService.updateVerboseLogging(enabled);

      setState(() {
        _verboseLoggingEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Verbose logging ${enabled ? 'enabled' : 'disabled'}');

      if (mounted) {
        if (enabled) {
          showSuccessMessage(context, 'Verbose logging enabled');
        } else {
          showWarningMessage(context, 'Verbose logging disabled');
        }
      }
    } catch (e) {
      LoggingService.error('Failed to toggle verbose logging', e);
      if (mounted) {
        showErrorMessage(context, 'Failed to update verbose logging setting');
      }
    }
  }

  void _clearLogs() {
    try {
      LoggingService.clearLogs();
      LoggingService.logUserAction('Logs cleared');

      if (mounted) {
        showSuccessMessage(context, 'Logs cleared successfully');
      }
    } catch (e) {
      LoggingService.error('Failed to clear logs', e);
      if (mounted) {
        showErrorMessage(context, 'Failed to clear logs');
      }
    }
  }

  void _exportLogs() {
    try {
      final logs = LoggingService.exportLogs();
      LoggingService.logUserAction('Logs exported');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exported Logs'),
          content: SingleChildScrollView(
            child: SelectableText(
              logs.isEmpty ? 'No logs available' : logs,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      LoggingService.error('Failed to export logs', e);
      if (mounted) {
        showErrorMessage(context, 'Failed to export logs');
      }
    }
  }

  void _openTalkerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TalkerScreen(
          talker: LoggingService.talker,
          theme: TalkerScreenTheme(
            backgroundColor: context.surfaceColor,
            textColor: context.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        centerTitle: true,
        backgroundColor: context.warningColor,
        foregroundColor: context.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: AppLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                              'Logging & Debug Tools',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.warningColor,
                              ),
                            ),
                          ],
                        ),
                        VSpace.sm(),
                        Text(
                          'Configure logging settings and access debugging tools. These tools help with troubleshooting and development.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  VSpace.lg(),

                  // App Info
                  _buildSectionTitle(context, 'App Information'),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _buildInfoRow(context, 'Debug Mode',
                              kDebugMode ? 'Enabled' : 'Disabled'),
                          _buildInfoRow(context, 'Total Logs',
                              '${LoggingService.logCount}'),
                          _buildInfoRow(context, 'Build Mode',
                              kReleaseMode ? 'Release' : 'Development'),
                        ],
                      ),
                    ),
                  ),

                  VSpace.lg(),

                  // Logging Settings
                  _buildSectionTitle(context, 'Logging Settings'),
                  AppCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: HugeIcon(
                            icon: HugeIcons.strokeRoundedBug01,
                            color: context.primaryColor,
                            size: AppDimensions.iconMedium,
                          ),
                          title: const Text('Debug Logging'),
                          subtitle: const Text(
                              'Enable debug level logging to console'),
                          value: _debugLoggingEnabled,
                          onChanged: _toggleDebugLogging,
                        ),
                        Divider(height: 1, color: context.outlineColor),
                        SwitchListTile(
                          secondary: HugeIcon(
                            icon: HugeIcons.strokeRoundedView,
                            color: context.primaryColor,
                            size: AppDimensions.iconMedium,
                          ),
                          title: const Text('Verbose Logging'),
                          subtitle: const Text(
                              'Enable verbose level logging (most detailed)'),
                          value: _verboseLoggingEnabled,
                          onChanged: _toggleVerboseLogging,
                        ),
                      ],
                    ),
                  ),

                  VSpace.lg(),

                  // Log Actions
                  _buildSectionTitle(context, 'Log Actions'),
                  AppCard(
                    child: Column(
                      children: [
                        _buildActionTile(
                          context,
                          icon: HugeIcons.strokeRoundedView,
                          title: 'View Logs',
                          subtitle: 'Open the log viewer screen',
                          onTap: _openTalkerScreen,
                        ),
                        Divider(height: 1, color: context.outlineColor),
                        _buildActionTile(
                          context,
                          icon: HugeIcons.strokeRoundedFileExport,
                          title: 'Export Logs',
                          subtitle: 'Export all logs as text',
                          onTap: _exportLogs,
                        ),
                        Divider(height: 1, color: context.outlineColor),
                        _buildActionTile(
                          context,
                          icon: HugeIcons.strokeRoundedDelete01,
                          title: 'Clear Logs',
                          subtitle: 'Delete all stored logs',
                          onTap: _clearLogs,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),

                  VSpace.xxl(),
                ],
              ),
            ),
    );
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: isDestructive ? context.errorColor : context.primaryColor,
        size: AppDimensions.iconMedium,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? context.errorColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: context.textSecondary,
        size: AppDimensions.iconMedium,
      ),
      onTap: onTap,
    );
  }
}
