import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/photo_storage_service.dart';
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

/// Provider for PhotoStorageService
///
/// Handles exercise photo storage, compression, and management.
/// Must be initialized before use with [photoStorageInitProvider].
final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

/// FutureProvider for initializing photo storage
///
/// Use this to ensure photo storage is initialized before use.
/// Creates the photos directory and prepares the service.
final photoStorageInitProvider = FutureProvider<PhotoStorageService>((
  ref,
) async {
  final photoService = ref.watch(photoStorageServiceProvider);
  await photoService.init();
  return photoService;
});
