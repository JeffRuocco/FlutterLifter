import 'package:flutter/material.dart';
import 'package:flutter_lifter/models/exercise_models.dart';

import 'exercise_picker.dart';

/// A bottom sheet for adding or swapping exercises in a workout.
///
/// This is a convenience wrapper around [ExercisePicker] that handles
/// converting the selected [Exercise] to a [WorkoutExercise] with default sets.
class AddExerciseBottomSheet extends StatelessWidget {
  /// Called when an exercise is selected and converted to a WorkoutExercise
  final Function(WorkoutExercise exercise) onExerciseAdded;

  /// If true, shows as a swap operation instead of add
  final bool isSwapping;

  /// The current exercise being swapped (shown as disabled in the list)
  final WorkoutExercise? currentExercise;

  const AddExerciseBottomSheet({
    super.key,
    required this.onExerciseAdded,
    this.isSwapping = false,
    this.currentExercise,
  });

  /// Shows the exercise picker as a modal bottom sheet and handles
  /// the conversion to WorkoutExercise.
  ///
  /// Returns the created [WorkoutExercise] or null if dismissed.
  static Future<WorkoutExercise?> show(
    BuildContext context, {
    bool isSwapping = false,
    WorkoutExercise? currentExercise,
  }) async {
    final exercise = await ExercisePicker.show(
      context,
      title: isSwapping ? 'Swap Exercise' : 'Add Exercise',
      subtitle: isSwapping
          ? 'Select a new exercise to replace the current one'
          : null,
      isSwapping: isSwapping,
      currentExercise: currentExercise?.exercise,
    );

    if (exercise == null) return null;

    return _createWorkoutExercise(exercise);
  }

  static WorkoutExercise _createWorkoutExercise(Exercise template) {
    return WorkoutExercise.create(
      exercise: template,
      sets: List.generate(
        template.defaultSets,
        (index) => ExerciseSet.create(
          targetReps: template.defaultReps,
          targetWeight: template.defaultWeight,
        ),
      ),
      restTime: Duration(seconds: template.defaultRestTimeSeconds),
      notes: template.notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExercisePicker(
      title: isSwapping ? 'Swap Exercise' : 'Add Exercise',
      subtitle: isSwapping
          ? 'Select a new exercise to replace the current one'
          : null,
      isSwapping: isSwapping,
      currentExercise: currentExercise?.exercise,
      onExerciseSelected: (exercise) {
        final workoutExercise = _createWorkoutExercise(exercise);
        onExerciseAdded(workoutExercise);
        Navigator.of(context).pop();
      },
    );
  }
}
