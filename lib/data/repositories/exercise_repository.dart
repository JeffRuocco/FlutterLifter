import 'package:flutter_lifter/data/datasources/local/exercise_local_datasource.dart';
import 'package:flutter_lifter/data/datasources/mock/default_exercises.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/user_exercise_preferences.dart';
import 'package:flutter_lifter/utils/utils.dart';

/// Repository for managing exercises (default and custom) and user preferences.
///
/// Key principles:
/// - Default exercises are immutable and cannot be deleted
/// - Custom exercises support full CRUD operations
/// - User preferences allow customizing default exercise parameters without modifying originals
/// - Prepared for future exercise library integration (sync, publish, import)
abstract class ExerciseRepository {
  // ============================================
  // Default Exercises (Read-Only)
  // ============================================

  /// Returns all default built-in exercises.
  Future<List<Exercise>> getDefaultExercises();

  // ============================================
  // Custom Exercises (Full CRUD)
  // ============================================

  /// Returns all custom user-created exercises.
  Future<List<Exercise>> getCustomExercises();

  /// Creates a new custom exercise.
  ///
  /// Throws [ArgumentError] if [exercise.isDefault] is true.
  Future<void> createCustomExercise(Exercise exercise);

  /// Updates an existing custom exercise.
  ///
  /// Throws [ArgumentError] if trying to update a default exercise.
  Future<void> updateCustomExercise(Exercise exercise);

  /// Deletes a custom exercise by ID.
  ///
  /// Throws [ArgumentError] if trying to delete a default exercise.
  Future<void> deleteCustomExercise(String exerciseId);

  // ============================================
  // Combined Exercise Access
  // ============================================

  /// Returns exercises filtered by source (default, custom, or all).
  ///
  /// Default is [ExerciseSource.all].
  ///
  /// This method returns exercises without applying user preferences.
  /// In most cases, you should use [getExercises] to get exercises with user preferences applied.
  Future<List<Exercise>> getExercisesWithoutPreferences({
    ExerciseSource source = ExerciseSource.all,
  });

  /// Returns exercises with user preferences applied (modified copies).
  ///
  /// Preferences override default values for sets, reps, weight, rest time, notes.
  Future<List<Exercise>> getExercises({
    ExerciseSource source = ExerciseSource.all,
  });

  /// Returns a single exercise by ID with user preferences applied.
  ///
  /// This is the default method for getting an exercise by ID.
  /// Use [getExerciseByIdWithoutPreferences] if you need the raw exercise data.
  Future<Exercise?> getExerciseById(String id);

  /// Returns a single exercise by ID without user preferences applied.
  ///
  /// In most cases, use [getExerciseById] instead to get exercises with preferences.
  Future<Exercise?> getExerciseByIdWithoutPreferences(String id);

  /// Returns a single exercise by name (checks both default and custom).
  Future<Exercise?> getExerciseByName(String name);

  /// Searches exercises by name, targeting muscle groups, or category.
  ///
  /// Returns both default and custom exercises matching the query.
  Future<List<Exercise>> searchExercises(
    String query, {
    ExerciseSource source = ExerciseSource.all,
  });

  /// Returns exercises filtered by category.
  Future<List<Exercise>> getExercisesByCategory(
    ExerciseCategory category, {
    ExerciseSource source = ExerciseSource.all,
  });

  /// Returns exercises that target a specific muscle group.
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup, {
    ExerciseSource source = ExerciseSource.all,
  });

  // ============================================
  // User Exercise Preferences
  // ============================================

  /// Returns all user exercise preferences.
  Future<List<UserExercisePreferences>> getPreferences();

  /// Returns user preference for a specific exercise (if any).
  Future<UserExercisePreferences?> getPreferenceForExercise(String exerciseId);

  /// Creates or updates user preference for an exercise.
  Future<void> setPreference(UserExercisePreferences preferences);

  /// Removes user preference for an exercise.
  Future<void> removePreference(String exerciseId);

  // ============================================
  // User Notes and Photos
  // ============================================

  /// Updates user notes for an exercise.
  ///
  /// Creates preferences if they don't exist, or updates existing preferences.
  /// Pass null to clear the notes.
  Future<void> updateExerciseUserNotes(String exerciseId, String? notes);

  /// Adds a photo to an exercise.
  ///
  /// Creates preferences if they don't exist.
  /// Returns the updated preferences.
  Future<UserExercisePreferences> addExercisePhoto(
    String exerciseId,
    String photoPath,
  );

  /// Removes a photo from an exercise.
  ///
  /// Returns the updated preferences, or null if no preferences exist.
  Future<UserExercisePreferences?> removeExercisePhoto(
    String exerciseId,
    String photoPath,
  );

  /// Removes a cloud photo URL from an exercise.
  ///
  /// Returns the updated preferences, or null if no preferences exist.
  Future<UserExercisePreferences?> removeExerciseCloudPhoto(
    String exerciseId,
    String photoUrl,
  );

  /// Gets all photo paths (local and cloud) for an exercise.
  ///
  /// Returns empty list if no photos exist.
  Future<List<String>> getExercisePhotos(String exerciseId);

  /// Gets user notes for an exercise.
  ///
  /// Returns null if no user notes exist.
  Future<String?> getExerciseUserNotes(String exerciseId);

  // ============================================
  // Future: Exercise Library Integration
  // ============================================

  /// Syncs exercises from the exercise library (future feature).
  ///
  /// Imports public exercises that the user has added to their library.
  Future<void> syncFromLibrary();

  /// Publishes a custom exercise to the exercise library (future feature).
  Future<void> publishToLibrary(String exerciseId);

  // ============================================
  // Cache Management
  // ============================================

  /// Refreshes the exercise cache.
  Future<void> refreshCache();
}

/// Implementation of [ExerciseRepository].
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource localDataSource;

  /// Default exercises loaded from mock data.
  ///
  /// These are immutable and loaded once at initialization.
  late final List<Exercise> _defaultExercises;

  ExerciseRepositoryImpl._({
    required this.localDataSource,
    required List<Exercise> defaultExercises,
  }) {
    _defaultExercises = List.unmodifiable(defaultExercises);
  }

  /// Creates a development instance with mock default exercises.
  ///
  /// Uses [InMemoryExerciseLocalDataSource] by default for testing purposes.
  /// For production, use [ExerciseRepositoryImpl.production] with
  /// [ExerciseLocalDataSourceImpl] which persists data using Hive.
  factory ExerciseRepositoryImpl.development({
    ExerciseLocalDataSource? localDataSource,
  }) {
    return ExerciseRepositoryImpl._(
      localDataSource: localDataSource ?? InMemoryExerciseLocalDataSource(),
      defaultExercises: DefaultExercises.exercises,
    );
  }

  /// Creates a production instance.
  ///
  /// In production, default exercises could be loaded from a remote source.
  factory ExerciseRepositoryImpl.production({
    required ExerciseLocalDataSource localDataSource,
    List<Exercise>? defaultExercises,
  }) {
    return ExerciseRepositoryImpl._(
      localDataSource: localDataSource,
      // In production, these could come from a remote API
      defaultExercises: defaultExercises ?? DefaultExercises.exercises,
    );
  }

  // ============================================
  // Default Exercises (Read-Only)
  // ============================================

  @override
  Future<List<Exercise>> getDefaultExercises() async {
    return _defaultExercises;
  }

  // ============================================
  // Custom Exercises (Full CRUD)
  // ============================================

  @override
  Future<List<Exercise>> getCustomExercises() async {
    return localDataSource.getCachedCustomExercises();
  }

  @override
  Future<void> createCustomExercise(Exercise exercise) async {
    // Ensure the exercise is not marked as default
    if (exercise.isDefault) {
      throw ArgumentError(
        'Cannot create a custom exercise with isDefault=true',
      );
    }

    // Normalize the exercise name to title case
    var exerciseToCreate = exercise.copyWith(
      name: Utils.toTitleCase(exercise.name),
    );

    await localDataSource.cacheCustomExercise(exerciseToCreate);
  }

  @override
  Future<void> updateCustomExercise(Exercise exercise) async {
    // Check if trying to update a default exercise
    final isDefaultExercise = _defaultExercises.any((e) => e.id == exercise.id);
    if (isDefaultExercise) {
      throw ArgumentError(
        'Cannot update default exercise "${exercise.name}". '
        'Use setPreference() to customize default exercises.',
      );
    }

    // Verify the custom exercise exists
    final existing = await localDataSource.getCachedCustomExerciseById(
      exercise.id,
    );
    if (existing == null) {
      throw ArgumentError('Custom exercise with ID "${exercise.id}" not found');
    }

    await localDataSource.cacheCustomExercise(exercise);
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    // Check if trying to delete a default exercise
    final isDefaultExercise = _defaultExercises.any((e) => e.id == exerciseId);
    if (isDefaultExercise) {
      throw ArgumentError(
        'Cannot delete default exercise. Default exercises are immutable.',
      );
    }

    await localDataSource.removeCustomExercise(exerciseId);

    // Also remove any preferences for this exercise
    await localDataSource.removePreference(exerciseId);
  }

  // ============================================
  // Combined Exercise Access
  // ============================================

  @override
  Future<List<Exercise>> getExercisesWithoutPreferences({
    ExerciseSource source = ExerciseSource.all,
  }) async {
    switch (source) {
      case ExerciseSource.defaultOnly:
        return _defaultExercises;
      case ExerciseSource.customOnly:
        return getCustomExercises();
      case ExerciseSource.all:
        final custom = await getCustomExercises();
        return [..._defaultExercises, ...custom];
    }
  }

  @override
  Future<List<Exercise>> getExercises({
    ExerciseSource source = ExerciseSource.all,
  }) async {
    final exercises = await getExercisesWithoutPreferences(source: source);
    final preferences = await localDataSource.getCachedPreferences();

    // Create a map for quick preference lookup
    final preferencesMap = {
      for (final pref in preferences) pref.exerciseId: pref,
    };

    // Apply preferences to exercises
    return exercises.map((exercise) {
      final pref = preferencesMap[exercise.id];
      if (pref != null) {
        return pref.applyToExercise(exercise);
      }
      return exercise;
    }).toList();
  }

  @override
  Future<Exercise?> getExerciseByIdWithoutPreferences(String id) async {
    // Check default exercises first
    final defaultMatch = _defaultExercises
        .where((e) => e.id.toLowerCase() == id.toLowerCase())
        .firstOrNull;
    if (defaultMatch != null) return defaultMatch;

    // Check custom exercises
    return localDataSource.getCachedCustomExerciseById(id);
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    final exercise = await getExerciseByIdWithoutPreferences(id);
    if (exercise == null) return null;

    final pref = await localDataSource.getCachedPreferenceForExercise(id);
    if (pref != null) {
      return pref.applyToExercise(exercise);
    }
    return exercise;
  }

  @override
  Future<Exercise?> getExerciseByName(String name) async {
    final allExercises = await getExercises();
    return allExercises
        .where((e) => e.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }

  @override
  Future<List<Exercise>> searchExercises(
    String query, {
    ExerciseSource source = ExerciseSource.all,
  }) async {
    if (query.isEmpty) {
      return getExercises(source: source);
    }

    final exercises = await getExercises(source: source);
    final queryLower = query.toLowerCase();

    return exercises.where((exercise) {
      // Search by name
      if (exercise.name.toLowerCase().contains(queryLower)) return true;

      // Search by short name
      if (exercise.shortName?.toLowerCase().contains(queryLower) ?? false) {
        return true;
      }

      // Search by category
      if (exercise.category.displayName.toLowerCase().contains(queryLower)) {
        return true;
      }

      // Search by target muscle groups
      for (final muscle in exercise.targetMuscleGroups) {
        if (muscle.displayName.toLowerCase().contains(queryLower)) return true;
      }

      return false;
    }).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByCategory(
    ExerciseCategory category, {
    ExerciseSource source = ExerciseSource.all,
  }) async {
    final exercises = await getExercises(source: source);
    return exercises.where((e) => e.category == category).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup, {
    ExerciseSource source = ExerciseSource.all,
  }) async {
    final exercises = await getExercises(source: source);

    return exercises.where((exercise) {
      return exercise.targetMuscleGroups.contains(muscleGroup);
    }).toList();
  }

  // ============================================
  // User Exercise Preferences
  // ============================================

  @override
  Future<List<UserExercisePreferences>> getPreferences() async {
    return localDataSource.getCachedPreferences();
  }

  @override
  Future<UserExercisePreferences?> getPreferenceForExercise(
    String exerciseId,
  ) async {
    return localDataSource.getCachedPreferenceForExercise(exerciseId);
  }

  @override
  Future<void> setPreference(UserExercisePreferences preferences) async {
    // Verify the exercise exists (default or custom)
    final exercise = await getExerciseByIdWithoutPreferences(
      preferences.exerciseId,
    );
    if (exercise == null) {
      throw ArgumentError(
        'Cannot set preference for non-existent exercise: ${preferences.exerciseId}',
      );
    }

    await localDataSource.cachePreference(preferences);
  }

  @override
  Future<void> removePreference(String exerciseId) async {
    await localDataSource.removePreference(exerciseId);
  }

  // ============================================
  // User Notes and Photos
  // ============================================

  @override
  Future<void> updateExerciseUserNotes(String exerciseId, String? notes) async {
    // Verify the exercise exists
    final exercise = await getExerciseByIdWithoutPreferences(exerciseId);
    if (exercise == null) {
      throw ArgumentError(
        'Cannot update notes for non-existent exercise: $exerciseId',
      );
    }

    // Get existing preferences or create new ones
    var prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );

    if (prefs == null) {
      // Create new preferences with just the notes
      prefs = UserExercisePreferences.create(
        exerciseId: exerciseId,
        userNotes: notes,
      );
    } else {
      // Update existing preferences
      prefs = prefs.withUserNotes(notes);
    }

    await localDataSource.cachePreference(prefs);
  }

  @override
  Future<UserExercisePreferences> addExercisePhoto(
    String exerciseId,
    String photoPath,
  ) async {
    // Verify the exercise exists
    final exercise = await getExerciseByIdWithoutPreferences(exerciseId);
    if (exercise == null) {
      throw ArgumentError(
        'Cannot add photo for non-existent exercise: $exerciseId',
      );
    }

    // Get existing preferences or create new ones
    var prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );

    if (prefs == null) {
      // Create new preferences with just the photo
      prefs = UserExercisePreferences.create(
        exerciseId: exerciseId,
        localPhotoPaths: [photoPath],
        pendingPhotoUploads: [photoPath],
      );
    } else {
      // Add photo to existing preferences
      prefs = prefs.withAddedPhoto(photoPath);
    }

    await localDataSource.cachePreference(prefs);
    return prefs;
  }

  @override
  Future<UserExercisePreferences?> removeExercisePhoto(
    String exerciseId,
    String photoPath,
  ) async {
    var prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );

    if (prefs == null) return null;

    prefs = prefs.withRemovedPhoto(photoPath);
    await localDataSource.cachePreference(prefs);
    return prefs;
  }

  @override
  Future<UserExercisePreferences?> removeExerciseCloudPhoto(
    String exerciseId,
    String photoUrl,
  ) async {
    var prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );

    if (prefs == null) return null;

    prefs = prefs.withRemovedCloudPhoto(photoUrl);
    await localDataSource.cachePreference(prefs);
    return prefs;
  }

  @override
  Future<List<String>> getExercisePhotos(String exerciseId) async {
    final prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );

    if (prefs == null) return [];

    // Return both local paths and cloud URLs
    return [...prefs.localPhotoPaths, ...prefs.cloudPhotoUrls];
  }

  @override
  Future<String?> getExerciseUserNotes(String exerciseId) async {
    final prefs = await localDataSource.getCachedPreferenceForExercise(
      exerciseId,
    );
    return prefs?.userNotes;
  }

  // ============================================
  // Future: Exercise Library Integration
  // ============================================

  @override
  Future<void> syncFromLibrary() async {
    // TODO: Implement when exercise library feature is built
    throw UnimplementedError('Exercise library sync not yet implemented');
  }

  @override
  Future<void> publishToLibrary(String exerciseId) async {
    // TODO: Implement when exercise library feature is built
    throw UnimplementedError('Exercise library publish not yet implemented');
  }

  // ============================================
  // Cache Management
  // ============================================

  @override
  Future<void> refreshCache() async {
    // In development mode with in-memory cache, this is a no-op
    // In production with persistent storage, this would reload from storage
  }
}
