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

/// Provider for ProgramRepository
///
/// Currently configured for development with mock data.
/// In production, use programRepositoryProductionProvider.
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

/// Provider for ExerciseRepository
///
/// Currently configured for development with mock data.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final localDataSource = ref.watch(exerciseLocalDataSourceProvider);
  return ExerciseRepositoryImpl.development(
    localDataSource: localDataSource,
  );
});

// ============================================
// Convenience Data Providers
// ============================================

/// FutureProvider for all programs
final programsProvider = FutureProvider<List<Program>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getPrograms();
});

/// FutureProvider for a single program by ID
final programByIdProvider =
    FutureProvider.family<Program?, String>((ref, id) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getProgramById(id);
});

/// FutureProvider for programs filtered by difficulty
final programsByDifficultyProvider =
    FutureProvider.family<List<Program>, ProgramDifficulty>(
        (ref, difficulty) async {
  final repository = ref.watch(programRepositoryProvider);
  return repository.getProgramsByDifficulty(difficulty);
});

/// FutureProvider for all exercises
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExercises();
});

/// FutureProvider for a single exercise by ID
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExerciseById(id);
});

/// FutureProvider for exercises by category
final exercisesByCategoryProvider =
    FutureProvider.family<List<Exercise>, ExerciseCategory>(
        (ref, category) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExercisesByCategory(category);
});

/// FutureProvider for searching exercises
final searchExercisesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, query) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.searchExercises(query);
});
