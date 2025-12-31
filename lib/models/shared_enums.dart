/// Shared enums and types used across multiple model files
library shared_enums;

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
enum ProgramDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

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
