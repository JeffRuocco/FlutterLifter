import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/theme/app_colors.dart';
import '../services/logging_service.dart';
import '../services/app_settings_service.dart';
import '../services/service_locator.dart';

/// Debug settings screen for development and troubleshooting
class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  late AppSettingsService _settingsService;
  bool _debugLoggingEnabled = false;
  bool _verboseLoggingEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = serviceLocator.get<AppSettingsService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final debugLogging = await _settingsService.isDebugLoggingEnabled();
      final verboseLogging = await _settingsService.isVerboseLoggingEnabled();

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
      await _settingsService.setDebugLoggingEnabled(enabled);
      await LoggingService.updateDebugLogging(enabled);

      setState(() {
        _debugLoggingEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Debug logging ${enabled ? 'enabled' : 'disabled'}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug logging ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to toggle debug logging', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update debug logging setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleVerboseLogging(bool enabled) async {
    try {
      await _settingsService.setVerboseLoggingEnabled(enabled);
      await LoggingService.updateVerboseLogging(enabled);

      setState(() {
        _verboseLoggingEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Verbose logging ${enabled ? 'enabled' : 'disabled'}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verbose logging ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to toggle verbose logging', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update verbose logging setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearLogs() {
    try {
      LoggingService.clearLogs();
      LoggingService.logUserAction('Logs cleared');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to clear logs', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear logs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportLogs() {
    try {
      final logs = LoggingService.exportLogs();
      LoggingService.logUserAction('Logs exported');

      // In a real app, you might want to share this via share_plus package
      // or save to file. For now, we'll just show a dialog with the logs.
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export logs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openTalkerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TalkerScreen(
          talker: LoggingService.talker,
          theme: const TalkerScreenTheme(
            backgroundColor: AppColors.surface,
            textColor: AppColors.textPrimary,
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
        backgroundColor: Colors.orange[800],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logging & Debug Tools',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure logging settings and access debugging tools. These tools help with troubleshooting and development.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Info
                  _buildSectionTitle('App Information'),
                  _buildInfoCard([
                    _buildInfoRow(
                        'Debug Mode', kDebugMode ? 'Enabled' : 'Disabled'),
                    _buildInfoRow('Total Logs', '${LoggingService.logCount}'),
                    _buildInfoRow(
                        'Build Mode', kReleaseMode ? 'Release' : 'Development'),
                  ]),

                  const SizedBox(height: 24),

                  // Logging Settings
                  _buildSectionTitle('Logging Settings'),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      'Debug Logging',
                      'Enable debug level logging to console',
                      _debugLoggingEnabled,
                      _toggleDebugLogging,
                      Icons.bug_report,
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      'Verbose Logging',
                      'Enable verbose level logging (most detailed)',
                      _verboseLoggingEnabled,
                      _toggleVerboseLogging,
                      Icons.visibility,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Log Actions
                  _buildSectionTitle('Log Actions'),
                  _buildActionsCard([
                    _buildActionTile(
                      'View Logs',
                      'Open the log viewer screen',
                      Icons.visibility,
                      _openTalkerScreen,
                    ),
                    const Divider(height: 1),
                    _buildActionTile(
                      'Export Logs',
                      'Export all logs as text',
                      Icons.file_download,
                      _exportLogs,
                    ),
                    const Divider(height: 1),
                    _buildActionTile(
                      'Clear Logs',
                      'Delete all stored logs',
                      Icons.delete_outline,
                      _clearLogs,
                      isDestructive: true,
                    ),
                  ]),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildActionsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
