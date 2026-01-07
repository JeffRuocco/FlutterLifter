import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lifter/core/theme/color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../screens/debug_settings_screen.dart';
import '../services/logging_service.dart';

/// Debug action button that appears only when debug mode is enabled
class DebugActionButton extends ConsumerWidget {
  const DebugActionButton({super.key});

  void _openDebugSettings(BuildContext context) {
    LoggingService.logUserAction('Opened debug settings');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugModeAsync = ref.watch(debugModeProvider);

    return debugModeAsync.when(
      data: (isDebugModeEnabled) {
        // Show if debug mode is enabled OR if we're in development mode
        if (!isDebugModeEnabled && !kDebugMode) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.small(
          onPressed: () => _openDebugSettings(context),
          backgroundColor: Colors.orange[700],
          foregroundColor: ColorUtils.getContrastingTextColor(
            Colors.orange[700]!,
          ),
          tooltip: 'Debug Settings',
          heroTag: 'debug_settings_fab', // Unique hero tag to avoid conflicts
          child: const Icon(Icons.bug_report, size: 20),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Debug icon button for app bars
class DebugIconButton extends ConsumerWidget {
  const DebugIconButton({super.key});

  void _openDebugSettings(BuildContext context) {
    LoggingService.logUserAction('Opened debug settings from app bar');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugModeAsync = ref.watch(debugModeProvider);

    return debugModeAsync.when(
      data: (isDebugModeEnabled) {
        // Show if debug mode is enabled OR if we're in development mode
        if (!isDebugModeEnabled && !kDebugMode) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => _openDebugSettings(context),
          icon: Icon(Icons.bug_report, color: Colors.orange[700]),
          tooltip: 'Debug Settings',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
