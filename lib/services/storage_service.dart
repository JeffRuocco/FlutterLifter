import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import 'logging_service.dart';

/// Abstract storage service for local data persistence
abstract class StorageService {
  Future<void> init();
  Future<void> store<T>(String key, T value);
  Future<T?> retrieve<T>(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<List<String>> getAllKeys();
}

/// SharedPreferences implementation of StorageService
class SharedPreferencesStorageService implements StorageService {
  // static late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    // TODO: Initialize SharedPreferences
    // _prefs = await SharedPreferences.getInstance();
    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<void> store<T>(String key, T value) async {
    // TODO: Implement storage based on type
    // if (value is String) {
    //   await _prefs.setString(key, value);
    // } else if (value is int) {
    //   await _prefs.setInt(key, value);
    // } else if (value is bool) {
    //   await _prefs.setBool(key, value);
    // } else if (value is double) {
    //   await _prefs.setDouble(key, value);
    // } else if (value is List<String>) {
    //   await _prefs.setStringList(key, value);
    // } else {
    //   // For complex objects, serialize to JSON
    //   await _prefs.setString(key, jsonEncode(value));
    // }

    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    // TODO: Implement retrieval based on type
    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<void> remove(String key) async {
    // await _prefs.remove(key);
    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<void> clear() async {
    // await _prefs.clear();
    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<bool> containsKey(String key) async {
    // return _prefs.containsKey(key);
    throw UnimplementedError('SharedPreferences implementation pending');
  }

  @override
  Future<List<String>> getAllKeys() async {
    // return _prefs.getKeys().toList();
    throw UnimplementedError('SharedPreferences implementation pending');
  }
}

/// Hive implementation of StorageService
///
/// Uses Hive boxes for persistent local storage across all platforms.
/// On web, Hive uses IndexedDB for storage.
class HiveStorageService implements StorageService {
  /// Box names for different data types
  static const String programsBoxName = 'programs';
  static const String customExercisesBoxName = 'custom_exercises';
  static const String userPreferencesBoxName = 'user_preferences';
  static const String exerciseHistoryBoxName = 'exercise_history';
  static const String syncMetadataBoxName = 'sync_metadata';
  static const String generalBoxName = 'general_storage';
  static const String photoStorageBoxName = 'photo_storage';

  /// Opened boxes for quick access
  static late Box<String> _programsBox;
  static late Box<String> _customExercisesBox;
  static late Box<String> _userPreferencesBox;
  static late Box<String> _exerciseHistoryBox;
  static late Box<String> _syncMetadataBox;
  static late Box<dynamic> _generalBox;
  static late Box<String> _photoStorageBox;

  static bool _isInitialized = false;

  /// Initialize all Hive boxes - call this once at app startup
  static Future<void> initializeBoxes() async {
    if (_isInitialized) return;

    _programsBox = await Hive.openBox<String>(programsBoxName);
    _customExercisesBox = await Hive.openBox<String>(customExercisesBoxName);
    _userPreferencesBox = await Hive.openBox<String>(userPreferencesBoxName);
    _exerciseHistoryBox = await Hive.openBox<String>(exerciseHistoryBoxName);
    _syncMetadataBox = await Hive.openBox<String>(syncMetadataBoxName);
    _generalBox = await Hive.openBox(generalBoxName);
    _photoStorageBox = await Hive.openBox<String>(photoStorageBoxName);

    _isInitialized = true;
  }

  /// Check if boxes have been initialized
  static bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    await initializeBoxes();
  }

  @override
  Future<void> store<T>(String key, T value) async {
    if (value is String) {
      await _generalBox.put(key, value);
    } else if (value is int ||
        value is double ||
        value is bool ||
        value is List) {
      await _generalBox.put(key, value);
    } else {
      // For complex objects, serialize to JSON
      await _generalBox.put(key, jsonEncode(value));
    }
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    final value = _generalBox.get(key);
    if (value == null) return null;

    if (T == String || T == int || T == double || T == bool) {
      return value as T;
    }

    // Try to decode JSON for complex types
    if (value is String) {
      try {
        return jsonDecode(value) as T;
      } catch (_) {
        return value as T;
      }
    }

    return value as T?;
  }

  @override
  Future<void> remove(String key) async {
    await _generalBox.delete(key);
  }

  @override
  Future<void> clear() async {
    await _generalBox.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _generalBox.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _generalBox.keys.cast<String>().toList();
  }

  // ===== Programs Box Operations =====

  /// Get the programs box for direct access
  static Box<String> get programsBox {
    _ensureInitialized();
    return _programsBox;
  }

  /// Store a program as JSON
  static Future<void> storeProgram(String id, Map<String, dynamic> json) async {
    _ensureInitialized();
    await _programsBox.put(id, jsonEncode(json));
  }

  /// Retrieve a program by ID
  static Map<String, dynamic>? getProgram(String id) {
    _ensureInitialized();
    final value = _programsBox.get(id);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'decode',
        'program:$id',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all programs as JSON maps
  static Map<String, Map<String, dynamic>> getAllPrograms() {
    _ensureInitialized();
    final result = <String, Map<String, dynamic>>{};
    for (final key in _programsBox.keys) {
      final value = _programsBox.get(key);
      if (value != null) {
        try {
          result[key as String] = jsonDecode(value) as Map<String, dynamic>;
        } catch (e, stackTrace) {
          // Skip corrupted entries
          LoggingService.logDataError(
            'decode',
            'program:$key',
            e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    return result;
  }

  /// Delete a program
  static Future<void> deleteProgram(String id) async {
    _ensureInitialized();
    await _programsBox.delete(id);
  }

  /// Clear all programs
  static Future<void> clearPrograms() async {
    _ensureInitialized();
    await _programsBox.clear();
  }

  // ===== Custom Exercises Box Operations =====

  /// Get the custom exercises box for direct access
  static Box<String> get customExercisesBox {
    _ensureInitialized();
    return _customExercisesBox;
  }

  /// Store a custom exercise as JSON
  static Future<void> storeCustomExercise(
    String id,
    Map<String, dynamic> json,
  ) async {
    _ensureInitialized();
    await _customExercisesBox.put(id.toLowerCase(), jsonEncode(json));
  }

  /// Retrieve a custom exercise by ID
  static Map<String, dynamic>? getCustomExercise(String id) {
    _ensureInitialized();
    final value = _customExercisesBox.get(id.toLowerCase());
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'decode',
        'custom_exercise:$id',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all custom exercises
  static Map<String, Map<String, dynamic>> getAllCustomExercises() {
    _ensureInitialized();
    final result = <String, Map<String, dynamic>>{};
    for (final key in _customExercisesBox.keys) {
      final value = _customExercisesBox.get(key);
      if (value != null) {
        try {
          result[key as String] = jsonDecode(value) as Map<String, dynamic>;
        } catch (e, stackTrace) {
          LoggingService.logDataError(
            'decode',
            'custom_exercise:$key',
            e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    return result;
  }

  /// Delete a custom exercise
  static Future<void> deleteCustomExercise(String id) async {
    _ensureInitialized();
    await _customExercisesBox.delete(id.toLowerCase());
  }

  /// Clear all custom exercises
  static Future<void> clearCustomExercises() async {
    _ensureInitialized();
    await _customExercisesBox.clear();
  }

  // ===== User Preferences Box Operations =====

  /// Get the user preferences box for direct access
  static Box<String> get userPreferencesBox {
    _ensureInitialized();
    return _userPreferencesBox;
  }

  /// Store user exercise preferences as JSON
  static Future<void> storeUserPreference(
    String exerciseId,
    Map<String, dynamic> json,
  ) async {
    _ensureInitialized();
    await _userPreferencesBox.put(exerciseId.toLowerCase(), jsonEncode(json));
  }

  /// Retrieve user preferences for an exercise
  static Map<String, dynamic>? getUserPreference(String exerciseId) {
    _ensureInitialized();
    final value = _userPreferencesBox.get(exerciseId.toLowerCase());
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'decode',
        'user_preference:$exerciseId',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all user preferences
  static Map<String, Map<String, dynamic>> getAllUserPreferences() {
    _ensureInitialized();
    final result = <String, Map<String, dynamic>>{};
    for (final key in _userPreferencesBox.keys) {
      final value = _userPreferencesBox.get(key);
      if (value != null) {
        try {
          result[key as String] = jsonDecode(value) as Map<String, dynamic>;
        } catch (e, stackTrace) {
          LoggingService.logDataError(
            'decode',
            'user_preference:$key',
            e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    return result;
  }

  /// Delete user preferences for an exercise
  static Future<void> deleteUserPreference(String exerciseId) async {
    _ensureInitialized();
    await _userPreferencesBox.delete(exerciseId.toLowerCase());
  }

  /// Clear all user preferences
  static Future<void> clearUserPreferences() async {
    _ensureInitialized();
    await _userPreferencesBox.clear();
  }

  // ===== Sync Metadata Box Operations =====

  /// Get the sync metadata box for direct access
  static Box<String> get syncMetadataBox {
    _ensureInitialized();
    return _syncMetadataBox;
  }

  /// Store sync metadata
  static Future<void> storeSyncMetadata(
    String id,
    Map<String, dynamic> json,
  ) async {
    _ensureInitialized();
    await _syncMetadataBox.put(id, jsonEncode(json));
  }

  /// Retrieve sync metadata by ID
  static Map<String, dynamic>? getSyncMetadata(String id) {
    _ensureInitialized();
    final value = _syncMetadataBox.get(id);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'decode',
        'sync_metadata:$id',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get all sync metadata
  static List<Map<String, dynamic>> getAllSyncMetadata() {
    _ensureInitialized();
    final result = <Map<String, dynamic>>[];
    for (final key in _syncMetadataBox.keys) {
      final value = _syncMetadataBox.get(key);
      if (value != null) {
        try {
          result.add(jsonDecode(value) as Map<String, dynamic>);
        } catch (e, stackTrace) {
          LoggingService.logDataError(
            'decode',
            'sync_metadata:$key',
            e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    return result;
  }

  /// Delete sync metadata
  static Future<void> deleteSyncMetadata(String id) async {
    _ensureInitialized();
    await _syncMetadataBox.delete(id);
  }

  /// Clear all sync metadata
  static Future<void> clearSyncMetadata() async {
    _ensureInitialized();
    await _syncMetadataBox.clear();
  }

  // ===== Photo Storage Operations (Web Platform) =====

  /// URI scheme for Hive-stored photos
  static const String hivePhotoScheme = 'hive://photo/';

  /// Store photo bytes as base64 string in Hive (for web platform)
  ///
  /// Returns the hive:// URI that can be used to retrieve the photo.
  static Future<String> storePhoto(String photoId, List<int> bytes) async {
    _ensureInitialized();
    final base64Data = base64Encode(bytes);
    await _photoStorageBox.put(photoId, base64Data);
    return '$hivePhotoScheme$photoId';
  }

  /// Retrieve photo bytes from Hive by photo ID
  ///
  /// Returns null if photo not found.
  static List<int>? getPhotoBytes(String photoId) {
    _ensureInitialized();
    final base64Data = _photoStorageBox.get(photoId);
    if (base64Data == null) return null;
    try {
      return base64Decode(base64Data);
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'decode',
        'photo:$photoId',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Check if a photo exists in Hive storage
  static bool photoExists(String photoId) {
    _ensureInitialized();
    return _photoStorageBox.containsKey(photoId);
  }

  /// Delete a photo from Hive storage
  static Future<void> deletePhoto(String photoId) async {
    _ensureInitialized();
    await _photoStorageBox.delete(photoId);
  }

  /// Get all photo IDs stored in Hive
  static List<String> getAllPhotoIds() {
    _ensureInitialized();
    return _photoStorageBox.keys.cast<String>().toList();
  }

  /// Clear all photos from Hive storage
  static Future<void> clearAllPhotos() async {
    _ensureInitialized();
    await _photoStorageBox.clear();
  }

  /// Get the total size of all stored photos in bytes (approximate)
  // TODO: Cache total size and update it incrementally when photos are added/removed for improved efficiency
  static int getPhotoStorageSize() {
    _ensureInitialized();
    var totalSize = 0;
    for (final key in _photoStorageBox.keys) {
      final value = _photoStorageBox.get(key);
      if (value != null) {
        // Base64 is ~33% larger than binary, so estimate actual size
        totalSize += (value.length * 3 ~/ 4);
      }
    }
    return totalSize;
  }

  /// Parse a hive:// URI to extract the photo ID
  ///
  /// Returns null if the URI is not a valid hive photo URI.
  static String? parseHivePhotoUri(String uri) {
    if (!uri.startsWith(hivePhotoScheme)) return null;
    return uri.substring(hivePhotoScheme.length);
  }

  /// Check if a URI is a hive:// photo URI
  static bool isHivePhotoUri(String uri) {
    return uri.startsWith(hivePhotoScheme);
  }

  // ===== Cache Metadata Operations =====

  /// Key for storing cache timestamps
  static const String _cacheTimestampPrefix = '_cache_timestamp_';

  /// Store cache update timestamp for a specific cache type
  static Future<void> setCacheTimestamp(
    String cacheType,
    DateTime timestamp,
  ) async {
    _ensureInitialized();
    await _generalBox.put(
      '$_cacheTimestampPrefix$cacheType',
      timestamp.toIso8601String(),
    );
  }

  /// Get cache update timestamp for a specific cache type
  static DateTime? getCacheTimestamp(String cacheType) {
    _ensureInitialized();
    final value = _generalBox.get('$_cacheTimestampPrefix$cacheType');
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (e, stackTrace) {
      LoggingService.logDataError(
        'parse',
        'cache_timestamp:$cacheType',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clear cache timestamp for a specific cache type
  static Future<void> clearCacheTimestamp(String cacheType) async {
    _ensureInitialized();
    await _generalBox.delete('$_cacheTimestampPrefix$cacheType');
  }

  // ===== Utility Methods =====

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveStorageService not initialized. '
        'Call HiveStorageService.initializeBoxes() first.',
      );
    }
  }

  /// Check if a box contains a key
  static bool boxContainsKey(String boxName, String key) {
    _ensureInitialized();
    switch (boxName) {
      case programsBoxName:
        return _programsBox.containsKey(key);
      case customExercisesBoxName:
        return _customExercisesBox.containsKey(key.toLowerCase());
      case userPreferencesBoxName:
        return _userPreferencesBox.containsKey(key.toLowerCase());
      case syncMetadataBoxName:
        return _syncMetadataBox.containsKey(key);
      default:
        return _generalBox.containsKey(key);
    }
  }

  /// Get the count of items in a box
  static int boxLength(String boxName) {
    _ensureInitialized();
    switch (boxName) {
      case programsBoxName:
        return _programsBox.length;
      case customExercisesBoxName:
        return _customExercisesBox.length;
      case userPreferencesBoxName:
        return _userPreferencesBox.length;
      case syncMetadataBoxName:
        return _syncMetadataBox.length;
      default:
        return _generalBox.length;
    }
  }

  /// Close all boxes - typically called on app shutdown
  static Future<void> closeBoxes() async {
    if (!_isInitialized) return;

    await _programsBox.close();
    await _customExercisesBox.close();
    await _userPreferencesBox.close();
    await _exerciseHistoryBox.close();
    await _syncMetadataBox.close();
    await _generalBox.close();
    await _photoStorageBox.close();

    _isInitialized = false;
  }

  /// Clear all data from all boxes
  static Future<void> clearAllData() async {
    _ensureInitialized();
    await _programsBox.clear();
    await _customExercisesBox.clear();
    await _userPreferencesBox.clear();
    await _exerciseHistoryBox.clear();
    await _syncMetadataBox.clear();
    await _generalBox.clear();
    await _photoStorageBox.clear();
  }
}

/// In-memory implementation for testing
class InMemoryStorageService implements StorageService {
  static final Map<String, dynamic> _storage = {};

  @override
  Future<void> init() async {
    // No initialization needed for in-memory storage
  }

  @override
  Future<void> store<T>(String key, T value) async {
    _storage[key] = value;
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    return _storage[key] as T?;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _storage.keys.cast<String>().toList();
  }
}
