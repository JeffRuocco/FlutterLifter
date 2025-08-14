import 'package:flutter/material.dart';
import 'package:flutter_lifter/core/theme/theme_utils.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
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
  })  : type = PeriodicityType.cyclic,
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
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
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
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
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
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
    if (intervalDays == null) return;

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      workoutDates.add(currentDate);
      currentDate = currentDate.add(Duration(days: intervalDays!));
    }
  }

  void _generateCustomDates(
      DateTime startDate, DateTime endDate, List<DateTime> workoutDates) {
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
  final String id;
  final String programId;
  final int cycleNumber;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isCompleted;
  final List<WorkoutSession> scheduledSessions;
  final WorkoutPeriodicity? periodicity;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

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
    this.metadata,
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
    this.metadata,
  })  : id = Utils.generateId(),
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
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
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
        .where((session) =>
            session.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            session.date.isBefore(weekEnd))
        .toList();
  }

  /// Returns workouts scheduled for a specific date in this cycle
  List<WorkoutSession> getWorkoutsForDate(DateTime date) {
    return scheduledSessions
        .where((session) =>
            session.date.year == date.year &&
            session.date.month == date.month &&
            session.date.day == date.day)
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
    final workoutDates =
        periodicity!.generateWorkoutDates(startDate, cycleEndDate);

    // Check if the specific date is in the list of workout dates
    return workoutDates.any((workoutDate) =>
        workoutDate.year == checkDate.year &&
        workoutDate.month == checkDate.month &&
        workoutDate.day == checkDate.day);
  }

  /// Adds a new workout session to this cycle
  ProgramCycle addWorkoutSession(WorkoutSession session) {
    return copyWith(
      scheduledSessions: [...scheduledSessions, session],
    );
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
        .map((session) =>
            session.id == updatedSession.id ? updatedSession : session)
        .toList();
    return copyWith(scheduledSessions: updatedSessions);
  }

  /// Generates and schedules workout sessions for this cycle based on program's periodicity
  ProgramCycle generateScheduledSessions({
    bool replaceExisting = false,
  }) {
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
          scheduledSessions.any((session) =>
              session.date.year == date.year &&
              session.date.month == date.month &&
              session.date.day == date.day)) {
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

  /// Marks the cycle as completed
  ProgramCycle markCompleted() {
    return copyWith(
      isCompleted: true,
      isActive: false,
      endDate: endDate ?? DateTime.now(),
    );
  }

  /// Starts the cycle
  ProgramCycle start() {
    return copyWith(
      isActive: true,
      isCompleted: false,
    );
  }

  /// Stops/pauses the cycle
  ProgramCycle stop() {
    return copyWith(
      isActive: false,
    );
  }

  /// Creates a copy of this cycle with updated values
  ProgramCycle copyWith({
    String? id,
    String? programId,
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
    return ProgramCycle(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledSessions: scheduledSessions ?? this.scheduledSessions,
      periodicity: periodicity ?? this.periodicity,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
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
      metadata: json['metadata'],
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
      'scheduledSessions':
          scheduledSessions.map((session) => session.toJson()).toList(),
      'periodicity': periodicity?.toJson(),
      'notes': notes,
      'metadata': metadata,
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
  })  : id = Utils.generateId(),
        createdAt = DateTime.now();

  /// Returns the current active cycle (only one allowed at a time)
  ProgramCycle? get currentCycle {
    return activeCycle;
  }

  /// Returns the most recently completed cycle
  ProgramCycle? get lastCompletedCycle {
    return cycles.where((cycle) => cycle.isCompleted).fold<ProgramCycle?>(null,
        (latest, cycle) {
      if (latest == null || cycle.createdAt.isAfter(latest.createdAt)) {
        return cycle;
      }
      return latest;
    });
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

  /// Creates a new cycle for this program (deactivates any existing active cycle)
  Program createNewCycle({
    required DateTime startDate,
    DateTime? endDate,
    WorkoutPeriodicity? periodicity,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    // Deactivate any existing active cycles
    final updatedCycles =
        cycles.map((cycle) => cycle.isActive ? cycle.stop() : cycle).toList();

    final newCycle = ProgramCycle.create(
      programId: id,
      cycleNumber: nextCycleNumber,
      startDate: startDate,
      endDate: endDate,
      periodicity: periodicity ??
          defaultPeriodicity, // Use provided or default periodicity
      notes: notes,
      metadata: metadata,
    );

    return copyWith(cycles: [...updatedCycles, newCycle]);
  }

  /// Adds an existing cycle to this program (deactivates other cycles if this one is active)
  Program addCycle(ProgramCycle cycle) {
    List<ProgramCycle> updatedCycles = List.from(cycles);

    // If the new cycle is active, deactivate all existing cycles
    if (cycle.isActive) {
      updatedCycles = updatedCycles
          .map((existingCycle) =>
              existingCycle.isActive ? existingCycle.stop() : existingCycle)
          .toList();
    }

    return copyWith(cycles: [...updatedCycles, cycle]);
  }

  /// Removes a cycle from this program
  Program removeCycle(String cycleId) {
    return copyWith(
      cycles: cycles.where((cycle) => cycle.id != cycleId).toList(),
    );
  }

  /// Updates a cycle in this program (enforces single active cycle constraint)
  Program updateCycle(ProgramCycle updatedCycle) {
    final updatedCycles = cycles.map((cycle) {
      if (cycle.id == updatedCycle.id) {
        return updatedCycle;
      } else {
        // If the updated cycle is being set to active, deactivate all other cycles
        if (updatedCycle.isActive && cycle.isActive) {
          return cycle.stop();
        }
        return cycle;
      }
    }).toList();

    return copyWith(cycles: updatedCycles);
  }

  /// Starts a new cycle and deactivates any current active cycle
  Program startNewCycle({
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    // Deactivate any currently active cycles
    final updatedCycles =
        cycles.map((cycle) => cycle.isActive ? cycle.stop() : cycle).toList();

    // Create and start new cycle
    final newCycle = ProgramCycle.create(
      programId: id,
      cycleNumber: nextCycleNumber,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      periodicity: defaultPeriodicity, // Use the program's default periodicity
      notes: notes,
      metadata: metadata,
    ).start();

    return copyWith(cycles: [...updatedCycles, newCycle]);
  }

  /// Completes the current active cycle
  Program completeCurrentCycle() {
    if (activeCycle == null) return this;

    final completedCycle = activeCycle!.markCompleted();
    return updateCycle(completedCycle);
  }

  /// Activates a specific cycle by ID, deactivating any other active cycles
  Program activateCycle(String cycleId) {
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

    final futureDates =
        defaultPeriodicity!.generateWorkoutDates(from, futureEnd);
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

  /// Returns the program icon, falling back to a default icon
  IconData get icon {
    if (metadata != null && metadata!.containsKey('icon')) {
      return metadata!['icon'] as IconData;
    }
    // Return a default icon
    return HugeIcons.strokeRoundedDumbbell01;
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
        'cyclesCount: ${cycles.length}, activeCycle: ${currentCycle?.cycleNumber ?? 'None'}}';
  }
}
