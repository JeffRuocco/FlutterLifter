import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/user_exercise_preferences.dart';

/// Local data source for exercise-related operations.
///
/// Handles caching of custom exercises and user preferences.
///
/// **ID Normalization**: All exercise IDs are normalized to lowercase when
/// storing and retrieving to ensure consistent case-insensitive lookups.
abstract class ExerciseLocalDataSource {
  static const Duration defaultCacheMaxAge = Duration(minutes: 5);

  // Storage keys for global storage (will be per-user after auth implementation)
  // TODO: Migrate to per-user keys when auth is implemented (e.g., 'custom_exercises_{userId}')
  static const String customExercisesKey = 'custom_exercises';
  static const String exercisePreferencesKey = 'exercise_preferences';

  // Custom exercises cache operations
  Future<List<Exercise>> getCachedCustomExercises();
  Future<Exercise?> getCachedCustomExerciseById(String id);
  Future<void> cacheCustomExercise(Exercise exercise);
  Future<void> cacheCustomExercises(List<Exercise> exercises);
  Future<void> removeCustomExercise(String id);
  Future<void> clearCustomExercisesCache();

  // User exercise preferences operations
  Future<List<UserExercisePreferences>> getCachedPreferences();
  Future<UserExercisePreferences?> getCachedPreferenceForExercise(
      String exerciseId);
  Future<void> cachePreference(UserExercisePreferences preferences);
  Future<void> cachePreferences(List<UserExercisePreferences> preferences);
  Future<void> removePreference(String exerciseId);
  Future<void> clearPreferencesCache();

  // Cache metadata
  Future<DateTime?> getLastCustomExercisesCacheUpdate();
  Future<DateTime?> getLastPreferencesCacheUpdate();
  Future<bool> isCustomExercisesCacheExpired(
      {Duration maxAge = defaultCacheMaxAge});
  Future<bool> isPreferencesCacheExpired(
      {Duration maxAge = defaultCacheMaxAge});
}

/// In-memory implementation of ExerciseLocalDataSource
///
/// Used for development and testing. Will be replaced by Hive implementation.
///
/// **Design Note**: This implementation uses instance-level caches, meaning each
/// instance maintains its own independent cache state. For production use where
/// singleton behavior is desired, register a single instance with your DI container.
/// This design ensures clean test isolation without requiring explicit cache clearing
/// between tests - simply create a new instance for each test.
class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  // Instance-level caches for proper test isolation
  final Map<String, Exercise> _customExercisesCache = {};
  final Map<String, UserExercisePreferences> _preferencesCache = {};
  DateTime? _lastCustomExercisesUpdate;
  DateTime? _lastPreferencesUpdate;

  // Custom exercises operations
  @override
  Future<List<Exercise>> getCachedCustomExercises() async {
    return _customExercisesCache.values.toList();
  }

  @override
  Future<Exercise?> getCachedCustomExerciseById(String id) async {
    return _customExercisesCache[id.toLowerCase()];
  }

  @override
  Future<void> cacheCustomExercise(Exercise exercise) async {
    _customExercisesCache[exercise.id.toLowerCase()] = exercise;
    _lastCustomExercisesUpdate = DateTime.now();
  }

  @override
  Future<void> cacheCustomExercises(List<Exercise> exercises) async {
    _customExercisesCache.clear();
    for (final exercise in exercises) {
      _customExercisesCache[exercise.id.toLowerCase()] = exercise;
    }
    _lastCustomExercisesUpdate = DateTime.now();
  }

  @override
  Future<void> removeCustomExercise(String id) async {
    _customExercisesCache.remove(id.toLowerCase());
    _lastCustomExercisesUpdate = DateTime.now();
  }

  @override
  Future<void> clearCustomExercisesCache() async {
    _customExercisesCache.clear();
    _lastCustomExercisesUpdate = null;
  }

  // User preferences operations
  @override
  Future<List<UserExercisePreferences>> getCachedPreferences() async {
    return _preferencesCache.values.toList();
  }

  @override
  Future<UserExercisePreferences?> getCachedPreferenceForExercise(
      String exerciseId) async {
    return _preferencesCache[exerciseId.toLowerCase()];
  }

  @override
  Future<void> cachePreference(UserExercisePreferences preferences) async {
    // Key by exerciseId (normalized to lowercase) for quick lookup
    _preferencesCache[preferences.exerciseId.toLowerCase()] = preferences;
    _lastPreferencesUpdate = DateTime.now();
  }

  @override
  Future<void> cachePreferences(
      List<UserExercisePreferences> preferences) async {
    _preferencesCache.clear();
    for (final pref in preferences) {
      _preferencesCache[pref.exerciseId.toLowerCase()] = pref;
    }
    _lastPreferencesUpdate = DateTime.now();
  }

  @override
  Future<void> removePreference(String exerciseId) async {
    _preferencesCache.remove(exerciseId.toLowerCase());
    _lastPreferencesUpdate = DateTime.now();
  }

  @override
  Future<void> clearPreferencesCache() async {
    _preferencesCache.clear();
    _lastPreferencesUpdate = null;
  }

  // Cache metadata
  @override
  Future<DateTime?> getLastCustomExercisesCacheUpdate() async {
    return _lastCustomExercisesUpdate;
  }

  @override
  Future<DateTime?> getLastPreferencesCacheUpdate() async {
    return _lastPreferencesUpdate;
  }

  @override
  Future<bool> isCustomExercisesCacheExpired({
    Duration maxAge = ExerciseLocalDataSource.defaultCacheMaxAge,
  }) async {
    if (_lastCustomExercisesUpdate == null) return true;
    return DateTime.now().difference(_lastCustomExercisesUpdate!) > maxAge;
  }

  @override
  Future<bool> isPreferencesCacheExpired({
    Duration maxAge = ExerciseLocalDataSource.defaultCacheMaxAge,
  }) async {
    if (_lastPreferencesUpdate == null) return true;
    return DateTime.now().difference(_lastPreferencesUpdate!) > maxAge;
  }

  /// Clears all caches for this instance.
  ///
  /// Useful for resetting state during testing or when user logs out.
  void clearAllCaches() {
    _customExercisesCache.clear();
    _preferencesCache.clear();
    _lastCustomExercisesUpdate = null;
    _lastPreferencesUpdate = null;
  }
}

/// Hive implementation placeholder for persistent storage
class HiveExerciseLocalDataSource implements ExerciseLocalDataSource {
  @override
  Future<List<Exercise>> getCachedCustomExercises() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<Exercise?> getCachedCustomExerciseById(String id) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> cacheCustomExercise(Exercise exercise) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> cacheCustomExercises(List<Exercise> exercises) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> removeCustomExercise(String id) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> clearCustomExercisesCache() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<List<UserExercisePreferences>> getCachedPreferences() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<UserExercisePreferences?> getCachedPreferenceForExercise(
      String exerciseId) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> cachePreference(UserExercisePreferences preferences) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> cachePreferences(
      List<UserExercisePreferences> preferences) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> removePreference(String exerciseId) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<void> clearPreferencesCache() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<DateTime?> getLastCustomExercisesCacheUpdate() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<DateTime?> getLastPreferencesCacheUpdate() async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<bool> isCustomExercisesCacheExpired({
    Duration maxAge = ExerciseLocalDataSource.defaultCacheMaxAge,
  }) async {
    throw UnimplementedError('Hive implementation pending');
  }

  @override
  Future<bool> isPreferencesCacheExpired({
    Duration maxAge = ExerciseLocalDataSource.defaultCacheMaxAge,
  }) async {
    throw UnimplementedError('Hive implementation pending');
  }
}
