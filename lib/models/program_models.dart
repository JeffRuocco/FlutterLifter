import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/theme_extensions.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';
import 'package:flutter_lifter/utils/utils.dart';
import 'package:hugeicons/hugeicons.dart';

/// Represents the scheduling periodicity for workout sessions in a program
class WorkoutPeriodicity {
  final PeriodicityType type;

  // For weekly scheduling - list of weekdays (1=Monday, 7=Sunday)
  final List<int>? weeklyDays;

  // For cyclic scheduling - number of workout days followed by rest days
  final int? workoutDays;
  final int? restDays;

  // For interval scheduling - workout every X days
  final int? intervalDays;

  // For custom scheduling - specific dates or patterns
  final Map<String, dynamic>? customPattern;

  const WorkoutPeriodicity({
    required this.type,
    this.weeklyDays,
    this.workoutDays,
    this.restDays,
    this.intervalDays,
    this.customPattern,
  });

  /// Creates a weekly periodicity (e.g., Monday, Wednesday, Friday)
  /// [days] is a list of integers representing the days of the week (1=Monday, 7=Sunday)
  const WorkoutPeriodicity.weekly(List<int> days)
    : type = PeriodicityType.weekly,
      weeklyDays = days,
      workoutDays = null,
      restDays = null,
      intervalDays = null,
      customPattern = null;

  /// Creates a cyclic periodicity (e.g., 3 days on, 1 day rest)
  const WorkoutPeriodicity.cyclic({
    required int this.workoutDays,
    required int this.restDays,
  }) : type = PeriodicityType.cyclic,
       weeklyDays = null,
       intervalDays = null,
       customPattern = null;

  /// Creates an interval periodicity (e.g., every 2 days)
  const WorkoutPeriodicity.interval(int days)
    : type = PeriodicityType.interval,
      weeklyDays = null,
      workoutDays = null,
      restDays = null,
      intervalDays = days,
      customPattern = null;

  /// Creates a custom periodicity with flexible patterns
  const WorkoutPeriodicity.custom(Map<String, dynamic> pattern)
    : type = PeriodicityType.custom,
      weeklyDays = null,
      workoutDays = null,
      restDays = null,
      intervalDays = null,
      customPattern = pattern;

  /// Returns a human-readable description of the periodicity
  String get description {
    switch (type) {
      case PeriodicityType.weekly:
        if (weeklyDays == null || weeklyDays!.isEmpty) return 'No schedule';
        final dayNames = weeklyDays!.map(_getDayName).join(', ');
        return 'Every $dayNames';

      case PeriodicityType.cyclic:
        if (workoutDays == null || restDays == null) return 'Invalid cycle';
        return '$workoutDays days on, $restDays days rest';

      case PeriodicityType.interval:
        if (intervalDays == null) return 'Invalid interval';
        return 'Every $intervalDays days';

      case PeriodicityType.custom:
        return 'Custom schedule';
    }
  }

  /// Returns the frequency per week for display purposes
  String get frequencyDescription {
    switch (type) {
      case PeriodicityType.weekly:
        final count = weeklyDays?.length ?? 0;
        return '$count days/week';

      case PeriodicityType.cyclic:
        if (workoutDays == null || restDays == null) return 'Variable';
        final cycleLength = workoutDays! + restDays!;
        final weeklyFreq = (workoutDays! / cycleLength * 7).round();
        return '~$weeklyFreq days/week';

      case PeriodicityType.interval:
        if (intervalDays == null) return 'Variable';
        final weeklyFreq = (7 / intervalDays!).round();
        return '~$weeklyFreq days/week';

      case PeriodicityType.custom:
        return 'Variable';
    }
  }

  /// Generates workout dates for a given period based on the periodicity
  List<DateTime> generateWorkoutDates(DateTime startDate, DateTime endDate) {
    final workoutDates = <DateTime>[];

    switch (type) {
      case PeriodicityType.weekly:
        _generateWeeklyDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.cyclic:
        _generateCyclicDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.interval:
        _generateIntervalDates(startDate, endDate, workoutDates);
        break;

      case PeriodicityType.custom:
        _generateCustomDates(startDate, endDate, workoutDates);
        break;
    }

    return workoutDates;
  }

  void _generateWeeklyDates(
    DateTime startDate,
    DateTime endDate,
    List<DateTime> workoutDates,
  ) {
    if (weeklyDays == null || weeklyDays!.isEmpty) return;

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (weeklyDays!.contains(currentDate.weekday)) {
        workoutDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  void _generateCyclicDates(
    DateTime startDate,
    DateTime endDate,
    List<DateTime> workoutDates,
  ) {
    if (workoutDays == null || restDays == null) return;

    var currentDate = startDate;
    var dayInCycle = 0;
    final cycleLength = workoutDays! + restDays!;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (dayInCycle < workoutDays!) {
        workoutDates.add(currentDate);
      }

      currentDate = currentDate.add(const Duration(days: 1));
      dayInCycle = (dayInCycle + 1) % cycleLength;
    }
  }

  void _generateIntervalDates(
    DateTime startDate,
    DateTime endDate,
    List<DateTime> workoutDates,
  ) {
    if (intervalDays == null) return;

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      workoutDates.add(currentDate);
      currentDate = currentDate.add(Duration(days: intervalDays!));
    }
  }

  void _generateCustomDates(
    DateTime startDate,
    DateTime endDate,
    List<DateTime> workoutDates,
  ) {
    // Custom implementation would depend on the specific pattern stored in customPattern
    // This is a placeholder for future custom scheduling logic
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Creates a copy of this periodicity with updated values
  WorkoutPeriodicity copyWith({
    PeriodicityType? type,
    List<int>? weeklyDays,
    int? workoutDays,
    int? restDays,
    int? intervalDays,
    Map<String, dynamic>? customPattern,
  }) {
    return WorkoutPeriodicity(
      type: type ?? this.type,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      workoutDays: workoutDays ?? this.workoutDays,
      restDays: restDays ?? this.restDays,
      intervalDays: intervalDays ?? this.intervalDays,
      customPattern: customPattern ?? this.customPattern,
    );
  }

  /// Creates WorkoutPeriodicity from JSON
  factory WorkoutPeriodicity.fromJson(Map<String, dynamic> json) {
    final type = PeriodicityType.values.firstWhere(
      (e) => e.toString() == 'PeriodicityType.${json['type']}',
      orElse: () => PeriodicityType.weekly,
    );

    return WorkoutPeriodicity(
      type: type,
      weeklyDays: json['weeklyDays'] != null
          ? List<int>.from(json['weeklyDays'])
          : null,
      workoutDays: json['workoutDays'],
      restDays: json['restDays'],
      intervalDays: json['intervalDays'],
      customPattern: json['customPattern'],
    );
  }

  /// Converts WorkoutPeriodicity to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'weeklyDays': weeklyDays,
      'workoutDays': workoutDays,
      'restDays': restDays,
      'intervalDays': intervalDays,
      'customPattern': customPattern,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutPeriodicity &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _listEquals(weeklyDays, other.weeklyDays) &&
          workoutDays == other.workoutDays &&
          restDays == other.restDays &&
          intervalDays == other.intervalDays;

  @override
  int get hashCode => Object.hash(
    type,
    weeklyDays,
    workoutDays,
    restDays,
    intervalDays,
    customPattern,
  );

  @override
  String toString() {
    return 'WorkoutPeriodicity{type: $type, description: $description}';
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Represents a cycle of a program with specific start and end dates
class ProgramCycle {
  /// The unique identifier for this cycle
  final String id;

  /// The program associated with this cycle
  final String programId;

  /// The cycle number within the program
  final int cycleNumber;

  /// The start date of the cycle
  final DateTime startDate;

  /// The end date of the cycle
  final DateTime? endDate;

  /// Whether the cycle is currently active
  final bool isActive;

  /// Whether the cycle has been completed
  final bool isCompleted;

  /// The list of scheduled workout sessions
  final List<WorkoutSession> scheduledSessions;

  /// The periodicity of workouts in this cycle
  final WorkoutPeriodicity? periodicity;

  /// Any additional notes for this cycle
  final String? notes;

  /// The date when this cycle was created
  final DateTime createdAt;

  /// Optional reference to the full program (not stored, only for runtime use)
  Program? _program;

  ProgramCycle({
    required this.id,
    required this.programId,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isCompleted = false,
    this.scheduledSessions = const [],
    this.periodicity,
    this.notes,
    required this.createdAt,
  });

  /// Named constructor for creating new program cycles with auto-generated ID
  ProgramCycle.create({
    required this.programId,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.isCompleted = false,
    this.scheduledSessions = const [],
    this.periodicity,
    this.notes,
  }) : id = Utils.generateId(),
       createdAt = DateTime.now();

  /// Returns the duration of the cycle in days
  int? get durationInDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// Returns the duration of the cycle in weeks
  int? get durationInWeeks {
    final days = durationInDays;
    if (days == null) return null;
    return (days / 7).ceil();
  }

  /// Returns whether the cycle is currently running
  bool get isCurrentlyActive {
    if (!isActive || isCompleted) return false;
    final now = DateTime.now();
    return isWithinDateRange(now);
  }

  /// Checks if a date is within this cycle's date range
  bool isWithinDateRange(DateTime date) {
    final effectiveEndDate =
        endDate ?? startDate.add(const Duration(days: 365));
    return !date.isBefore(startDate) && !date.isAfter(effectiveEndDate);
  }

  /// Checks if this cycle can be activated on the given date
  bool canBeActivatedOn(DateTime date) {
    return isWithinDateRange(date) && !isCompleted;
  }

  /// Gets the effective end date (actual end date or default)
  DateTime get effectiveEndDate {
    return endDate ?? startDate.add(const Duration(days: 365));
  }

  /// Sets the program reference for runtime use (not persisted)
  void setProgram(Program program) {
    if (program.id == programId) {
      _program = program;
    }
  }

  /// Gets the cached program reference (may be null)
  Program? get program => _program;

  /// Loads the program from a repository if not already cached
  Future<Program?> loadProgram(
    Future<Program?> Function(String) programLoader,
  ) async {
    if (_program != null) return _program;
    _program = await programLoader(programId);
    return _program;
  }

  /// Returns the total number of scheduled workouts in this cycle
  int get totalWorkoutsCount => scheduledSessions.length;

  /// Returns the number of completed workouts in this cycle
  int get completedWorkoutsCount =>
      scheduledSessions.where((session) => session.isCompleted).length;

  /// Returns the cycle completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (scheduledSessions.isEmpty) return 0.0;
    return completedWorkoutsCount / totalWorkoutsCount;
  }

  /// Return the current workout session in this cycle
  WorkoutSession? get currentWorkoutSession {
    final now = DateTime.now();
    return scheduledSessions
        .where((session) => !session.isCompleted && !session.date.isAfter(now))
        .fold<WorkoutSession?>(null, (latest, session) {
          if (latest == null || session.date.isAfter(latest.date)) {
            return session;
          }
          return latest;
        });
  }

  /// Returns the next scheduled workout session in this cycle
  WorkoutSession? get nextWorkout {
    final now = DateTime.now();
    return scheduledSessions
        .where((session) => !session.isCompleted && session.date.isAfter(now))
        .fold<WorkoutSession?>(null, (next, session) {
          if (next == null || session.date.isBefore(next.date)) {
            return session;
          }
          return next;
        });
  }

  /// Returns the most recent completed workout in this cycle
  WorkoutSession? get lastCompletedWorkout {
    return scheduledSessions
        .where((session) => session.isCompleted)
        .fold<WorkoutSession?>(null, (latest, session) {
          if (latest == null || session.date.isAfter(latest.date)) {
            return session;
          }
          return latest;
        });
  }

  /// Returns workouts scheduled for a specific week in this cycle
  List<WorkoutSession> getWorkoutsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return scheduledSessions
        .where(
          (session) =>
              session.date.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              session.date.isBefore(weekEnd),
        )
        .toList();
  }

  /// Returns workouts scheduled for a specific date in this cycle
  List<WorkoutSession> getWorkoutsForDate(DateTime date) {
    return scheduledSessions
        .where(
          (session) =>
              session.date.year == date.year &&
              session.date.month == date.month &&
              session.date.day == date.day,
        )
        .toList();
  }

  /// Checks if a workout is expected on a specific date for the cycle's periodicity
  bool isWorkoutExpectedOnDate(DateTime date) {
    if (periodicity == null) return false;

    // Normalize the date to remove time components
    final checkDate = DateTime(date.year, date.month, date.day);

    // For the cycle's date range, we check if the date falls within a workout day
    final cycleEndDate = endDate ?? startDate.add(const Duration(days: 365));

    // Generate all workout dates for this cycle
    final workoutDates = periodicity!.generateWorkoutDates(
      startDate,
      cycleEndDate,
    );

    // Check if the specific date is in the list of workout dates
    return workoutDates.any(
      (workoutDate) =>
          workoutDate.year == checkDate.year &&
          workoutDate.month == checkDate.month &&
          workoutDate.day == checkDate.day,
    );
  }

  /// Adds a new workout session to this cycle
  ProgramCycle addWorkoutSession(WorkoutSession session) {
    return copyWith(scheduledSessions: [...scheduledSessions, session]);
  }

  /// Removes a workout session from this cycle
  ProgramCycle removeWorkoutSession(String sessionId) {
    return copyWith(
      scheduledSessions: scheduledSessions
          .where((session) => session.id != sessionId)
          .toList(),
    );
  }

  /// Updates a workout session in this cycle
  ProgramCycle updateWorkoutSession(WorkoutSession updatedSession) {
    final updatedSessions = scheduledSessions
        .map(
          (session) =>
              session.id == updatedSession.id ? updatedSession : session,
        )
        .toList();
    return copyWith(scheduledSessions: updatedSessions);
  }

  /// Generates and schedules workout sessions for this cycle based on program's periodicity
  ProgramCycle generateScheduledSessions({bool replaceExisting = false}) {
    final cycleEndDate =
        endDate ?? startDate.add(const Duration(days: 84)); // Default 12 weeks

    List<WorkoutSession> newSessions = [];
    if (!replaceExisting) {
      newSessions = List.from(scheduledSessions);
    }

    // Generate workout dates based on periodicity
    final workoutDates =
        periodicity?.generateWorkoutDates(startDate, cycleEndDate) ?? [];

    // Create workout sessions for each date
    for (final date in workoutDates) {
      // Skip if session already exists for this date (when not replacing)
      if (!replaceExisting &&
          scheduledSessions.any(
            (session) =>
                session.date.year == date.year &&
                session.date.month == date.month &&
                session.date.day == date.day,
          )) {
        continue;
      }

      final session = WorkoutSession.create(
        programId: programId,
        programName: null, // Will be filled when linked to program
        date: date,
        metadata: {'cycleId': id, 'cycleNumber': cycleNumber},
      );
      newSessions.add(session);
    }

    return copyWith(
      scheduledSessions: newSessions,
      endDate: endDate ?? cycleEndDate,
    );
  }

  /// Starts the cycle (only if not completed and within date range)
  ProgramCycle start({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    if (isCompleted) {
      throw StateError('Cannot start a completed cycle');
    }
    if (!canBeActivatedOn(now)) {
      throw StateError('Cycle cannot be started: outside valid date range');
    }

    return copyWith(isActive: true, isCompleted: false);
  }

  /// Stops/pauses the cycle
  ProgramCycle stop() {
    return copyWith(isActive: false);
  }

  /// Completes the cycle (alias for markCompleted for consistency)
  ProgramCycle complete() {
    return copyWith(
      isCompleted: true,
      isActive: false,
      endDate: endDate ?? DateTime.now(),
    );
  }

  /// Creates a copy of this cycle with updated values
  ProgramCycle copyWith({
    String? id,
    int? cycleNumber,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isCompleted,
    List<WorkoutSession>? scheduledSessions,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    final copy = ProgramCycle(
      id: id ?? this.id,
      programId: programId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledSessions: scheduledSessions ?? this.scheduledSessions,
      periodicity: periodicity ?? this.periodicity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
    // Preserve the program reference if it exists
    if (_program != null) {
      copy.setProgram(_program!);
    }
    return copy;
  }

  /// Creates a ProgramCycle from JSON
  factory ProgramCycle.fromJson(Map<String, dynamic> json) {
    return ProgramCycle(
      id: json['id'],
      programId: json['programId'],
      cycleNumber: json['cycleNumber'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      isCompleted: json['isCompleted'] ?? false,
      scheduledSessions: json['scheduledSessions'] != null
          ? (json['scheduledSessions'] as List)
                .map((sessionJson) => WorkoutSession.fromJson(sessionJson))
                .toList()
          : [],
      periodicity: json['periodicity'] != null
          ? WorkoutPeriodicity.fromJson(json['periodicity'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Converts ProgramCycle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'cycleNumber': cycleNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'scheduledSessions': scheduledSessions
          .map((session) => session.toJson())
          .toList(),
      'periodicity': periodicity?.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramCycle &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProgramCycle{id: $id, programId: $programId, cycleNumber: $cycleNumber, '
        'startDate: $startDate, endDate: $endDate, isActive: $isActive, '
        'isCompleted: $isCompleted, workoutsCount: ${scheduledSessions.length}}';
  }
}

/// Represents a fitness program template that can be used to create program cycles
class Program {
  final String id;
  final String name;
  final String? description;
  final ProgramType type;
  final ProgramDifficulty difficulty;
  final WorkoutPeriodicity? defaultPeriodicity;
  final DateTime createdAt;
  final String? createdBy;
  final bool isPublic;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  /// List of program cycles - each cycle represents a run of this program
  final List<ProgramCycle> cycles;

  Program({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    this.defaultPeriodicity,
    required this.createdAt,
    this.createdBy,
    this.isPublic = false,
    this.tags = const [],
    this.imageUrl,
    this.metadata,
    this.cycles = const [],
  });

  /// Named constructor for creating new programs with auto-generated ID
  Program.create({
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    required this.defaultPeriodicity,
    this.createdBy,
    this.isPublic = false,
    this.tags = const [],
    this.imageUrl,
    this.metadata,
    this.cycles = const [],
  }) : id = Utils.generateId(),
       createdAt = DateTime.now();

  /// Returns the most recently completed cycle
  ProgramCycle? get lastCompletedCycle {
    return cycles.where((cycle) => cycle.isCompleted).fold<ProgramCycle?>(
      null,
      (latest, cycle) {
        if (latest == null || cycle.createdAt.isAfter(latest.createdAt)) {
          return cycle;
        }
        return latest;
      },
    );
  }

  /// Returns the next cycle number
  int get nextCycleNumber {
    if (cycles.isEmpty) return 1;
    return cycles
            .map((cycle) => cycle.cycleNumber)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  /// Returns all cycles for this program
  List<ProgramCycle> get allCycles => List.unmodifiable(cycles);

  /// Returns the single active cycle (null if none active)
  ProgramCycle? get activeCycle {
    final activeCycles = cycles.where((cycle) => cycle.isActive);
    return activeCycles.isNotEmpty ? activeCycles.first : null;
  }

  /// Returns only completed cycles
  List<ProgramCycle> get completedCycles =>
      cycles.where((cycle) => cycle.isCompleted).toList();

  /// Validates that only one cycle is active at a time
  bool get hasValidCycleState {
    return cycles.where((cycle) => cycle.isActive).length <= 1;
  }

  /// Returns the number of active cycles (should always be 0 or 1)
  int get activeCyclesCount =>
      allCycles.where((cycle) => cycle.isActive).length;

  /// Returns the last completed workout session in the active cycle
  WorkoutSession? get lastCompletedWorkoutSession =>
      activeCycle?.lastCompletedWorkout;

  /// Validates that a new cycle's date range doesn't overlap with existing cycles
  bool _validateCycleDateRange(DateTime startDate, DateTime? endDate) {
    final effectiveEndDate =
        endDate ?? startDate.add(const Duration(days: 365));

    return !cycles.any((existingCycle) {
      final existingEnd =
          existingCycle.endDate ??
          existingCycle.startDate.add(const Duration(days: 365));

      // Check for overlap: new cycle starts before existing ends AND new cycle ends after existing starts
      return startDate.isBefore(existingEnd) &&
          effectiveEndDate.isAfter(existingCycle.startDate);
    });
  }

  /// Gets cycles that should be active based on current date
  List<ProgramCycle> _getCyclesValidForActivation({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    return cycles.where((cycle) {
      if (cycle.isCompleted) return false;
      final effectiveEndDate =
          cycle.endDate ?? cycle.startDate.add(const Duration(days: 365));
      return !cycle.startDate.isAfter(now) && !effectiveEndDate.isBefore(now);
    }).toList();
  }

  /// Updates cycle activation status based on date ranges
  Program _updateCycleActivationByDate({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final validCycles = _getCyclesValidForActivation(currentDate: now);

    final updatedCycles = cycles.map((cycle) {
      final shouldBeActive = validCycles.contains(cycle) && !cycle.isCompleted;
      if (cycle.isActive != shouldBeActive && !cycle.isCompleted) {
        return shouldBeActive ? cycle.start(currentDate: now) : cycle.stop();
      }
      return cycle;
    }).toList();

    return copyWith(cycles: updatedCycles);
  }

  /// Adds a cycle to this program with date range validation
  /// Throws ArgumentError if date ranges overlap
  Program addCycle(ProgramCycle cycle) {
    // Validate date range
    if (!_validateCycleDateRange(cycle.startDate, cycle.endDate)) {
      throw ArgumentError('Cycle date range overlaps with existing cycle');
    }

    final updatedCycles = [...cycles, cycle];
    return copyWith(cycles: updatedCycles)._updateCycleActivationByDate();
  }

  /// Creates and adds a new cycle to this program with date range validation
  /// Throws ArgumentError if date ranges overlap
  Program createCycle({
    required DateTime startDate,
    DateTime? endDate,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    // Validate date range
    if (!_validateCycleDateRange(startDate, endDate)) {
      throw ArgumentError('Cycle date range overlaps with existing cycle');
    }

    final newCycle = ProgramCycle.create(
      programId: id,
      cycleNumber: nextCycleNumber,
      startDate: startDate,
      endDate: endDate,
      periodicity: periodicity ?? defaultPeriodicity,
      notes: notes,
    );

    return addCycle(newCycle);
  }

  /// Removes a cycle from this program
  Program removeCycle(String cycleId) {
    return copyWith(
      cycles: cycles.where((cycle) => cycle.id != cycleId).toList(),
    );
  }

  /// Updates a cycle in this program and refreshes activation based on dates
  Program updateCycle(ProgramCycle updatedCycle) {
    final updatedCycles = cycles.map((cycle) {
      return cycle.id == updatedCycle.id ? updatedCycle : cycle;
    }).toList();

    return copyWith(cycles: updatedCycles)._updateCycleActivationByDate();
  }

  /// Forces activation of a specific cycle if it's within valid date range
  /// Returns the program unchanged if the cycle cannot be activated
  Program activateCycle(String cycleId, {DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final targetCycle = cycles.firstWhere(
      (cycle) => cycle.id == cycleId,
      orElse: () => throw ArgumentError('Cycle not found: $cycleId'),
    );

    // Check if cycle is within valid date range for activation
    final effectiveEndDate =
        targetCycle.endDate ??
        targetCycle.startDate.add(const Duration(days: 365));

    if (targetCycle.startDate.isAfter(now) || effectiveEndDate.isBefore(now)) {
      throw ArgumentError(
        'Cycle cannot be activated: outside valid date range',
      );
    }

    final updatedCycles = cycles.map((cycle) {
      if (cycle.id == cycleId) {
        return cycle.start();
      } else if (cycle.isActive) {
        return cycle.stop();
      }
      return cycle;
    }).toList();

    return copyWith(cycles: updatedCycles);
  }

  /// Updates all cycle activation statuses based on their date ranges
  Program refreshCycleActivation({DateTime? currentDate}) {
    return _updateCycleActivationByDate(currentDate: currentDate);
  }

  /// Completes the current active cycle
  Program completeCurrentCycle() {
    if (activeCycle == null) return this;

    final completedCycle = activeCycle!.complete();
    return updateCycle(completedCycle);
  }

  /// Creates a new cycle starting immediately (convenience method)
  Program startImmediateCycle({
    DateTime? endDate,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return createCycle(
      startDate: DateTime.now(),
      endDate: endDate,
      periodicity: periodicity,
      notes: notes,
      metadata: metadata,
    );
  }

  /// Gets cycles that are eligible for activation (within date range)
  List<ProgramCycle> getActivatableCycles({DateTime? currentDate}) {
    return _getCyclesValidForActivation(currentDate: currentDate);
  }

  /// Checks if a cycle with the given date range would overlap with existing cycles
  bool wouldCycleOverlap(DateTime startDate, DateTime? endDate) {
    return !_validateCycleDateRange(startDate, endDate);
  }

  /// Returns the expected frequency description from default periodicity
  String get frequencyDescription {
    return defaultPeriodicity?.frequencyDescription ?? 'No schedule';
  }

  /// Returns the default periodicity description
  String get periodicityDescription {
    return defaultPeriodicity?.description ?? 'No periodicity defined';
  }

  /// Returns whether this program has a defined default periodicity
  bool get hasSchedulingPeriodicity => defaultPeriodicity != null;

  /// Returns the next expected workout date based on default periodicity
  DateTime? getNextExpectedWorkoutDate({DateTime? fromDate}) {
    if (defaultPeriodicity == null) return null;

    final from = fromDate ?? DateTime.now();
    final futureEnd = from.add(const Duration(days: 365)); // Look ahead 1 year

    final futureDates = defaultPeriodicity!.generateWorkoutDates(
      from,
      futureEnd,
    );
    return futureDates.isNotEmpty ? futureDates.first : null;
  }

  /// Checks if a workout is expected on a specific date for the active cycle
  /// Returns false if no active cycle exists or no periodicity is defined
  bool isWorkoutExpectedOnDate(DateTime date) {
    if (activeCycle == null || activeCycle!.periodicity == null) return false;
    return activeCycle!.isWorkoutExpectedOnDate(date);
  }

  /// Returns the program color, falling back to the app's primary color
  Color getColor(BuildContext context) {
    if (metadata != null && metadata!.containsKey('color')) {
      return metadata!['color'] as Color;
    }
    // Return theme-aware primary color using your theme extension
    return context.primaryColor;
  }

  /// Stores the program color in metadata
  Program storeColor(Color color) {
    var updatedMetadata = {...?metadata, 'color': color};
    return copyWith(metadata: updatedMetadata);
  }

  /// Returns the program icon, falling back to a default icon
  HugeIconData get icon {
    if (metadata != null && metadata!.containsKey('icon')) {
      return metadata!['icon'] as HugeIconData;
    }
    // Return a default icon
    return HugeIcons.strokeRoundedDumbbell01;
  }

  /// Stores the program icon in metadata
  Program storeIcon(HugeIconData icon) {
    var updatedMetadata = {...?metadata, 'icon': icon};
    return copyWith(metadata: updatedMetadata);
  }

  /// Creates a copy of this program with updated values
  Program copyWith({
    String? id,
    String? name,
    String? description,
    ProgramType? type,
    ProgramDifficulty? difficulty,
    WorkoutPeriodicity? defaultPeriodicity,
    DateTime? createdAt,
    String? createdBy,
    bool? isPublic,
    List<String>? tags,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    List<ProgramCycle>? cycles,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      defaultPeriodicity: defaultPeriodicity ?? this.defaultPeriodicity,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      cycles: cycles ?? this.cycles,
    );
  }

  /// Creates a Program from JSON
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ProgramType.values.firstWhere(
        (e) => e.toString() == 'ProgramType.${json['type']}',
        orElse: () => ProgramType.general,
      ),
      difficulty: ProgramDifficulty.values.firstWhere(
        (e) => e.toString() == 'ProgramDifficulty.${json['difficulty']}',
        orElse: () => ProgramDifficulty.beginner,
      ),
      defaultPeriodicity: json['periodicity'] != null
          ? WorkoutPeriodicity.fromJson(json['periodicity'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      isPublic: json['isPublic'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
      cycles: json['cycles'] != null
          ? (json['cycles'] as List)
                .map((cycleJson) => ProgramCycle.fromJson(cycleJson))
                .toList()
          : [],
    );
  }

  /// Converts Program to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'periodicity': defaultPeriodicity?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isPublic': isPublic,
      'tags': tags,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'cycles': cycles.map((cycle) => cycle.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Program && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Program{id: $id, name: $name, type: $type, '
        'difficulty: $difficulty, defaultPeriodicity: ${defaultPeriodicity?.description}, '
        'cyclesCount: ${cycles.length}, activeCycle: ${activeCycle?.cycleNumber ?? 'None'}}';
  }
}
