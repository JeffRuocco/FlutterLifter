import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../screens/debug_settings_screen.dart';
import '../services/app_settings_service.dart';
import '../services/service_locator.dart';
import '../services/logging_service.dart';

/// Debug action button that appears only when debug mode is enabled
class DebugActionButton extends StatefulWidget {
  const DebugActionButton({super.key});

  @override
  State<DebugActionButton> createState() => _DebugActionButtonState();
}

class _DebugActionButtonState extends State<DebugActionButton> {
  bool _isDebugModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDebugMode();
  }

  Future<void> _checkDebugMode() async {
    try {
      final settingsService = serviceLocator.get<AppSettingsService>();
      final isEnabled =
          kDebugMode || await settingsService.isDebugModeEnabled();

      setState(() {
        _isDebugModeEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Failed to check debug mode', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDebugSettings() {
    LoggingService.logUserAction('Opened debug settings');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugSettingsScreen(),
      ),
    ).then((_) {
      // Refresh debug mode status when returning from settings
      _checkDebugMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if loading or debug mode is not enabled
    if (_isLoading || !_isDebugModeEnabled) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.small(
      onPressed: _openDebugSettings,
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      tooltip: 'Debug Settings',
      heroTag: 'debug_settings_fab', // Unique hero tag to avoid conflicts
      child: const Icon(
        Icons.bug_report,
        size: 20,
      ),
    );
  }
}

/// Debug icon button for app bars
class DebugIconButton extends StatefulWidget {
  const DebugIconButton({super.key});

  @override
  State<DebugIconButton> createState() => _DebugIconButtonState();
}

class _DebugIconButtonState extends State<DebugIconButton> {
  bool _isDebugModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDebugMode();
  }

  Future<void> _checkDebugMode() async {
    try {
      final settingsService = serviceLocator.get<AppSettingsService>();
      final isEnabled =
          kDebugMode || await settingsService.isDebugModeEnabled();

      setState(() {
        _isDebugModeEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Failed to check debug mode', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDebugSettings() {
    LoggingService.logUserAction('Opened debug settings from app bar');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugSettingsScreen(),
      ),
    ).then((_) {
      // Refresh debug mode status when returning from settings
      _checkDebugMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if loading or debug mode is not enabled
    if (_isLoading || !_isDebugModeEnabled) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: _openDebugSettings,
      icon: Icon(
        Icons.bug_report,
        color: Colors.orange[700],
      ),
      tooltip: 'Debug Settings',
    );
  }
}
