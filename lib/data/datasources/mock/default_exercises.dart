import 'package:flutter_lifter/models/models.dart';

/// Default built-in exercises for the app.
/// These are immutable templates that cannot be deleted by users.
class DefaultExercises {
  /// Retrieves an exercise by its name.
  /// Returns null if the exercise is not found.
  static Exercise? getExerciseByName(String name) {
    try {
      return exercises.firstWhere(
        (exercise) => exercise.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw Exception('Exercise not found: $name'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Retrieves an exercise by its ID.
  /// Returns null if the exercise is not found.
  static Exercise? getExerciseById(String id) {
    try {
      return exercises.firstWhere(
        (exercise) => exercise.id.toLowerCase() == id.toLowerCase(),
        orElse: () => throw Exception('Exercise not found: $id'),
      );
    } catch (e) {
      return null;
    }
  }

  /// List of predefined default exercises covering all major categories and muscle groups
  static List<Exercise> exercises = [
    // ============================================
    // STRENGTH - Chest
    // ============================================
    Exercise(
      id: 'bench',
      name: 'Bench Press',
      shortName: 'Bench',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.shoulders,
      ],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 120,
      isDefault: true,
      instructions:
          'Lie flat on bench, grip bar slightly wider than shoulder width, lower to chest, press up.',
    ),
    Exercise(
      id: 'incline_bench',
      name: 'Incline Bench Press',
      shortName: 'Inc Bench',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.upperChest,
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
      ],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 120,
      isDefault: true,
      instructions:
          'Set bench to 30-45 degrees, grip bar shoulder width, lower to upper chest, press up.',
    ),
    Exercise(
      id: 'dumbbell_fly',
      name: 'Dumbbell Fly',
      shortName: 'DB Fly',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Lie flat, dumbbells above chest, lower arms in arc motion, squeeze chest to return.',
    ),

    // ============================================
    // STRENGTH - Back
    // ============================================
    Exercise(
      id: 'deadlift',
      name: 'Deadlift',
      shortName: 'Dead',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.back,
        MuscleGroup.core,
      ],
      defaultSets: 3,
      defaultReps: 5,
      defaultRestTimeSeconds: 180,
      isDefault: true,
      instructions:
          'Stand with feet hip-width, grip bar outside knees, drive through heels, extend hips and knees.',
    ),
    Exercise(
      id: 'row',
      name: 'Bent-Over Barbell Row',
      shortName: 'BB Row',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.lats,
        MuscleGroup.rhomboids,
        MuscleGroup.rearDelts,
        MuscleGroup.biceps,
      ],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Hinge at hips, pull bar to lower chest, squeeze shoulder blades, lower controlled.',
    ),
    Exercise(
      id: 'pullup',
      name: 'Pull-ups',
      shortName: 'Pull-up',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.lats,
        MuscleGroup.biceps,
        MuscleGroup.rhomboids,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Hang from bar, pull body up until chin over bar, lower controlled.',
    ),
    Exercise(
      id: 'lat_pulldown',
      name: 'Lat Pulldown',
      shortName: 'Lat Pull',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.lats,
        MuscleGroup.biceps,
        MuscleGroup.rhomboids,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Grip bar wide, pull to upper chest, squeeze lats, return controlled.',
    ),
    Exercise(
      id: 'seated_cable_row',
      name: 'Seated Cable Row',
      shortName: 'Cable Row',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.lats,
        MuscleGroup.rhomboids,
        MuscleGroup.rearDelts,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Sit upright, pull handle to abdomen, squeeze shoulder blades, return controlled.',
    ),

    // ============================================
    // STRENGTH - Shoulders
    // ============================================
    Exercise(
      id: 'ohp',
      name: 'Overhead Press',
      shortName: 'OHP',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
        MuscleGroup.core,
      ],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 120,
      isDefault: true,
      instructions:
          'Stand with bar at shoulders, press overhead, lock out elbows, lower controlled.',
    ),
    Exercise(
      id: 'lateral_raise',
      name: 'Lateral Raise',
      shortName: 'Lat Raise',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.sideDelts],
      defaultSets: 3,
      defaultReps: 15,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Stand with dumbbells at sides, raise arms to shoulder height, lower controlled.',
    ),
    Exercise(
      id: 'face_pull',
      name: 'Face Pull',
      shortName: 'Face Pull',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.rearDelts,
        MuscleGroup.rotatorCuff,
        MuscleGroup.traps,
      ],
      defaultSets: 3,
      defaultReps: 15,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Set cable high, pull rope to face, external rotate at end, return controlled.',
    ),

    // ============================================
    // STRENGTH - Arms
    // ============================================
    Exercise(
      id: 'dips',
      name: 'Dips',
      shortName: 'Dips',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.triceps,
        MuscleGroup.chest,
        MuscleGroup.shoulders,
      ],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Support on bars, lower body by bending elbows, press back up to lockout.',
    ),
    Exercise(
      id: 'barbell_curl',
      name: 'Barbell Curl',
      shortName: 'BB Curl',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.biceps, MuscleGroup.forearms],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Stand with bar at thighs, curl to shoulders, squeeze biceps, lower controlled.',
    ),
    Exercise(
      id: 'tricep_pushdown',
      name: 'Tricep Pushdown',
      shortName: 'Tri Push',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.triceps],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Set cable high, push bar down until arms straight, return controlled.',
    ),
    Exercise(
      id: 'hammer_curl',
      name: 'Hammer Curl',
      shortName: 'Hammer',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.biceps,
        MuscleGroup.brachialis,
        MuscleGroup.forearms,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Hold dumbbells with neutral grip, curl to shoulders, lower controlled.',
    ),

    // ============================================
    // STRENGTH - Legs
    // ============================================
    Exercise(
      id: 'squat',
      name: 'Barbell Back Squat',
      shortName: 'Squat',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
        MuscleGroup.core,
      ],
      defaultSets: 4,
      defaultReps: 8,
      defaultRestTimeSeconds: 180,
      isDefault: true,
      instructions:
          'Bar on upper back, feet shoulder width, squat to parallel, drive through heels.',
    ),
    Exercise(
      id: 'front_squat',
      name: 'Front Squat',
      shortName: 'Front Squat',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.core,
      ],
      defaultSets: 3,
      defaultReps: 8,
      defaultRestTimeSeconds: 150,
      isDefault: true,
      instructions:
          'Bar on front delts, elbows high, squat deep, keep torso upright.',
    ),
    Exercise(
      id: 'lunges',
      name: 'Lunges',
      shortName: 'Lunges',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
      ],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Step forward, lower back knee to floor, push through front heel to return.',
    ),
    Exercise(
      id: 'leg_press',
      name: 'Leg Press',
      shortName: 'Leg Press',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 120,
      isDefault: true,
      instructions:
          'Feet shoulder width on platform, lower weight, press through heels.',
    ),
    Exercise(
      id: 'romanian_deadlift',
      name: 'Romanian Deadlift',
      shortName: 'RDL',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.lowerBack,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Hold bar, hinge at hips with slight knee bend, feel hamstring stretch, return.',
    ),
    Exercise(
      id: 'leg_curl',
      name: 'Leg Curl',
      shortName: 'Leg Curl',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.hamstrings],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Lie prone on machine, curl weight towards glutes, lower controlled.',
    ),
    Exercise(
      id: 'leg_extension',
      name: 'Leg Extension',
      shortName: 'Leg Ext',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.quadriceps],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Sit on machine, extend legs until straight, squeeze quads, lower controlled.',
    ),
    Exercise(
      id: 'calf_raise',
      name: 'Standing Calf Raise',
      shortName: 'Calf Raise',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.calves],
      defaultSets: 4,
      defaultReps: 15,
      defaultRestTimeSeconds: 45,
      isDefault: true,
      instructions:
          'Stand on raised surface, raise heels as high as possible, lower for stretch.',
    ),

    // ============================================
    // STRENGTH - Core
    // ============================================
    Exercise(
      id: 'plank',
      name: 'Plank',
      shortName: 'Plank',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.core, MuscleGroup.shoulders],
      defaultSets: 3,
      defaultReps: 60, // seconds
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Support on forearms and toes, keep body straight, hold position.',
    ),
    Exercise(
      id: 'hanging_leg_raise',
      name: 'Hanging Leg Raise',
      shortName: 'Leg Raise',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.lowerAbs, MuscleGroup.hipFlexors],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Hang from bar, raise legs to parallel or higher, lower controlled.',
    ),
    Exercise(
      id: 'cable_crunch',
      name: 'Cable Crunch',
      shortName: 'Cable Crunch',
      category: ExerciseCategory.strength,
      targetMuscleGroups: [MuscleGroup.abs],
      defaultSets: 3,
      defaultReps: 15,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Kneel at cable, hold rope behind head, crunch down, squeeze abs.',
    ),

    // ============================================
    // CARDIO
    // ============================================
    Exercise(
      id: 'running',
      name: 'Running',
      shortName: 'Run',
      category: ExerciseCategory.cardio,
      targetMuscleGroups: [MuscleGroup.legs, MuscleGroup.cardiovascular],
      defaultSets: 1,
      defaultReps: 30, // minutes
      defaultRestTimeSeconds: 0,
      isDefault: true,
      instructions: 'Maintain steady pace, focus on breathing rhythm.',
    ),
    Exercise(
      id: 'cycling',
      name: 'Cycling',
      shortName: 'Cycle',
      category: ExerciseCategory.cardio,
      targetMuscleGroups: [MuscleGroup.legs, MuscleGroup.cardiovascular],
      defaultSets: 1,
      defaultReps: 30, // minutes
      defaultRestTimeSeconds: 0,
      isDefault: true,
      instructions: 'Maintain steady cadence, adjust resistance as needed.',
    ),
    Exercise(
      id: 'rowing_machine',
      name: 'Rowing Machine',
      shortName: 'Row',
      category: ExerciseCategory.cardio,
      targetMuscleGroups: [
        MuscleGroup.back,
        MuscleGroup.legs,
        MuscleGroup.arms,
        MuscleGroup.cardiovascular,
      ],
      defaultSets: 1,
      defaultReps: 20, // minutes
      defaultRestTimeSeconds: 0,
      isDefault: true,
      instructions: 'Drive with legs, pull handle to chest, return controlled.',
    ),
    Exercise(
      id: 'jump_rope',
      name: 'Jump Rope',
      shortName: 'Jump Rope',
      category: ExerciseCategory.cardio,
      targetMuscleGroups: [
        MuscleGroup.calves,
        MuscleGroup.shoulders,
        MuscleGroup.cardiovascular,
      ],
      defaultSets: 3,
      defaultReps: 100, // skips
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions: 'Jump with minimal height, turn rope with wrists.',
    ),

    // ============================================
    // FLEXIBILITY
    // ============================================
    Exercise(
      id: 'hamstring_stretch',
      name: 'Hamstring Stretch',
      shortName: 'Ham Stretch',
      category: ExerciseCategory.flexibility,
      targetMuscleGroups: [MuscleGroup.hamstrings],
      defaultSets: 2,
      defaultReps: 30, // seconds per side
      defaultRestTimeSeconds: 15,
      isDefault: true,
      instructions:
          'Sit with one leg extended, reach towards toes, hold stretch.',
    ),
    Exercise(
      id: 'hip_flexor_stretch',
      name: 'Hip Flexor Stretch',
      shortName: 'Hip Stretch',
      category: ExerciseCategory.flexibility,
      targetMuscleGroups: [MuscleGroup.hipFlexors, MuscleGroup.quadriceps],
      defaultSets: 2,
      defaultReps: 30, // seconds per side
      defaultRestTimeSeconds: 15,
      isDefault: true,
      instructions:
          'Kneel on one knee, push hips forward, feel stretch in front hip.',
    ),
    Exercise(
      id: 'shoulder_stretch',
      name: 'Cross-Body Shoulder Stretch',
      shortName: 'Shoulder Str',
      category: ExerciseCategory.flexibility,
      targetMuscleGroups: [MuscleGroup.shoulders, MuscleGroup.back],
      defaultSets: 2,
      defaultReps: 30, // seconds per side
      defaultRestTimeSeconds: 15,
      isDefault: true,
      instructions: 'Pull arm across body at shoulder height, hold stretch.',
    ),

    // ============================================
    // BALANCE
    // ============================================
    Exercise(
      id: 'single_leg_stand',
      name: 'Single Leg Stand',
      shortName: 'SL Stand',
      category: ExerciseCategory.balance,
      targetMuscleGroups: [MuscleGroup.core, MuscleGroup.legs],
      defaultSets: 3,
      defaultReps: 30, // seconds per side
      defaultRestTimeSeconds: 30,
      isDefault: true,
      instructions: 'Stand on one leg, maintain balance, engage core.',
    ),
    Exercise(
      id: 'bosu_squat',
      name: 'BOSU Ball Squat',
      shortName: 'BOSU Squat',
      category: ExerciseCategory.balance,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.core,
      ],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Stand on BOSU ball, perform squat while maintaining balance.',
    ),

    // ============================================
    // ENDURANCE
    // ============================================
    Exercise(
      id: 'burpees',
      name: 'Burpees',
      shortName: 'Burpees',
      category: ExerciseCategory.endurance,
      targetMuscleGroups: [MuscleGroup.fullBody, MuscleGroup.cardiovascular],
      defaultSets: 3,
      defaultReps: 15,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Squat, jump feet back, push-up, jump feet forward, jump up.',
    ),
    Exercise(
      id: 'mountain_climbers',
      name: 'Mountain Climbers',
      shortName: 'Mt Climbers',
      category: ExerciseCategory.endurance,
      targetMuscleGroups: [
        MuscleGroup.core,
        MuscleGroup.shoulders,
        MuscleGroup.cardiovascular,
      ],
      defaultSets: 3,
      defaultReps: 30, // per side
      defaultRestTimeSeconds: 45,
      isDefault: true,
      instructions: 'Plank position, alternate driving knees to chest rapidly.',
    ),
    Exercise(
      id: 'kettlebell_swing',
      name: 'Kettlebell Swing',
      shortName: 'KB Swing',
      category: ExerciseCategory.endurance,
      targetMuscleGroups: [
        MuscleGroup.glutes,
        MuscleGroup.hamstrings,
        MuscleGroup.core,
        MuscleGroup.shoulders,
      ],
      defaultSets: 3,
      defaultReps: 20,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Hinge at hips, swing kettlebell to shoulder height using hip drive.',
    ),

    // ============================================
    // SPORTS
    // ============================================
    Exercise(
      id: 'box_jump',
      name: 'Box Jump',
      shortName: 'Box Jump',
      category: ExerciseCategory.sports,
      targetMuscleGroups: [
        MuscleGroup.quadriceps,
        MuscleGroup.glutes,
        MuscleGroup.calves,
      ],
      defaultSets: 3,
      defaultReps: 10,
      defaultRestTimeSeconds: 90,
      isDefault: true,
      instructions:
          'Stand facing box, jump onto box landing softly, step down.',
    ),
    Exercise(
      id: 'medicine_ball_slam',
      name: 'Medicine Ball Slam',
      shortName: 'MB Slam',
      category: ExerciseCategory.sports,
      targetMuscleGroups: [
        MuscleGroup.core,
        MuscleGroup.shoulders,
        MuscleGroup.lats,
      ],
      defaultSets: 3,
      defaultReps: 12,
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions:
          'Lift ball overhead, slam to ground with full force, catch and repeat.',
    ),
    Exercise(
      id: 'battle_ropes',
      name: 'Battle Ropes',
      shortName: 'Ropes',
      category: ExerciseCategory.sports,
      targetMuscleGroups: [
        MuscleGroup.arms,
        MuscleGroup.shoulders,
        MuscleGroup.core,
        MuscleGroup.cardiovascular,
      ],
      defaultSets: 3,
      defaultReps: 30, // seconds
      defaultRestTimeSeconds: 60,
      isDefault: true,
      instructions: 'Hold rope ends, create waves by alternating arms rapidly.',
    ),
  ];
}
