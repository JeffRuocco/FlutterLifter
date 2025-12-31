import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_settings_service.dart';

/// Provider for AppSettingsService
///
/// This is an async provider because the service needs to be initialized.
final appSettingsServiceProvider =
    FutureProvider<AppSettingsService>((ref) async {
  final service = AppSettingsService();
  await service.init();
  return service;
});

/// Provider for debug mode state
///
/// Returns whether debug mode is enabled.
final debugModeProvider = FutureProvider<bool>((ref) async {
  final settingsAsync = await ref.watch(appSettingsServiceProvider.future);
  return settingsAsync.isDebugModeEnabled();
});

/// Notifier for managing debug mode state
class DebugModeNotifier extends StateNotifier<AsyncValue<bool>> {
  final AppSettingsService _settingsService;

  DebugModeNotifier(this._settingsService) : super(const AsyncValue.loading()) {
    _loadState();
  }

  Future<void> _loadState() async {
    state = const AsyncValue.loading();
    try {
      final enabled = await _settingsService.isDebugModeEnabled();
      state = AsyncValue.data(enabled);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setDebugMode(bool enabled) async {
    state = const AsyncValue.loading();
    try {
      await _settingsService.setDebugModeEnabled(enabled);
      state = AsyncValue.data(enabled);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    await setDebugMode(!current);
  }
}

/// StateNotifierProvider for debug mode with toggle functionality
final debugModeNotifierProvider =
    StateNotifierProvider<DebugModeNotifier, AsyncValue<bool>>((ref) {
  // We need to handle the async nature of appSettingsServiceProvider
  // For now, we'll create a placeholder that gets updated
  throw UnimplementedError(
    'Use debugModeNotifierProviderFamily with initialized AppSettingsService',
  );
});

/// Provider for debug logging state
final debugLoggingProvider = FutureProvider<bool>((ref) async {
  final settingsAsync = await ref.watch(appSettingsServiceProvider.future);
  return settingsAsync.isDebugLoggingEnabled();
});

/// Provider for verbose logging state
final verboseLoggingProvider = FutureProvider<bool>((ref) async {
  final settingsAsync = await ref.watch(appSettingsServiceProvider.future);
  return settingsAsync.isVerboseLoggingEnabled();
});
