import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/exercise_history_repository.dart';
import '../../data/datasources/local/program_local_datasource.dart';
import '../../data/datasources/local/exercise_local_datasource.dart';
import '../../data/datasources/mock/mock_program_datasource.dart';
import '../../models/models.dart';
import '../../models/exercise/exercise_session_record.dart';

// ============================================
// Data Source Providers
// ============================================
// These providers respect [AppConfig.storageMode] to determine
// whether to use persistent (Hive) or in-memory storage.
//
// Change [AppConfig.storageMode] in lib/config/app_config.dart
// to switch between storage backends during development.
// ============================================

/// Provider for MockProgramDataSource
final mockProgramDataSourceProvider = Provider<MockProgramDataSource>((ref) {
  return MockProgramDataSource();
});

/// Provider for ProgramLocalDataSource
///
/// Returns Hive-backed or in-memory implementation based on [AppConfig.storageMode].
final programLocalDataSourceProvider = Provider<ProgramLocalDataSource>((ref) {
  return switch (AppConfig.storageMode) {
    StorageMode.hive => ProgramLocalDataSourceImpl(),
    StorageMode.inMemory => InMemoryProgramLocalDataSource(),
  };
});

/// Provider for ExerciseLocalDataSource
///
/// Returns Hive-backed or in-memory implementation based on [AppConfig.storageMode].
final exerciseLocalDataSourceProvider = Provider<ExerciseLocalDataSource>((
  ref,
) {
  return switch (AppConfig.storageMode) {
    StorageMode.hive => ExerciseLocalDataSourceImpl(),
    StorageMode.inMemory => InMemoryExerciseLocalDataSource(),
  };
});

// ============================================
// Repository Providers
// ============================================
// These providers give you direct access to repository instances.
// Use these when you need to call specific methods not covered by
// convenience providers (e.g., save, delete, getWithoutPreferences).
//
// Access pattern: ref.read(repositoryProvider).methodName()
// ============================================

/// Provider for [ProgramRepository] - direct repository access.
///
/// **When to use:**
/// - Saving, updating, or deleting programs
/// - Calling methods not available via convenience providers
/// - When you need full control over the repository
///
/// **Example:**
/// ```dart
/// final repo = ref.read(programRepositoryProvider);
/// await repo.saveProgram(program);
/// await repo.deleteProgram(id);
/// ```
///
/// **Prefer convenience providers when:**
/// - Just fetching programs (use [programsProvider])
/// - Fetching by ID (use [programByIdProvider])
/// - Filtering by difficulty (use [programsByDifficultyProvider])
///
/// Storage backend controlled by [AppConfig.storageMode].
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final localDataSource = ref.watch(programLocalDataSourceProvider);
  final mockDataSource = ref.watch(mockProgramDataSourceProvider);
  return ProgramRepositoryImpl(
    mockDataSource: mockDataSource,
    localDataSource: localDataSource,
    useMockData: AppConfig.useMockProgramData,
    // TODO: enable remote API when ready
    useRemoteApi: false,
  );
});

/// Provider for production ProgramRepository
///
/// Requires API and local data sources.
// final programRepositoryProductionProvider = Provider<ProgramRepository>((ref) {
//   final apiDataSource = ref.watch(programApiDataSourceProvider);
//   final localDataSource = ref.watch(programLocalDataSourceProvider);
//   return ProgramRepositoryImpl.production(
//     apiDataSource: apiDataSource,
//     localDataSource: localDataSource,
//   );
// });

/// Provider for [ExerciseRepository] - direct repository access.
///
/// **When to use:**
/// - Saving, updating, or deleting exercises
/// - Getting exercises without user preferences ([getExercisesWithoutPreferences])
/// - Calling methods not available via convenience providers
///
/// **Example:**
/// ```dart
/// final repo = ref.read(exerciseRepositoryProvider);
/// await repo.saveExercise(exercise);
/// await repo.deleteExercise(id);
/// ```
///
/// **Prefer convenience providers when:**
/// - Fetching all exercises with preferences (use [exercisesProvider])
/// - Fetching by ID (use [exerciseByIdProvider])
/// - Filtering by category (use [exercisesByCategoryProvider])
/// - Searching exercises (use [searchExercisesProvider])
///
/// Storage backend controlled by [AppConfig.storageMode].
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final localDataSource = ref.watch(exerciseLocalDataSourceProvider);
  return ExerciseRepositoryImpl.production(localDataSource: localDataSource);
});

/// Provider for [ExerciseHistoryRepository] - direct repository access.
///
/// **When to use:**
/// - Fetching exercise history and PR data
/// - Recording completed workout sessions
/// - Getting PR progression for charts
///
/// **Example:**
/// ```dart
/// final repo = ref.read(exerciseHistoryRepositoryProvider);
/// final history = await repo.getExerciseHistory(exercise);
/// ```
///
/// Currently configured for development with mock data.
final exerciseHistoryRepositoryProvider = Provider<ExerciseHistoryRepository>((
  ref,
) {
  return DevExerciseHistoryRepository();
});

// ============================================
// Convenience Data Providers (FutureProviders)
// ============================================
// These providers wrap common repository calls with built-in async handling.
// They automatically provide loading, data, and error states via AsyncValue.
//
// Use these for simple data fetching in widgets - no manual async/await needed.
//
// Access pattern: ref.watch(provider).when(data: ..., loading: ..., error: ...)
// ============================================

/// FutureProvider for all programs - async with loading/error states.
///
/// **When to use:**
/// - Displaying a list of all programs in UI
/// - When you need automatic loading spinners and error handling
///
/// **Example:**
/// ```dart
/// final programsAsync = ref.watch(programsProvider);
/// programsAsync.when(
///   data: (programs) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// **Use [programRepositoryProvider] instead when:**
/// - Saving, updating, or deleting programs
/// - You need methods beyond simple fetching
final programsProvider = FutureProvider<List<Program>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getPrograms();
});

/// FutureProvider for a single program by ID.
///
/// **Example:**
/// ```dart
/// final programAsync = ref.watch(programByIdProvider('program-123'));
/// ```
final programByIdProvider = FutureProvider.family<Program?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getProgramById(id);
});

/// FutureProvider for programs filtered by difficulty.
///
/// **Example:**
/// ```dart
/// final beginnerPrograms = ref.watch(
///   programsByDifficultyProvider(ProgramDifficulty.beginner),
/// );
/// ```
final programsByDifficultyProvider =
    FutureProvider.family<List<Program>, ProgramDifficulty>((
      ref,
      difficulty,
    ) async {
      final repository = ref.watch(programRepositoryProvider);
      return repository.getProgramsByDifficulty(difficulty);
    });

/// FutureProvider for all exercises - async with loading/error states.
///
/// Returns exercises from [ExerciseRepository.getExercises],
/// which includes user preferences (custom defaults, favorites, etc.).
///
/// **When to use:**
/// - Displaying a list of exercises in UI (most common case)
/// - When you need automatic loading spinners and error handling
/// - When exercises should reflect user's saved preferences
///
/// **Example:**
/// ```dart
/// final exercisesAsync = ref.watch(exercisesProvider);
/// exercisesAsync.when(
///   data: (exercises) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
///
/// **Use [exerciseRepositoryProvider] instead when:**
/// - Saving, updating, or deleting exercises
/// - You need exercises without user preferences applied
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExercises();
});

/// FutureProvider for a single exercise by ID.
///
/// **Example:**
/// ```dart
/// final exerciseAsync = ref.watch(exerciseByIdProvider('exercise-456'));
/// ```
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExerciseById(id);
});

/// FutureProvider for exercises filtered by category.
///
/// **Example:**
/// ```dart
/// final chestExercises = ref.watch(
///   exercisesByCategoryProvider(ExerciseCategory.chest),
/// );
/// ```
final exercisesByCategoryProvider =
    FutureProvider.family<List<Exercise>, ExerciseCategory>((
      ref,
      category,
    ) async {
      final repository = ref.watch(exerciseRepositoryProvider);
      return repository.getExercisesByCategory(category);
    });

/// FutureProvider for searching exercises by name or muscle group.
///
/// **Example:**
/// ```dart
/// final results = ref.watch(searchExercisesProvider('bench press'));
/// ```
final searchExercisesProvider = FutureProvider.family<List<Exercise>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.searchExercises(query);
});

// ============================================
// Exercise History Providers
// ============================================

/// FutureProvider for the all-time PR (Epley score) for an exercise.
///
/// Returns the highest Epley score achieved for the given exercise ID.
/// Returns null if no history exists for this exercise.
///
/// **Example:**
/// ```dart
/// final prAsync = ref.watch(exercisePRProvider('bench-press'));
/// prAsync.when(
///   data: (pr) => pr != null ? Text('PR: ${pr.toStringAsFixed(0)}') : null,
///   loading: () => null,
///   error: (e, _) => null,
/// );
/// ```
final exercisePRProvider = FutureProvider.family<double?, String>((
  ref,
  exerciseId,
) async {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  return repository.getAllTimePR(exerciseId);
});

/// FutureProvider for the most recent session for an exercise.
///
/// Returns the last ExerciseSessionRecord for the given exercise ID.
/// Useful for showing "Last time" performance in workout screens.
///
/// **Example:**
/// ```dart
/// final lastSessionAsync = ref.watch(lastExerciseSessionProvider('bench-press'));
/// ```
final lastExerciseSessionProvider =
    FutureProvider.family<ExerciseSessionRecord?, String>((
      ref,
      exerciseId,
    ) async {
      final repository = ref.watch(exerciseHistoryRepositoryProvider);
      final sessions = await repository.getRecentSessions(exerciseId, limit: 1);
      return sessions.isNotEmpty ? sessions.first : null;
    });

// ============================================
// Exercise User Preferences Providers
// ============================================

/// FutureProvider for user exercise preferences.
///
/// Returns the user's custom preferences for an exercise, including
/// custom notes, photos, and preferred settings.
///
/// **Example:**
/// ```dart
/// final prefsAsync = ref.watch(exercisePreferencesProvider('bench-press'));
/// ```
final exercisePreferencesProvider =
    FutureProvider.family<UserExercisePreferences?, String>((
      ref,
      exerciseId,
    ) async {
      final repository = ref.watch(exerciseRepositoryProvider);
      return repository.getPreferenceForExercise(exerciseId);
    });

/// FutureProvider for exercise photos.
///
/// Returns all photos (local and cloud) for an exercise.
///
/// **Example:**
/// ```dart
/// final photosAsync = ref.watch(exercisePhotosProvider('bench-press'));
/// ```
final exercisePhotosProvider = FutureProvider.family<List<String>, String>((
  ref,
  exerciseId,
) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExercisePhotos(exerciseId);
});

/// FutureProvider for exercise user notes.
///
/// Returns the user's personal notes for an exercise.
///
/// **Example:**
/// ```dart
/// final notesAsync = ref.watch(exerciseUserNotesProvider('bench-press'));
/// ```
final exerciseUserNotesProvider = FutureProvider.family<String?, String>((
  ref,
  exerciseId,
) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExerciseUserNotes(exerciseId);
});

// ============================================
// Program Library Providers
// ============================================

/// FutureProvider for the currently active program cycle.
///
/// Returns the single active cycle across all programs, or null if none.
/// Only one cycle can be active at a time in the app.
///
/// **Example:**
/// ```dart
/// final activeCycleAsync = ref.watch(activeCycleProvider);
/// activeCycleAsync.when(
///   data: (cycle) => cycle != null
///     ? Text('Active: ${cycle.program?.name}')
///     : Text('No active program'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final activeCycleProvider = FutureProvider<ProgramCycle?>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getActiveCycle();
});

/// FutureProvider for recently used programs.
///
/// Returns programs sorted by lastUsedAt, most recent first.
/// Limited to 5 programs by default.
///
/// **Example:**
/// ```dart
/// final recentAsync = ref.watch(recentProgramsProvider);
/// ```
final recentProgramsProvider = FutureProvider<List<Program>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getRecentPrograms(limit: 5);
});

/// FutureProvider for default (built-in) programs.
///
/// **Example:**
/// ```dart
/// final defaultPrograms = ref.watch(defaultProgramsProvider);
/// ```
final defaultProgramsProvider = FutureProvider<List<Program>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getDefaultPrograms();
});

/// FutureProvider for custom (user-created) programs.
///
/// **Example:**
/// ```dart
/// final customPrograms = ref.watch(customProgramsProvider);
/// ```
final customProgramsProvider = FutureProvider<List<Program>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getCustomPrograms();
});

/// FutureProvider for programs filtered by source.
///
/// **Example:**
/// ```dart
/// final programs = ref.watch(programsBySourceProvider(ProgramSource.defaultOnly));
/// ```
final programsBySourceProvider =
    FutureProvider.family<List<Program>, ProgramSource>((ref, source) async {
      final repository = ref.watch(programRepositoryProvider);
      return repository.getProgramsBySource(source: source);
    });
