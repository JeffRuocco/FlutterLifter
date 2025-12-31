import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:hugeicons/hugeicons.dart';

/// Default built-in program templates for the app.
/// These are clean templates without active cycles or sessions.
/// Users can start new cycles from these templates.
class DefaultPrograms {
  /// Retrieves a program by its ID.
  /// Returns null if the program is not found.
  static Program? getProgramById(String id) {
    try {
      return programs.firstWhere(
        (program) => program.id.toLowerCase() == id.toLowerCase(),
        orElse: () => throw Exception('Program not found: $id'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retrieves a program by name.
  /// Returns null if the program is not found.
  static Program? getProgramByName(String name) {
    try {
      return programs.firstWhere(
        (program) => program.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Program not found: $name'),
      );
    } catch (e) {
      return null;
    }
  }

  /// List of default program templates (without active cycles/sessions)
  static List<Program> programs = [
    Program(
      id: 'upper_lower',
      name: 'Upper/Lower',
      description:
          'Train upper body and lower body on alternating days. Perfect for intermediate lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 2, 4, 5]), // Mon, Tue, Thu, Fri - 4 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime(2024, 1, 1),
      metadata: {
        'color': Colors.blue,
        'icon': HugeIcons.strokeRoundedDumbbell01,
      },
      // No cycles - this is a clean template
      cycles: [],
    ),
    Program(
      id: 'full_body',
      name: 'Full Body',
      description:
          'Train all major muscle groups in a single session. Ideal for beginners and those with limited time.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 3, 5]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'hypertrophy', 'full body', 'beginner'],
      createdAt: DateTime(2024, 1, 1),
      metadata: {
        'color': Colors.green,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
      cycles: [],
    ),
    Program(
      id: 'push_pull_legs',
      name: 'Push/Pull/Legs',
      description:
          'Split training by movement patterns: push, pull, and legs. Great for advanced lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.advanced,
      defaultPeriodicity: const WorkoutPeriodicity.cyclic(
          workoutDays: 3, restDays: 1), // 3 days on, 1 day rest
      tags: ['strength', 'hypertrophy', 'split', 'advanced'],
      createdAt: DateTime(2024, 1, 1),
      metadata: {
        'color': Colors.orange,
        'icon': HugeIcons.strokeRoundedFire,
      },
      cycles: [],
    ),
    Program(
      id: 'starting_strength',
      name: 'Starting Strength',
      description:
          'Classic beginner strength program focusing on compound lifts. Build a foundation of strength.',
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 3, 5]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'beginner', 'compound', 'barbell'],
      createdAt: DateTime(2024, 1, 1),
      metadata: {
        'color': Colors.red,
        'icon': HugeIcons.strokeRoundedDumbbell02,
      },
      cycles: [],
    ),
    Program(
      id: 'ppl_6day',
      name: 'PPL 6-Day Split',
      description:
          'High frequency push/pull/legs split. Train each muscle group twice per week.',
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly(
          [1, 2, 3, 4, 5, 6]), // Mon-Sat - 6 days/week
      tags: ['hypertrophy', 'split', 'high frequency', 'muscle building'],
      createdAt: DateTime(2024, 1, 1),
      metadata: {
        'color': Colors.purple,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
      cycles: [],
    ),
  ];
}
