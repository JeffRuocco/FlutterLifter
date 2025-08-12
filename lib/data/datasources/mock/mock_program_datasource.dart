import '../../../models/workout_models.dart';
import 'mock_data.dart';

/// Mock data source for program-related operations
abstract class ProgramDataSource {
  Future<List<Program>> getPrograms();
  Future<Program?> getProgramById(String id);
  Future<void> createProgram(Program program);
  Future<void> updateProgram(Program program);
  Future<void> deleteProgram(String id);
  Future<List<Program>> searchPrograms(String query);
}

/// Mock implementation of ProgramDataSource
class MockProgramDataSource implements ProgramDataSource {
  static final List<Program> _programs = List.from(MockPrograms.programs);

  @override
  Future<List<Program>> getPrograms() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_programs);
  }

  @override
  Future<Program?> getProgramById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _programs.firstWhere((program) => program.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createProgram(Program program) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _programs.add(program);
  }

  @override
  Future<void> updateProgram(Program program) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _programs.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      _programs[index] = program;
    }
  }

  @override
  Future<void> deleteProgram(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _programs.removeWhere((program) => program.id == id);
  }

  @override
  Future<List<Program>> searchPrograms(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowercaseQuery = query.toLowerCase();
    return _programs.where((program) {
      return program.name.toLowerCase().contains(lowercaseQuery) ||
          (program.description?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          program.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get programs by difficulty level
  Future<List<Program>> getProgramsByDifficulty(
      ProgramDifficulty difficulty) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _programs
        .where((program) => program.difficulty == difficulty)
        .toList();
  }

  /// Get programs by type
  Future<List<Program>> getProgramsByType(ProgramType type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _programs.where((program) => program.type == type).toList();
  }

  /// Get active programs only
  Future<List<Program>> getActivePrograms() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _programs.where((program) => program.activeCycle != null).toList();
  }

  /// Get programs with periodicity
  Future<List<Program>> getProgramsWithScheduling() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _programs
        .where((program) => program.hasSchedulingPeriodicity)
        .toList();
  }

  // TODO: move this to ExerciseDataSource
  /// Get all exercises
  Future<List<Exercise>> getExercises() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockExercises.exercises);
  }

  /// Get an exercise by name
  Future<Exercise?> getExerciseByName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockExercises.getExerciseByName(name);
  }
}
