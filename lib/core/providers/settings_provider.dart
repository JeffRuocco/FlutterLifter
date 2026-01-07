import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_settings_service.dart';

/// Provider for AppSettingsService
///
/// This is an async provider because the service needs to be initialized.
final appSettingsServiceProvider = FutureProvider<AppSettingsService>((
  ref,
) async {
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
class DebugModeNotifier extends Notifier<AsyncValue<bool>> {
  late AppSettingsService _settingsService;

  @override
  AsyncValue<bool> build() {
    // Will be overridden with proper service
    throw UnimplementedError(
      'Use debugModeNotifierProviderFamily with initialized AppSettingsService',
    );
  }

  /// Initialize the notifier with AppSettingsService
  void init(AppSettingsService service) {
    _settingsService = service;
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
    final current = state.value ?? false;
    await setDebugMode(!current);
  }
}

/// NotifierProvider for debug mode with toggle functionality
final debugModeNotifierProvider =
    NotifierProvider<DebugModeNotifier, AsyncValue<bool>>(
      DebugModeNotifier.new,
    );

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
