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

  // ============================================
  // WORKOUT DAY TEMPLATES
  // ============================================

  /// Upper/Lower program day templates
  static const _upperLowerTemplates = [
    WorkoutDayTemplate(
      id: 'upper_lower_upper_a',
      name: 'Upper Body',
      dayIndex: 0,
      variant: 'A',
      description: 'Chest and back focus with arm accessories',
      exerciseIds: [
        'bench', // Bench Press
        'row', // Bent-Over Barbell Row
        'ohp', // Overhead Press
        'lat_pulldown', // Lat Pulldown
        'dumbbell_fly', // Dumbbell Fly
        'barbell_curl', // Barbell Curl
        'tricep_pushdown', // Tricep Pushdown
      ],
    ),
    WorkoutDayTemplate(
      id: 'upper_lower_lower_a',
      name: 'Lower Body',
      dayIndex: 1,
      variant: 'A',
      description: 'Squat focus with hamstring and calf work',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'romanian_deadlift', // Romanian Deadlift
        'leg_press', // Leg Press
        'leg_curl', // Leg Curl
        'leg_extension', // Leg Extension
        'calf_raise', // Standing Calf Raise
      ],
    ),
    WorkoutDayTemplate(
      id: 'upper_lower_upper_b',
      name: 'Upper Body',
      dayIndex: 2,
      variant: 'B',
      description: 'Shoulder and back focus with arm accessories',
      exerciseIds: [
        'ohp', // Overhead Press
        'pullup', // Pull-ups
        'incline_bench', // Incline Bench Press
        'seated_cable_row', // Seated Cable Row
        'lateral_raise', // Lateral Raise
        'face_pull', // Face Pull
        'hammer_curl', // Hammer Curl
        'dips', // Dips
      ],
    ),
    WorkoutDayTemplate(
      id: 'upper_lower_lower_b',
      name: 'Lower Body',
      dayIndex: 3,
      variant: 'B',
      description: 'Deadlift focus with quad and glute work',
      exerciseIds: [
        'deadlift', // Deadlift
        'front_squat', // Front Squat
        'lunges', // Lunges
        'leg_curl', // Leg Curl
        'leg_extension', // Leg Extension
        'calf_raise', // Standing Calf Raise
      ],
    ),
  ];

  /// Full Body program day templates
  static const _fullBodyTemplates = [
    WorkoutDayTemplate(
      id: 'full_body_day_a',
      name: 'Full Body',
      dayIndex: 0,
      variant: 'A',
      description: 'Squat and bench focus',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'bench', // Bench Press
        'row', // Bent-Over Barbell Row
        'ohp', // Overhead Press
        'barbell_curl', // Barbell Curl
        'plank', // Plank
      ],
    ),
    WorkoutDayTemplate(
      id: 'full_body_day_b',
      name: 'Full Body',
      dayIndex: 1,
      variant: 'B',
      description: 'Deadlift and overhead focus',
      exerciseIds: [
        'deadlift', // Deadlift
        'ohp', // Overhead Press
        'pullup', // Pull-ups
        'incline_bench', // Incline Bench Press
        'lunges', // Lunges
        'hanging_leg_raise', // Hanging Leg Raise
      ],
    ),
    WorkoutDayTemplate(
      id: 'full_body_day_c',
      name: 'Full Body',
      dayIndex: 2,
      variant: 'C',
      description: 'Front squat and accessory focus',
      exerciseIds: [
        'front_squat', // Front Squat
        'bench', // Bench Press
        'seated_cable_row', // Seated Cable Row
        'lateral_raise', // Lateral Raise
        'leg_curl', // Leg Curl
        'tricep_pushdown', // Tricep Pushdown
      ],
    ),
  ];

  /// Push/Pull/Legs program day templates
  static const _pplTemplates = [
    WorkoutDayTemplate(
      id: 'ppl_push',
      name: 'Push',
      dayIndex: 0,
      description: 'Chest, shoulders, and triceps',
      exerciseIds: [
        'bench', // Bench Press
        'ohp', // Overhead Press
        'incline_bench', // Incline Bench Press
        'dumbbell_fly', // Dumbbell Fly
        'lateral_raise', // Lateral Raise
        'tricep_pushdown', // Tricep Pushdown
        'dips', // Dips
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl_pull',
      name: 'Pull',
      dayIndex: 1,
      description: 'Back and biceps',
      exerciseIds: [
        'deadlift', // Deadlift
        'pullup', // Pull-ups
        'row', // Bent-Over Barbell Row
        'lat_pulldown', // Lat Pulldown
        'face_pull', // Face Pull
        'barbell_curl', // Barbell Curl
        'hammer_curl', // Hammer Curl
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl_legs',
      name: 'Legs',
      dayIndex: 2,
      description: 'Quadriceps, hamstrings, glutes, and calves',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'romanian_deadlift', // Romanian Deadlift
        'leg_press', // Leg Press
        'leg_curl', // Leg Curl
        'leg_extension', // Leg Extension
        'calf_raise', // Standing Calf Raise
      ],
    ),
  ];

  /// Starting Strength program day templates (classic A/B)
  static const _startingStrengthTemplates = [
    WorkoutDayTemplate(
      id: 'ss_day_a',
      name: 'Workout',
      dayIndex: 0,
      variant: 'A',
      description: 'Squat, Bench, Deadlift',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'bench', // Bench Press
        'deadlift', // Deadlift
      ],
    ),
    WorkoutDayTemplate(
      id: 'ss_day_b',
      name: 'Workout',
      dayIndex: 1,
      variant: 'B',
      description: 'Squat, Press, Power Clean/Row',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'ohp', // Overhead Press
        'row', // Bent-Over Barbell Row (substitute for power clean)
      ],
    ),
  ];

  /// PPL 6-Day Split templates (each muscle group twice per week)
  static const _ppl6DayTemplates = [
    WorkoutDayTemplate(
      id: 'ppl6_push_a',
      name: 'Push',
      dayIndex: 0,
      variant: 'A',
      description: 'Heavy chest and shoulders',
      exerciseIds: [
        'bench', // Bench Press
        'ohp', // Overhead Press
        'incline_bench', // Incline Bench Press
        'lateral_raise', // Lateral Raise
        'tricep_pushdown', // Tricep Pushdown
        'dips', // Dips
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl6_pull_a',
      name: 'Pull',
      dayIndex: 1,
      variant: 'A',
      description: 'Heavy back with deadlifts',
      exerciseIds: [
        'deadlift', // Deadlift
        'pullup', // Pull-ups
        'row', // Bent-Over Barbell Row
        'face_pull', // Face Pull
        'barbell_curl', // Barbell Curl
        'hammer_curl', // Hammer Curl
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl6_legs_a',
      name: 'Legs',
      dayIndex: 2,
      variant: 'A',
      description: 'Heavy squat focus',
      exerciseIds: [
        'squat', // Barbell Back Squat
        'romanian_deadlift', // Romanian Deadlift
        'leg_press', // Leg Press
        'leg_curl', // Leg Curl
        'calf_raise', // Standing Calf Raise
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl6_push_b',
      name: 'Push',
      dayIndex: 3,
      variant: 'B',
      description: 'Volume chest and shoulders',
      exerciseIds: [
        'incline_bench', // Incline Bench Press
        'bench', // Bench Press
        'dumbbell_fly', // Dumbbell Fly
        'lateral_raise', // Lateral Raise
        'ohp', // Overhead Press
        'tricep_pushdown', // Tricep Pushdown
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl6_pull_b',
      name: 'Pull',
      dayIndex: 4,
      variant: 'B',
      description: 'Volume back without deadlifts',
      exerciseIds: [
        'pullup', // Pull-ups
        'lat_pulldown', // Lat Pulldown
        'seated_cable_row', // Seated Cable Row
        'face_pull', // Face Pull
        'barbell_curl', // Barbell Curl
        'hammer_curl', // Hammer Curl
      ],
    ),
    WorkoutDayTemplate(
      id: 'ppl6_legs_b',
      name: 'Legs',
      dayIndex: 5,
      variant: 'B',
      description: 'Volume leg work',
      exerciseIds: [
        'front_squat', // Front Squat
        'lunges', // Lunges
        'leg_extension', // Leg Extension
        'leg_curl', // Leg Curl
        'calf_raise', // Standing Calf Raise
      ],
    ),
  ];

  /// List of default program templates (without active cycles/sessions)
  static List<Program> programs = [
    Program(
      id: 'upper_lower',
      name: 'Upper/Lower',
      description:
          'Train upper body and lower body on alternating days. Perfect for intermediate lifters.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        2,
        4,
        5,
      ]), // Mon, Tue, Thu, Fri - 4 days/week
      tags: ['strength', 'hypertrophy', 'upper body', 'lower body'],
      createdAt: DateTime(2024, 1, 1),
      isDefault: true,
      metadata: {
        'color': Colors.blue,
        'icon': HugeIcons.strokeRoundedDumbbell01,
      },
      dayTemplates: _upperLowerTemplates,
      cycles: [],
    ),
    Program(
      id: 'full_body',
      name: 'Full Body',
      description:
          'Train all major muscle groups in a single session. Ideal for beginners and those with limited time.',
      type: ProgramType.general,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        3,
        5,
      ]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'hypertrophy', 'full body', 'beginner'],
      createdAt: DateTime(2024, 1, 1),
      isDefault: true,
      metadata: {
        'color': Colors.green,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
      dayTemplates: _fullBodyTemplates,
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
        workoutDays: 3,
        restDays: 1,
      ), // 3 days on, 1 day rest
      tags: ['strength', 'hypertrophy', 'split', 'advanced'],
      createdAt: DateTime(2024, 1, 1),
      isDefault: true,
      metadata: {'color': Colors.orange, 'icon': HugeIcons.strokeRoundedFire},
      dayTemplates: _pplTemplates,
      cycles: [],
    ),
    Program(
      id: 'starting_strength',
      name: 'Starting Strength',
      description:
          'Classic beginner strength program focusing on compound lifts. Build a foundation of strength.',
      type: ProgramType.strength,
      difficulty: ProgramDifficulty.beginner,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        3,
        5,
      ]), // Mon, Wed, Fri - 3 days/week
      tags: ['strength', 'beginner', 'compound', 'barbell'],
      createdAt: DateTime(2024, 1, 1),
      isDefault: true,
      metadata: {
        'color': Colors.red,
        'icon': HugeIcons.strokeRoundedDumbbell02,
      },
      dayTemplates: _startingStrengthTemplates,
      cycles: [],
    ),
    Program(
      id: 'ppl_6day',
      name: 'PPL 6-Day Split',
      description:
          'High frequency push/pull/legs split. Train each muscle group twice per week.',
      type: ProgramType.hypertrophy,
      difficulty: ProgramDifficulty.intermediate,
      defaultPeriodicity: const WorkoutPeriodicity.weekly([
        1,
        2,
        3,
        4,
        5,
        6,
      ]), // Mon-Sat - 6 days/week
      tags: ['hypertrophy', 'split', 'high frequency', 'muscle building'],
      createdAt: DateTime(2024, 1, 1),
      isDefault: true,
      metadata: {
        'color': Colors.purple,
        'icon': HugeIcons.strokeRoundedBodyPartMuscle,
      },
      dayTemplates: _ppl6DayTemplates,
      cycles: [],
    ),
  ];
}
