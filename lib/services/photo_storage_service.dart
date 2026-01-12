import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling exercise photo storage and management.
///
/// Provides:
/// - Photo picking from camera or gallery
/// - 85% JPEG compression for optimal quality/size balance
/// - Local file storage in app documents directory
/// - Stubs for future cloud storage integration (Firebase Storage)
///
/// Usage:
/// ```dart
/// final service = PhotoStorageService();
/// await service.init();
///
/// // Pick and save a photo
/// final path = await service.pickAndSaveFromGallery('exercise-id-123');
/// if (path != null) {
///   // Photo saved at path
/// }
///
/// // Delete a photo
/// await service.deletePhoto(path);
/// ```
class PhotoStorageService {
  static const String _photosDirectoryName = 'exercise_photos';
  static const int _compressionQuality =
      85; // Industry standard for high quality
  static const int _maxWidth = 2048; // Max dimension to prevent huge files
  static const int _maxHeight = 2048;

  final ImagePicker _picker = ImagePicker();
  Directory? _photosDirectory;
  bool _isInitialized = false;

  /// Whether the service is initialized and ready to use
  bool get isInitialized => _isInitialized;

  /// Path to the photos directory
  String? get photosDirectoryPath => _photosDirectory?.path;

  /// Initialize the service.
  ///
  /// Must be called before using any photo operations.
  /// On web platform, initialization is skipped (photos stored differently).
  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // Web platform doesn't use local file storage the same way
      // Photos will be handled via IndexedDB or cloud storage
      LoggingService.info('Web platform - using alternative storage');
      _isInitialized = true;
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _photosDirectory = Directory('${appDir.path}/$_photosDirectoryName');

      LoggingService.debug('App documents directory: ${appDir.path}');
      LoggingService.debug('Photos directory path: ${_photosDirectory!.path}');

      if (!await _photosDirectory!.exists()) {
        await _photosDirectory!.create(recursive: true);
        LoggingService.debug(
          'Created photos directory at ${_photosDirectory!.path}',
        );
      } else {
        // List existing photos on init for debugging
        final existingFiles = _photosDirectory!.listSync();
        LoggingService.debug(
          'Photos directory exists with ${existingFiles.length} files',
        );
        for (final file in existingFiles.take(5)) {
          LoggingService.debug(
            '  - ${file.path.split(Platform.pathSeparator).last}',
          );
        }
        if (existingFiles.length > 5) {
          LoggingService.debug('  ... and ${existingFiles.length - 5} more');
        }
      }

      _isInitialized = true;
      LoggingService.debug(
        'Initialized with directory ${_photosDirectory!.path}',
      );
    } catch (e) {
      LoggingService.error('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Pick a photo from the device camera and save it.
  ///
  /// Returns the saved file path, or null if cancelled or failed.
  Future<String?> pickAndSaveFromCamera(String exerciseId) async {
    return _pickAndSave(exerciseId, ImageSource.camera);
  }

  /// Pick a photo from the device gallery and save it.
  ///
  /// Returns the saved file path, or null if cancelled or failed.
  Future<String?> pickAndSaveFromGallery(String exerciseId) async {
    return _pickAndSave(exerciseId, ImageSource.gallery);
  }

  Future<String?> _pickAndSave(String exerciseId, ImageSource source) async {
    _ensureInitialized();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: _maxWidth.toDouble(),
        maxHeight: _maxHeight.toDouble(),
        imageQuality: _compressionQuality,
      );

      if (pickedFile == null) {
        LoggingService.debug('User cancelled picker');
        return null;
      }

      return await _compressAndSave(pickedFile, exerciseId);
    } catch (e) {
      LoggingService.error('Failed to pick photo from $source: $e');
      return null;
    }
  }

  Future<String?> _compressAndSave(XFile pickedFile, String exerciseId) async {
    try {
      final bytes = await pickedFile.readAsBytes();

      // Generate unique photo ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedExerciseId = _sanitizeFilename(exerciseId);
      final photoId = '${sanitizedExerciseId}_$timestamp';

      if (kIsWeb) {
        // On web, store photo bytes in Hive (IndexedDB)
        // This persists across browser sessions
        return await _saveToHive(bytes, photoId);
      }

      // Native platform: save to file system
      final filename = '$photoId.jpg';
      final outputPath =
          '${_photosDirectory!.path}${Platform.pathSeparator}$filename';

      LoggingService.debug('Attempting to save photo to: $outputPath');

      // Check if compression is supported on this platform
      // flutter_image_compress only supports Android, iOS, macOS, and Web
      final bool compressionSupported = _isCompressionSupported();

      Uint8List finalBytes;
      if (compressionSupported) {
        // Compress the image
        // Note: minWidth/minHeight in flutter_image_compress act as max constraints
        // Images larger than these will be scaled down; smaller images won't scale up
        finalBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _maxWidth,
          minHeight: _maxHeight,
          quality: _compressionQuality,
          format: CompressFormat.jpeg,
        );

        final originalSize = bytes.length;
        final compressedSize = finalBytes.length;
        final savings = ((1 - compressedSize / originalSize) * 100)
            .toStringAsFixed(1);

        LoggingService.debug(
          'Compressed photo '
          '(${_formatBytes(originalSize)} -> ${_formatBytes(compressedSize)}, $savings% reduction)',
        );
      } else {
        // On Windows/Linux, skip compression and save original
        finalBytes = bytes;
        LoggingService.debug('Skipping compression - platform not supported');
      }

      // Save the image
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(finalBytes);

      // Verify the file was written successfully
      if (await outputFile.exists()) {
        final fileSize = await outputFile.length();
        LoggingService.debug(
          'Successfully saved photo to $outputPath (${_formatBytes(fileSize)})',
        );
        return outputPath;
      } else {
        LoggingService.error('ERROR: File was not created at $outputPath');
        return null;
      }
    } catch (e, stackTrace) {
      LoggingService.error('Failed to compress and save photo: $e');
      LoggingService.error('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Save photo bytes to Hive storage (web platform).
  ///
  /// Compresses the image if supported and stores as base64 in IndexedDB.
  /// Returns the hive:// URI for the stored photo.
  // TODO: Add unit tests
  Future<String?> _saveToHive(Uint8List bytes, String photoId) async {
    try {
      Uint8List finalBytes;

      // Compress on web (flutter_image_compress supports web)
      if (_isCompressionSupported()) {
        finalBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _maxWidth,
          minHeight: _maxHeight,
          quality: _compressionQuality,
          format: CompressFormat.jpeg,
        );

        final originalSize = bytes.length;
        final compressedSize = finalBytes.length;
        final savings = ((1 - compressedSize / originalSize) * 100)
            .toStringAsFixed(1);

        LoggingService.debug(
          'Compressed photo for web '
          '(${_formatBytes(originalSize)} -> ${_formatBytes(compressedSize)}, $savings% reduction)',
        );
      } else {
        finalBytes = bytes;
      }

      // Store in Hive (uses IndexedDB on web)
      final hiveUri = await HiveStorageService.storePhoto(photoId, finalBytes);

      LoggingService.debug(
        'Saved photo to Hive: $hiveUri (${_formatBytes(finalBytes.length)})',
      );

      return hiveUri;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to save photo to Hive: $e');
      LoggingService.error('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if image compression is supported on the current platform.
  ///
  /// flutter_image_compress supports: Android, iOS, macOS, Web
  /// Not supported: Windows, Linux
  bool _isCompressionSupported() {
    return kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Save a photo from bytes (useful for importing or testing).
  ///
  /// Returns the saved file path (or hive:// URI on web), or null if failed.
  Future<String?> saveFromBytes(
    Uint8List bytes,
    String exerciseId, {
    bool compress = true,
  }) async {
    _ensureInitialized();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedExerciseId = _sanitizeFilename(exerciseId);
    final photoId = '${sanitizedExerciseId}_$timestamp';

    if (kIsWeb) {
      // On web, store in Hive
      return await _saveToHive(bytes, photoId);
    }

    try {
      final filename = '$photoId.jpg';
      final outputPath =
          '${_photosDirectory!.path}${Platform.pathSeparator}$filename';

      Uint8List finalBytes = bytes;

      // Only compress if requested AND platform supports it
      if (compress && _isCompressionSupported()) {
        finalBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _maxWidth,
          minHeight: _maxHeight,
          quality: _compressionQuality,
          format: CompressFormat.jpeg,
        );
      }

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(finalBytes);

      LoggingService.debug('Saved photo from bytes to $outputPath');

      return outputPath;
    } catch (e) {
      LoggingService.error('Failed to save photo from bytes: $e');
      return null;
    }
  }

  /// Delete a locally stored photo.
  ///
  /// Handles both native file paths and hive:// URIs (web).
  /// Returns true if deleted successfully, false otherwise.
  Future<bool> deletePhoto(String photoPath) async {
    // Handle hive:// URIs (web storage)
    if (HiveStorageService.isHivePhotoUri(photoPath)) {
      try {
        final photoId = HiveStorageService.parseHivePhotoUri(photoPath);
        if (photoId == null) {
          LoggingService.error('Invalid hive photo URI: $photoPath');
          return false;
        }
        await HiveStorageService.deletePhoto(photoId);
        LoggingService.debug('Deleted photo from Hive: $photoPath');
        return true;
      } catch (e) {
        LoggingService.error('Failed to delete photo from Hive: $e');
        return false;
      }
    }

    // Native file system
    if (kIsWeb) {
      LoggingService.debug('deletePhoto not supported on web for local files');
      return false;
    }

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        LoggingService.debug('Deleted photo at $photoPath');
        return true;
      } else {
        LoggingService.debug('Photo not found at $photoPath');
        return false;
      }
    } catch (e) {
      LoggingService.error('Failed to delete photo at $photoPath: $e');
      return false;
    }
  }

  /// Delete all photos for a specific exercise.
  ///
  /// Returns the count of deleted files.
  Future<int> deletePhotosForExercise(String exerciseId) async {
    if (kIsWeb) return 0;

    _ensureInitialized();

    try {
      final sanitizedId = _sanitizeFilename(exerciseId);
      final files = _photosDirectory!.listSync();
      var deletedCount = 0;

      for (final entity in files) {
        if (entity is File) {
          final filename = entity.path.split(Platform.pathSeparator).last;
          if (filename.startsWith('${sanitizedId}_')) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      LoggingService.debug(
        'Deleted $deletedCount photos for exercise $exerciseId',
      );

      return deletedCount;
    } catch (e) {
      LoggingService.error(
        'Failed to delete photos for exercise $exerciseId: $e',
      );
      return 0;
    }
  }

  /// Check if a photo exists (supports both file paths and hive:// URIs).
  Future<bool> photoExists(String photoPath) async {
    // Handle hive:// URIs (web storage)
    if (HiveStorageService.isHivePhotoUri(photoPath)) {
      final photoId = HiveStorageService.parseHivePhotoUri(photoPath);
      if (photoId == null) return false;
      return HiveStorageService.photoExists(photoId);
    }

    // Native file system
    if (kIsWeb) return false;

    try {
      return await File(photoPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the size of a photo in bytes (supports both file paths and hive:// URIs).
  Future<int?> getPhotoSize(String photoPath) async {
    // Handle hive:// URIs (web storage)
    if (HiveStorageService.isHivePhotoUri(photoPath)) {
      final photoId = HiveStorageService.parseHivePhotoUri(photoPath);
      if (photoId == null) return null;
      final bytes = HiveStorageService.getPhotoBytes(photoId);
      return bytes?.length;
    }

    // Native file system
    if (kIsWeb) return null;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get total storage used by exercise photos in bytes.
  ///
  /// On web, returns the estimated size of photos stored in Hive.
  Future<int> getTotalStorageUsed() async {
    if (kIsWeb) {
      return HiveStorageService.getPhotoStorageSize();
    }

    _ensureInitialized();

    try {
      var totalBytes = 0;
      final files = _photosDirectory!.listSync();

      for (final entity in files) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      return totalBytes;
    } catch (e) {
      LoggingService.error('Failed to calculate storage used: $e');
      return 0;
    }
  }

  /// Clear all locally stored exercise photos.
  ///
  /// Use with caution - this deletes all photos!
  Future<int> clearAllPhotos() async {
    if (kIsWeb) {
      // Clear all photos from Hive storage
      final photoIds = HiveStorageService.getAllPhotoIds();
      final count = photoIds.length;
      await HiveStorageService.clearAllPhotos();
      LoggingService.debug('Cleared all photos from Hive ($count photos)');
      return count;
    }

    _ensureInitialized();

    try {
      var deletedCount = 0;
      final files = _photosDirectory!.listSync();

      for (final entity in files) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }

      LoggingService.debug('Cleared all photos ($deletedCount files)');

      return deletedCount;
    } catch (e) {
      LoggingService.error('Failed to clear all photos: $e');
      return 0;
    }
  }

  // ============================================
  // Hive Photo Loading (Web Platform)
  // ============================================

  /// Load photo bytes from Hive storage by URI.
  ///
  /// Returns null if the photo doesn't exist or URI is invalid.
  /// This is a static method so it can be called from widgets without
  /// needing a PhotoStorageService instance.
  // TODO: The loadPhotoFromHive method performs synchronous base64 decoding in the widget build method, which could cause UI jank for large photos. Consider making this async and using FutureBuilder or caching the decoded bytes to avoid blocking the UI thread during decoding.
  static Uint8List? loadPhotoFromHive(String hiveUri) {
    final photoId = HiveStorageService.parseHivePhotoUri(hiveUri);
    if (photoId == null) return null;
    final bytes = HiveStorageService.getPhotoBytes(photoId);
    if (bytes == null) return null;
    return Uint8List.fromList(bytes);
  }

  /// Check if a URI is a Hive photo URI.
  static bool isHivePhotoUri(String uri) {
    return HiveStorageService.isHivePhotoUri(uri);
  }

  // ============================================
  // Cloud Storage Stubs (Future Implementation)
  // ============================================

  /// Upload a photo to cloud storage.
  ///
  /// Returns the cloud URL if successful, null otherwise.
  /// Currently a stub - will be implemented with Firebase Storage.
  Future<String?> uploadToCloud(String localPath, String exerciseId) async {
    // TODO: Implement with Firebase Storage
    LoggingService.debug('uploadToCloud not yet implemented');
    throw UnimplementedError('Cloud storage upload not yet implemented');
  }

  /// Download a photo from cloud storage.
  ///
  /// Returns the local file path if successful, null otherwise.
  /// Currently a stub - will be implemented with Firebase Storage.
  Future<String?> downloadFromCloud(String cloudUrl, String exerciseId) async {
    // TODO: Implement with Firebase Storage
    LoggingService.debug('downloadFromCloud not yet implemented');
    throw UnimplementedError('Cloud storage download not yet implemented');
  }

  /// Delete a photo from cloud storage.
  ///
  /// Returns true if deleted successfully, false otherwise.
  /// Currently a stub - will be implemented with Firebase Storage.
  Future<bool> deleteFromCloud(String cloudUrl) async {
    // TODO: Implement with Firebase Storage
    LoggingService.debug('deleteFromCloud not yet implemented');
    throw UnimplementedError('Cloud storage delete not yet implemented');
  }

  /// Sync pending photo uploads to cloud storage.
  ///
  /// Returns a map of local paths to cloud URLs for successfully uploaded photos.
  /// Currently a stub - will be implemented with Firebase Storage.
  Future<Map<String, String>> syncPendingUploads(
    List<String> pendingPaths,
    String exerciseId,
  ) async {
    // TODO: Implement with Firebase Storage
    LoggingService.debug('syncPendingUploads not yet implemented');
    throw UnimplementedError('Cloud storage sync not yet implemented');
  }

  // ============================================
  // Private Helpers
  // ============================================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PhotoStorageService not initialized. Call init() first.',
      );
    }
  }

  String _sanitizeFilename(String input) {
    // Remove or replace characters not safe for filenames
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
