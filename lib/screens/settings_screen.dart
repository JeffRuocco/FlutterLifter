import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/theme/app_colors.dart';
import '../services/app_settings_service.dart';
import '../services/service_locator.dart';
import '../services/logging_service.dart';
import 'debug_settings_screen.dart';

/// Main settings screen accessible only from home page
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettingsService _settingsService;
  bool _debugModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = serviceLocator.get<AppSettingsService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final debugMode = await _settingsService.isDebugModeEnabled();

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
      await _settingsService.setDebugModeEnabled(enabled);

      setState(() {
        _debugModeEnabled = enabled;
      });

      LoggingService.logUserAction(
          'Debug mode ${enabled ? 'enabled' : 'disabled'} from main settings');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug mode ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to toggle debug mode', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update debug mode setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openDebugSettings() {
    LoggingService.logUserAction('Opened debug settings from main settings');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugSettingsScreen(),
      ),
    ).then((_) {
      // Refresh settings when returning
      _loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Settings Section
                  _buildSectionTitle('App Settings'),
                  _buildSettingsCard([
                    ListTile(
                      leading:
                          const Icon(Icons.palette, color: AppColors.primary),
                      title: const Text('Theme'),
                      subtitle: const Text('Light mode'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement theme settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Theme settings coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications,
                          color: AppColors.primary),
                      title: const Text('Notifications'),
                      subtitle: const Text('Workout reminders and updates'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Notification settings coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.backup, color: AppColors.primary),
                      title: const Text('Backup & Sync'),
                      subtitle: const Text('Cloud backup and synchronization'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement backup settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Backup settings coming soon')),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Privacy & Security Section
                  _buildSectionTitle('Privacy & Security'),
                  _buildSettingsCard([
                    ListTile(
                      leading: const Icon(Icons.privacy_tip,
                          color: AppColors.primary),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('View our privacy policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement privacy policy view
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Privacy policy coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.security, color: AppColors.primary),
                      title: const Text('Data Export'),
                      subtitle: const Text('Export your workout data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement data export
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Data export coming soon')),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Developer Options Section
                  _buildSectionTitle('Developer Options'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Developer Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enable debug features and logging tools. Only enable if you need to troubleshoot issues or are developing the app.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      'Enable Debug Mode',
                      'Show debug buttons and enable developer features',
                      _debugModeEnabled,
                      _toggleDebugMode,
                      Icons.developer_mode,
                    ),
                    if (_debugModeEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bug_report,
                            color: AppColors.primary),
                        title: const Text('Debug Tools'),
                        subtitle:
                            const Text('Advanced logging and debugging tools'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openDebugSettings,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionTitle('About'),
                  _buildSettingsCard([
                    ListTile(
                      leading: const Icon(Icons.info, color: AppColors.primary),
                      title: const Text('App Version'),
                      subtitle: const Text('1.0.0+1'),
                      onTap: () {
                        // TODO: Show version details and changelog
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help, color: AppColors.primary),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Get help and contact support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement help and support
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Help & support coming soon')),
                        );
                      },
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(children: children),
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
}
