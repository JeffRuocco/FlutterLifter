import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';

/// Provider for StorageService
///
/// Currently uses InMemoryStorageService for development.
/// In production, this would be replaced with SharedPreferencesStorageService or HiveStorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return InMemoryStorageService();
});

/// FutureProvider for initializing storage
///
/// Use this to ensure storage is initialized before use.
final storageInitProvider = FutureProvider<void>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  await storage.init();
});
