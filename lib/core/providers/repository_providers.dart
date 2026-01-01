import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/program_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/datasources/local/program_local_datasource.dart';
import '../../data/datasources/local/exercise_local_datasource.dart';
import '../../data/datasources/mock/mock_program_datasource.dart';
import '../../models/models.dart';

// ============================================
// Data Source Providers
// ============================================

/// Provider for MockProgramDataSource
final mockProgramDataSourceProvider = Provider<MockProgramDataSource>((ref) {
  return MockProgramDataSource();
});

/// Provider for ProgramLocalDataSource
final programLocalDataSourceProvider = Provider<ProgramLocalDataSource>((ref) {
  return ProgramLocalDataSourceImpl();
});

/// Provider for ExerciseLocalDataSource
final exerciseLocalDataSourceProvider =
    Provider<ExerciseLocalDataSource>((ref) {
  return ExerciseLocalDataSourceImpl();
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
/// Currently configured for development with mock data.
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepositoryImpl.development();
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
/// Currently configured for development with mock data.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final localDataSource = ref.watch(exerciseLocalDataSourceProvider);
  return ExerciseRepositoryImpl.development(
    localDataSource: localDataSource,
  );
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
final programByIdProvider =
    FutureProvider.family<Program?, String>((ref, id) async {
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
    FutureProvider.family<List<Program>, ProgramDifficulty>(
        (ref, difficulty) async {
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
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
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
    FutureProvider.family<List<Exercise>, ExerciseCategory>(
        (ref, category) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExercisesByCategory(category);
});

/// FutureProvider for searching exercises by name or muscle group.
///
/// **Example:**
/// ```dart
/// final results = ref.watch(searchExercisesProvider('bench press'));
/// ```
final searchExercisesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, query) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.searchExercises(query);
});
