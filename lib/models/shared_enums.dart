/// Shared enums and types used across multiple model files
library;

/// Enum for filtering exercises by source (default built-in vs custom user-created)
enum ExerciseSource {
  /// Include both default and custom exercises
  all,

  /// Include only default built-in exercises
  defaultOnly,

  /// Include only custom user-created exercises
  customOnly,
}

extension ExerciseSourceExtension on ExerciseSource {
  String get displayName {
    switch (this) {
      case ExerciseSource.all:
        return 'All Exercises';
      case ExerciseSource.defaultOnly:
        return 'Default Exercises';
      case ExerciseSource.customOnly:
        return 'My Exercises';
    }
  }
}

/// Enum for exercise categories
enum ExerciseCategory {
  strength,
  cardio,
  flexibility,
  balance,
  endurance,
  sports,
  other,
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get displayName {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.balance:
        return 'Balance';
      case ExerciseCategory.endurance:
        return 'Endurance';
      case ExerciseCategory.sports:
        return 'Sports';
      case ExerciseCategory.other:
        return 'Other';
    }
  }
}

/// Enum for program difficulty levels
enum ProgramDifficulty { beginner, intermediate, advanced, expert }

extension ProgramDifficultyExtension on ProgramDifficulty {
  String get displayName {
    switch (this) {
      case ProgramDifficulty.beginner:
        return 'Beginner';
      case ProgramDifficulty.intermediate:
        return 'Intermediate';
      case ProgramDifficulty.advanced:
        return 'Advanced';
      case ProgramDifficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case ProgramDifficulty.beginner:
        return 'New to fitness or this type of training';
      case ProgramDifficulty.intermediate:
        return '6+ months of consistent training experience';
      case ProgramDifficulty.advanced:
        return '2+ years of training experience';
      case ProgramDifficulty.expert:
        return 'Competitive athlete or 5+ years experience';
    }
  }
}

/// Enum for program types/categories
enum ProgramType {
  strength,
  hypertrophy,
  powerlifting,
  bodybuilding,
  cardio,
  hiit,
  flexibility,
  general,
  sport,
  rehabilitation,
}

extension ProgramTypeExtension on ProgramType {
  String get displayName {
    switch (this) {
      case ProgramType.strength:
        return 'Strength Training';
      case ProgramType.hypertrophy:
        return 'Muscle Building';
      case ProgramType.powerlifting:
        return 'Powerlifting';
      case ProgramType.bodybuilding:
        return 'Bodybuilding';
      case ProgramType.cardio:
        return 'Cardiovascular';
      case ProgramType.hiit:
        return 'HIIT';
      case ProgramType.flexibility:
        return 'Flexibility';
      case ProgramType.general:
        return 'General Fitness';
      case ProgramType.sport:
        return 'Sport Specific';
      case ProgramType.rehabilitation:
        return 'Rehabilitation';
    }
  }
}

/// Enum for workout session scheduling periodicity types
enum PeriodicityType {
  weekly, // Specific days of the week (e.g., Monday, Wednesday, Friday)
  cyclic, // Cycle pattern (e.g., 3 days on, 1 day rest)
  interval, // Every X days (e.g., every 2 days)
  custom, // Custom pattern defined by dates
}

extension PeriodicityTypeExtension on PeriodicityType {
  String get displayName {
    switch (this) {
      case PeriodicityType.weekly:
        return 'Weekly Schedule';
      case PeriodicityType.cyclic:
        return 'Cycle Pattern';
      case PeriodicityType.interval:
        return 'Interval Schedule';
      case PeriodicityType.custom:
        return 'Custom Schedule';
    }
  }

  String get description {
    switch (this) {
      case PeriodicityType.weekly:
        return 'Workouts on specific days of the week';
      case PeriodicityType.cyclic:
        return 'Repeating cycle of workout and rest days';
      case PeriodicityType.interval:
        return 'Workouts every X days';
      case PeriodicityType.custom:
        return 'Custom workout schedule';
    }
  }
}

/// Enum for muscle group regions (used for grouping in UI)
enum MuscleGroupRegion { upperPush, upperPull, legs, core, cardio, other }

extension MuscleGroupRegionExtension on MuscleGroupRegion {
  String get displayName {
    switch (this) {
      case MuscleGroupRegion.upperPush:
        return 'Upper Body (Push)';
      case MuscleGroupRegion.upperPull:
        return 'Upper Body (Pull)';
      case MuscleGroupRegion.legs:
        return 'Legs';
      case MuscleGroupRegion.core:
        return 'Core';
      case MuscleGroupRegion.cardio:
        return 'Cardio & Full Body';
      case MuscleGroupRegion.other:
        return 'Other';
    }
  }
}

/// Enum for muscle groups targeted by exercises
enum MuscleGroup {
  // Upper Push
  chest,
  upperChest,
  triceps,
  shoulders,
  sideDelts,

  // Upper Pull
  lats,
  rhomboids,
  back,
  lowerBack,
  rearDelts,
  rotatorCuff,
  traps,
  biceps,
  brachialis,
  forearms,

  // Legs
  quadriceps,
  glutes,
  hamstrings,
  calves,
  hipFlexors,

  // Core
  core,
  abs,
  lowerAbs,

  // Cardio / Other
  legs,
  arms,
  fullBody,
  cardiovascular,
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.upperChest:
        return 'Upper Chest';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.sideDelts:
        return 'Side Delts';
      case MuscleGroup.lats:
        return 'Lats';
      case MuscleGroup.rhomboids:
        return 'Rhomboids';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.lowerBack:
        return 'Lower Back';
      case MuscleGroup.rearDelts:
        return 'Rear Delts';
      case MuscleGroup.rotatorCuff:
        return 'Rotator Cuff';
      case MuscleGroup.traps:
        return 'Traps';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.brachialis:
        return 'Brachialis';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quadriceps:
        return 'Quadriceps';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.hipFlexors:
        return 'Hip Flexors';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.lowerAbs:
        return 'Lower Abs';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardiovascular:
        return 'Cardiovascular';
    }
  }

  /// Returns the region this muscle group belongs to for UI grouping
  MuscleGroupRegion get region {
    switch (this) {
      // Upper Push
      case MuscleGroup.chest:
      case MuscleGroup.upperChest:
      case MuscleGroup.triceps:
      case MuscleGroup.shoulders:
      case MuscleGroup.sideDelts:
        return MuscleGroupRegion.upperPush;

      // Upper Pull
      case MuscleGroup.lats:
      case MuscleGroup.rhomboids:
      case MuscleGroup.back:
      case MuscleGroup.lowerBack:
      case MuscleGroup.rearDelts:
      case MuscleGroup.rotatorCuff:
      case MuscleGroup.traps:
      case MuscleGroup.biceps:
      case MuscleGroup.brachialis:
      case MuscleGroup.forearms:
        return MuscleGroupRegion.upperPull;

      // Legs
      case MuscleGroup.quadriceps:
      case MuscleGroup.glutes:
      case MuscleGroup.hamstrings:
      case MuscleGroup.calves:
      case MuscleGroup.hipFlexors:
      case MuscleGroup.legs:
        return MuscleGroupRegion.legs;

      // Core
      case MuscleGroup.core:
      case MuscleGroup.abs:
      case MuscleGroup.lowerAbs:
        return MuscleGroupRegion.core;

      // Cardio / Full Body
      case MuscleGroup.cardiovascular:
      case MuscleGroup.fullBody:
        return MuscleGroupRegion.cardio;

      // Other
      case MuscleGroup.arms:
        return MuscleGroupRegion.other;
    }
  }

  /// Returns all muscle groups for a given region
  static List<MuscleGroup> byRegion(MuscleGroupRegion region) {
    return MuscleGroup.values.where((m) => m.region == region).toList();
  }
}
