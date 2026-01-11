import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/photo_storage_service.dart';
import '../../services/storage_service.dart';

/// Provider for StorageService
///
/// Uses HiveStorageService for persistent local storage.
/// Hive is initialized in main.dart before the app starts.
final storageServiceProvider = Provider<StorageService>((ref) {
  return HiveStorageService();
});

/// FutureProvider for initializing storage
///
/// Note: Hive boxes are initialized in main.dart, so this provider
/// simply ensures the HiveStorageService is ready for use.
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
