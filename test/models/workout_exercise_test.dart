import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';

void main() {
  group('WorkoutExercise.removeSet', () {
    late WorkoutExercise exercise;

    setUp(() {
      exercise = WorkoutExercise(
        id: 'ex1',
        exercise: Exercise(
          id: 'base1',
          name: 'Bench Press',
          category: ExerciseCategory.strength,
          targetMuscleGroups: [MuscleGroup.chest],
          defaultSets: 3,
          defaultReps: 10,
        ),
        sets: [
          ExerciseSet.create(targetReps: 10, targetWeight: 100),
          ExerciseSet.create(targetReps: 8, targetWeight: 110),
          ExerciseSet.create(targetReps: 6, targetWeight: 120),
        ],
      );
    });

    test('removes set at valid index', () {
      final initialCount = exercise.sets.length;
      final result = exercise.removeSet(1);
      expect(result, isTrue);
      expect(exercise.sets.length, initialCount - 1);
      expect(exercise.sets[0].targetWeight, 100);
      expect(exercise.sets[1].targetWeight, 120);
    });

    test('returns false for negative index', () {
      final result = exercise.removeSet(-1);
      expect(result, isFalse);
      expect(exercise.sets.length, 3);
    });

    test('returns false for out-of-bounds index', () {
      final result = exercise.removeSet(3);
      expect(result, isFalse);
      expect(exercise.sets.length, 3);
    });

    test('removes all sets one by one', () {
      expect(exercise.removeSet(2), isTrue);
      expect(exercise.removeSet(1), isTrue);
      expect(exercise.removeSet(0), isTrue);
      expect(exercise.sets, isEmpty);
    });
  });
}
