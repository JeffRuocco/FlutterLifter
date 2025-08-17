import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/program_cycle_extensions.dart';

/// Service for managing program cycles with improved date-based activation
class ProgramCycleService {
  final ProgramRepository _programRepository;

  ProgramCycleService(this._programRepository);

  /// Gets a cycle with its program details loaded
  Future<ProgramCycle?> getCycleWithProgram(String cycleId) async {
    return await _programRepository.getProgramCycleWithProgram(cycleId);
  }

  /// Gets all cycles for a program with program details loaded
  Future<List<ProgramCycle>> getCyclesForProgram(String programId) async {
    return await _programRepository.getProgramCyclesWithProgram(programId);
  }

  /// Creates a new cycle with date validation
  Future<Program> createCycleForProgram(
    String programId, {
    required DateTime startDate,
    DateTime? endDate,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) throw ArgumentError('Program not found: $programId');

    final updatedProgram = program.createCycle(
      startDate: startDate,
      endDate: endDate,
      periodicity: periodicity,
      notes: notes,
      metadata: metadata,
    );

    await _programRepository.updateProgram(updatedProgram);
    return updatedProgram;
  }

  /// Activates a cycle if it's within the valid date range
  Future<Program> activateCycleIfValid(String programId, String cycleId) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) throw ArgumentError('Program not found: $programId');

    final updatedProgram = program.activateCycle(cycleId);
    await _programRepository.updateProgram(updatedProgram);
    return updatedProgram;
  }

  /// Refreshes cycle activation for all programs based on current date
  Future<void> refreshAllProgramCycleActivations() async {
    final programs = await _programRepository.getPrograms();

    for (final program in programs) {
      final updatedProgram = program.refreshCycleActivation();
      if (updatedProgram.activeCyclesCount != program.activeCyclesCount) {
        await _programRepository.updateProgram(updatedProgram);
      }
    }
  }

  /// Gets cycles that can be activated today for a program
  Future<List<ProgramCycle>> getActivatableCyclesForProgram(
      String programId) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) return [];

    return program.getActivatableCycles();
  }

  /// Checks if a new cycle with given dates would overlap with existing cycles
  Future<bool> wouldCycleOverlap(
    String programId,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) return false;

    return program.wouldCycleOverlap(startDate, endDate);
  }

  /// Starts an immediate cycle for a program
  Future<Program> startImmediateCycleForProgram(
    String programId, {
    DateTime? endDate,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) throw ArgumentError('Program not found: $programId');

    final updatedProgram = program.startImmediateCycle(
      endDate: endDate,
      periodicity: periodicity,
      notes: notes,
      metadata: metadata,
    );

    await _programRepository.updateProgram(updatedProgram);
    return updatedProgram;
  }

  /// Example method showing how to use the loaded program data
  Future<String> getCycleDisplayInfo(String cycleId) async {
    final cycle = await getCycleWithProgram(cycleId);
    if (cycle == null) return 'Cycle not found';

    // Now you can access program details easily
    final programName = cycle.programName ?? 'Unknown Program';
    final difficulty =
        cycle.programDifficulty?.toString().split('.').last ?? 'Unknown';
    final type = cycle.programType?.toString().split('.').last ?? 'Unknown';

    return 'Cycle ${cycle.cycleNumber} of $programName ($type, $difficulty)';
  }

  /// Example method showing how to get effective workout schedule
  Future<String?> getCycleScheduleInfo(String cycleId) async {
    final cycle = await getCycleWithProgram(cycleId);
    if (cycle == null) return null;

    // Use the effective periodicity (cycle's own or program's default)
    final effectivePeriodicity = cycle.effectivePeriodicity;
    return effectivePeriodicity?.description ?? 'No schedule defined';
  }

  /// Example method showing how to check if a cycle can access program details
  Future<bool> canAccessProgramDetails(String cycleId) async {
    final cycle = await getCycleWithProgram(cycleId);
    return cycle?.hasProgramDetails ?? false;
  }

  /// Gets detailed status for all cycles in a program
  Future<Map<String, dynamic>> getProgramCycleStatus(String programId) async {
    final program = await _programRepository.getProgramById(programId);
    if (program == null) return {};

    final activatableCycles = program.getActivatableCycles();
    final activeCycle = program.activeCycle;
    final completedCycles = program.completedCycles;

    return {
      'totalCycles': program.cycles.length,
      'activeCycles': program.activeCyclesCount,
      'completedCycles': completedCycles.length,
      'activatableCycles': activatableCycles.length,
      'currentActiveCycle': activeCycle?.id,
      'hasValidCycleState': program.hasValidCycleState,
      'nextCycleNumber': program.nextCycleNumber,
    };
  }
}
