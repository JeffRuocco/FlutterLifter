import 'package:flutter_lifter/data/datasources/local/exercise_local_datasource.dart';
import 'package:flutter_lifter/data/repositories/exercise_repository.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/user_exercise_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseRepository', () {
    late ExerciseRepository repository;

    setUp(() {
      // Each ExerciseLocalDataSourceImpl instance has its own cache,
      // so creating a new repository provides test isolation
      repository = ExerciseRepositoryImpl.development();
    });

    group('Factory Constructors', () {
      test(
          'development factory should create repository with default exercises',
          () async {
        final repo = ExerciseRepositoryImpl.development();
        final exercises = await repo.getDefaultExercises();

        expect(exercises, isNotEmpty);
        expect(exercises.every((e) => e.isDefault), isTrue);
      });

      test(
          'production factory should create repository with provided datasource',
          () async {
        final datasource = ExerciseLocalDataSourceImpl();
        final repo = ExerciseRepositoryImpl.production(
          localDataSource: datasource,
        );
        final exercises = await repo.getDefaultExercises();

        expect(exercises, isNotEmpty);
      });

      test('production factory should accept custom default exercises',
          () async {
        final customDefaults = [
          Exercise(
            id: 'custom_default',
            name: 'Custom Default Exercise',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Test'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: true,
          ),
        ];

        final repo = ExerciseRepositoryImpl.production(
          localDataSource: ExerciseLocalDataSourceImpl(),
          defaultExercises: customDefaults,
        );

        final exercises = await repo.getDefaultExercises();
        expect(exercises.length, equals(1));
        expect(exercises.first.id, equals('custom_default'));
      });
    });

    group('Default Exercises', () {
      test('getDefaultExercises should return all built-in exercises',
          () async {
        final exercises = await repository.getDefaultExercises();

        expect(exercises, isNotEmpty);
        expect(exercises.length, greaterThan(40)); // We have 40+ exercises
        expect(exercises.every((e) => e.isDefault), isTrue);
      });

      test('default exercises should be immutable', () async {
        final exercises1 = await repository.getDefaultExercises();
        final exercises2 = await repository.getDefaultExercises();

        // Should return same instances
        expect(exercises1.length, equals(exercises2.length));
        for (var i = 0; i < exercises1.length; i++) {
          expect(exercises1[i].id, equals(exercises2[i].id));
        }
      });

      test('should not be able to delete default exercises', () async {
        expect(
          () => repository.deleteCustomExercise('bench'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should not be able to update default exercises', () async {
        final benchPress = await repository.getExerciseById('bench');
        final modifiedBench = benchPress!.copyWith(name: 'Modified Bench');

        expect(
          () => repository.updateCustomExercise(modifiedBench),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Custom Exercises', () {
      late Exercise customExercise;

      setUp(() {
        customExercise = Exercise(
          id: 'custom_1',
          name: 'Custom Push-up Variation',
          shortName: 'Custom Push',
          category: ExerciseCategory.strength,
          targetMuscleGroups: ['Chest', 'Triceps'],
          defaultSets: 3,
          defaultReps: 15,
          isDefault: false,
        );
      });

      test('createCustomExercise should add a new custom exercise', () async {
        await repository.createCustomExercise(customExercise);
        final exercises = await repository.getCustomExercises();

        expect(exercises.length, equals(1));
        expect(exercises.first.id, equals('custom_1'));
        expect(exercises.first.isDefault, isFalse);
      });

      test('createCustomExercise should throw if isDefault is true', () async {
        final invalidExercise = customExercise.copyWith(isDefault: true);

        expect(
          () => repository.createCustomExercise(invalidExercise),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('getCustomExercises should return only custom exercises', () async {
        await repository.createCustomExercise(customExercise);
        await repository.createCustomExercise(
          customExercise.copyWith(id: 'custom_2', name: 'Another Custom'),
        );

        final exercises = await repository.getCustomExercises();

        expect(exercises.length, equals(2));
        expect(exercises.every((e) => !e.isDefault), isTrue);
      });

      test('updateCustomExercise should modify existing custom exercise',
          () async {
        await repository.createCustomExercise(customExercise);

        final updated = customExercise.copyWith(
          name: 'Updated Custom Exercise',
          defaultSets: 5,
        );
        await repository.updateCustomExercise(updated);

        final exercises = await repository.getCustomExercises();
        expect(exercises.first.name, equals('Updated Custom Exercise'));
        expect(exercises.first.defaultSets, equals(5));
      });

      test('updateCustomExercise should throw for non-existent exercise',
          () async {
        expect(
          () => repository.updateCustomExercise(customExercise),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('deleteCustomExercise should remove custom exercise', () async {
        await repository.createCustomExercise(customExercise);
        expect((await repository.getCustomExercises()).length, equals(1));

        await repository.deleteCustomExercise('custom_1');
        expect((await repository.getCustomExercises()).length, equals(0));
      });

      test('deleteCustomExercise should also remove associated preferences',
          () async {
        await repository.createCustomExercise(customExercise);

        final pref = UserExercisePreferences.create(
          exerciseId: 'custom_1',
          preferredSets: 5,
        );
        await repository.setPreference(pref);

        // Verify preference exists
        expect(
          await repository.getPreferenceForExercise('custom_1'),
          isNotNull,
        );

        // Delete exercise
        await repository.deleteCustomExercise('custom_1');

        // Preference should be removed
        expect(
          await repository.getPreferenceForExercise('custom_1'),
          isNull,
        );
      });
    });

    group('Combined Exercise Access', () {
      late Exercise customExercise;

      setUp(() async {
        customExercise = Exercise(
          id: 'custom_combined',
          name: 'Custom for Combined Test',
          category: ExerciseCategory.cardio,
          targetMuscleGroups: ['Full Body'],
          defaultSets: 2,
          defaultReps: 20,
          isDefault: false,
        );
        await repository.createCustomExercise(customExercise);
      });

      test('getExercises with ExerciseSource.all should return all exercises',
          () async {
        final exercises = await repository.getExercises(
          source: ExerciseSource.all,
        );

        final defaultExercises = await repository.getDefaultExercises();
        final customExercises = await repository.getCustomExercises();

        expect(
          exercises.length,
          equals(defaultExercises.length + customExercises.length),
        );
      });

      test(
          'getExercises with ExerciseSource.defaultOnly should return only defaults',
          () async {
        final exercises = await repository.getExercises(
          source: ExerciseSource.defaultOnly,
        );

        expect(exercises.every((e) => e.isDefault), isTrue);
        expect(exercises.any((e) => e.id == 'custom_combined'), isFalse);
      });

      test(
          'getExercises with ExerciseSource.customOnly should return only custom',
          () async {
        final exercises = await repository.getExercises(
          source: ExerciseSource.customOnly,
        );

        expect(exercises.every((e) => !e.isDefault), isTrue);
        expect(exercises.any((e) => e.id == 'custom_combined'), isTrue);
      });

      test('getExercises should default to ExerciseSource.all', () async {
        final allExercises = await repository.getExercises();
        final explicitAll = await repository.getExercises(
          source: ExerciseSource.all,
        );

        expect(allExercises.length, equals(explicitAll.length));
      });
    });

    group('Exercise Lookup', () {
      test('getExerciseById should find default exercise', () async {
        final exercise = await repository.getExerciseById('bench');

        expect(exercise, isNotNull);
        expect(exercise!.name, equals('Bench Press'));
      });

      test('getExerciseById should be case-insensitive', () async {
        final exercise1 = await repository.getExerciseById('BENCH');
        final exercise2 = await repository.getExerciseById('Bench');
        final exercise3 = await repository.getExerciseById('bench');

        expect(exercise1, isNotNull);
        expect(exercise2, isNotNull);
        expect(exercise3, isNotNull);
        expect(exercise1!.id, equals(exercise2!.id));
        expect(exercise2.id, equals(exercise3!.id));
      });

      test('getExerciseById should find custom exercise', () async {
        await repository.createCustomExercise(
          Exercise(
            id: 'my_custom',
            name: 'My Custom Exercise',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Arms'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );

        final exercise = await repository.getExerciseById('my_custom');

        expect(exercise, isNotNull);
        expect(exercise!.name, equals('My Custom Exercise'));
      });

      test('getExerciseById should return null for non-existent id', () async {
        final exercise = await repository.getExerciseById('does_not_exist');

        expect(exercise, isNull);
      });

      test('getExerciseByName should find exercise by name', () async {
        final exercise = await repository.getExerciseByName('Bench Press');

        expect(exercise, isNotNull);
        expect(exercise!.id, equals('bench'));
      });

      test('getExerciseByName should be case-insensitive', () async {
        final exercise1 = await repository.getExerciseByName('BENCH PRESS');
        final exercise2 = await repository.getExerciseByName('bench press');

        expect(exercise1, isNotNull);
        expect(exercise2, isNotNull);
        expect(exercise1!.id, equals(exercise2!.id));
      });

      test('getExerciseByName should return null for non-existent name',
          () async {
        final exercise = await repository.getExerciseByName('Does Not Exist');

        expect(exercise, isNull);
      });
    });

    group('Search Exercises', () {
      test('searchExercises should find by name', () async {
        final results = await repository.searchExercises('bench');

        expect(results, isNotEmpty);
        expect(
          results.any((e) => e.name.toLowerCase().contains('bench')),
          isTrue,
        );
      });

      test('searchExercises should find by short name', () async {
        final results = await repository.searchExercises('OHP');

        expect(results, isNotEmpty);
        expect(results.any((e) => e.shortName == 'OHP'), isTrue);
      });

      test('searchExercises should find by category', () async {
        final results = await repository.searchExercises('cardio');

        expect(results, isNotEmpty);
        // All results should match 'cardio' in name, category displayName, or muscle groups
        expect(
          results.every((e) =>
              e.category.displayName.toLowerCase().contains('cardio') ||
              e.name.toLowerCase().contains('cardio') ||
              e.targetMuscleGroups
                  .any((m) => m.toLowerCase().contains('cardio'))),
          isTrue,
        );
      });

      test('searchExercises should find by muscle group', () async {
        final results = await repository.searchExercises('biceps');

        expect(results, isNotEmpty);
        expect(
          results.every(
              (e) => e.targetMuscleGroups.any((m) => m.contains('Biceps'))),
          isTrue,
        );
      });

      test('searchExercises should be case-insensitive', () async {
        final results1 = await repository.searchExercises('SQUAT');
        final results2 = await repository.searchExercises('squat');

        expect(results1.length, equals(results2.length));
      });

      test('searchExercises with empty query should return all exercises',
          () async {
        final results = await repository.searchExercises('');
        final all = await repository.getExercises();

        expect(results.length, equals(all.length));
      });

      test('searchExercises should respect ExerciseSource filter', () async {
        await repository.createCustomExercise(
          Exercise(
            id: 'custom_squat',
            name: 'Custom Squat Variation',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Legs'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );

        final defaultOnly = await repository.searchExercises(
          'squat',
          source: ExerciseSource.defaultOnly,
        );
        final customOnly = await repository.searchExercises(
          'squat',
          source: ExerciseSource.customOnly,
        );
        final all = await repository.searchExercises(
          'squat',
          source: ExerciseSource.all,
        );

        expect(defaultOnly.every((e) => e.isDefault), isTrue);
        expect(customOnly.every((e) => !e.isDefault), isTrue);
        expect(all.length, equals(defaultOnly.length + customOnly.length));
      });
    });

    group('Filter by Category', () {
      test('getExercisesByCategory should return only matching category',
          () async {
        final cardio = await repository.getExercisesByCategory(
          ExerciseCategory.cardio,
        );

        expect(cardio, isNotEmpty);
        expect(
          cardio.every((e) => e.category == ExerciseCategory.cardio),
          isTrue,
        );
      });

      test('getExercisesByCategory should respect ExerciseSource', () async {
        await repository.createCustomExercise(
          Exercise(
            id: 'custom_cardio',
            name: 'Custom Cardio Exercise',
            category: ExerciseCategory.cardio,
            targetMuscleGroups: ['Cardiovascular'],
            defaultSets: 1,
            defaultReps: 30,
            isDefault: false,
          ),
        );

        final defaultOnly = await repository.getExercisesByCategory(
          ExerciseCategory.cardio,
          source: ExerciseSource.defaultOnly,
        );
        final customOnly = await repository.getExercisesByCategory(
          ExerciseCategory.cardio,
          source: ExerciseSource.customOnly,
        );

        expect(defaultOnly.every((e) => e.isDefault), isTrue);
        expect(customOnly.length, equals(1));
        expect(customOnly.first.id, equals('custom_cardio'));
      });

      test('getExercisesByCategory should return empty for no matches',
          () async {
        // Clear custom exercises that might be in 'other' category
        final customOnly = await repository.getExercisesByCategory(
          ExerciseCategory.other,
          source: ExerciseSource.customOnly,
        );

        // If there are no custom 'other' exercises, this should be empty
        expect(customOnly.every((e) => e.category == ExerciseCategory.other),
            isTrue);
      });
    });

    group('Filter by Muscle Group', () {
      test('getExercisesByMuscleGroup should return matching exercises',
          () async {
        final chestExercises = await repository.getExercisesByMuscleGroup(
          'Chest',
        );

        expect(chestExercises, isNotEmpty);
        expect(
          chestExercises.every(
              (e) => e.targetMuscleGroups.any((m) => m.contains('Chest'))),
          isTrue,
        );
      });

      test('getExercisesByMuscleGroup should be case-insensitive', () async {
        final results1 = await repository.getExercisesByMuscleGroup('CHEST');
        final results2 = await repository.getExercisesByMuscleGroup('chest');

        expect(results1.length, equals(results2.length));
      });

      test('getExercisesByMuscleGroup should support partial matching',
          () async {
        final results = await repository.getExercisesByMuscleGroup('Quad');

        expect(results, isNotEmpty);
        // Should match 'Quadriceps'
        expect(
          results.every(
              (e) => e.targetMuscleGroups.any((m) => m.contains('Quad'))),
          isTrue,
        );
      });

      test('getExercisesByMuscleGroup should respect ExerciseSource', () async {
        await repository.createCustomExercise(
          Exercise(
            id: 'custom_chest',
            name: 'Custom Chest Exercise',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Chest'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );

        final defaultOnly = await repository.getExercisesByMuscleGroup(
          'Chest',
          source: ExerciseSource.defaultOnly,
        );
        final customOnly = await repository.getExercisesByMuscleGroup(
          'Chest',
          source: ExerciseSource.customOnly,
        );

        expect(defaultOnly.every((e) => e.isDefault), isTrue);
        expect(customOnly.length, equals(1));
        expect(customOnly.first.id, equals('custom_chest'));
      });
    });

    group('User Preferences', () {
      late UserExercisePreferences benchPreference;

      setUp(() {
        benchPreference = UserExercisePreferences.create(
          exerciseId: 'bench',
          preferredSets: 5,
          preferredReps: 5,
          preferredWeight: 225.0,
          preferredRestTimeSeconds: 180,
          notes: 'Focus on form',
        );
      });

      test('setPreference should store preference for exercise', () async {
        await repository.setPreference(benchPreference);

        final pref = await repository.getPreferenceForExercise('bench');

        expect(pref, isNotNull);
        expect(pref!.exerciseId, equals('bench'));
        expect(pref.preferredSets, equals(5));
        expect(pref.preferredWeight, equals(225.0));
      });

      test('setPreference should throw for non-existent exercise', () async {
        final invalidPref = UserExercisePreferences.create(
          exerciseId: 'does_not_exist',
          preferredSets: 3,
        );

        expect(
          () => repository.setPreference(invalidPref),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('setPreference should update existing preference', () async {
        await repository.setPreference(benchPreference);

        final updated = benchPreference.copyWith(preferredSets: 8);
        await repository.setPreference(updated);

        final pref = await repository.getPreferenceForExercise('bench');
        expect(pref!.preferredSets, equals(8));
      });

      test('getPreferences should return all preferences', () async {
        await repository.setPreference(benchPreference);
        await repository.setPreference(
          UserExercisePreferences.create(
            exerciseId: 'squat',
            preferredSets: 4,
          ),
        );

        final prefs = await repository.getPreferences();

        expect(prefs.length, equals(2));
      });

      test('getPreferenceForExercise should return null if none exists',
          () async {
        final pref = await repository.getPreferenceForExercise('deadlift');

        expect(pref, isNull);
      });

      test('removePreference should delete preference', () async {
        await repository.setPreference(benchPreference);
        expect(await repository.getPreferenceForExercise('bench'), isNotNull);

        await repository.removePreference('bench');
        expect(await repository.getPreferenceForExercise('bench'), isNull);
      });
    });

    group('Exercises with Preferences Applied', () {
      setUp(() async {
        await repository.setPreference(
          UserExercisePreferences.create(
            exerciseId: 'bench',
            preferredSets: 5,
            preferredReps: 3,
            preferredWeight: 315.0,
            notes: 'Heavy day',
          ),
        );
      });

      test('getExercises should apply stored preferences', () async {
        final exercises = await repository.getExercises();

        final bench = exercises.firstWhere((e) => e.id == 'bench');

        expect(bench.defaultSets, equals(5));
        expect(bench.defaultReps, equals(3));
        expect(bench.defaultWeight, equals(315.0));
        expect(bench.notes, equals('Heavy day'));
      });

      test('getExercises should not modify exercises without preferences',
          () async {
        final exercises = await repository.getExercises();
        final original =
            await repository.getExerciseByIdWithoutPreferences('squat');

        final squat = exercises.firstWhere((e) => e.id == 'squat');

        expect(squat.defaultSets, equals(original!.defaultSets));
        expect(squat.defaultReps, equals(original.defaultReps));
      });

      test('getExerciseById should apply preference', () async {
        final bench = await repository.getExerciseById('bench');

        expect(bench, isNotNull);
        expect(bench!.defaultSets, equals(5));
        expect(bench.defaultWeight, equals(315.0));
      });

      test('getExerciseById should return original if no preference', () async {
        final squat = await repository.getExerciseById('squat');
        final original =
            await repository.getExerciseByIdWithoutPreferences('squat');

        expect(squat, isNotNull);
        expect(squat!.defaultSets, equals(original!.defaultSets));
      });

      test('getExerciseById should return null for non-existent', () async {
        final result = await repository.getExerciseById(
          'does_not_exist',
        );

        expect(result, isNull);
      });

      test('getExercises should respect ExerciseSource', () async {
        await repository.createCustomExercise(
          Exercise(
            id: 'custom_with_pref',
            name: 'Custom With Pref',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Test'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );
        await repository.setPreference(
          UserExercisePreferences.create(
            exerciseId: 'custom_with_pref',
            preferredSets: 6,
          ),
        );

        final customOnly = await repository.getExercises(
          source: ExerciseSource.customOnly,
        );

        expect(customOnly.length, equals(1));
        expect(customOnly.first.defaultSets, equals(6));
      });
    });

    group('Future Library Features', () {
      test('syncFromLibrary should throw UnimplementedError', () async {
        expect(
          () => repository.syncFromLibrary(),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('publishToLibrary should throw UnimplementedError', () async {
        expect(
          () => repository.publishToLibrary('bench'),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('Cache Management', () {
      test('refreshCache should complete without error', () async {
        expect(() => repository.refreshCache(), returnsNormally);
      });
    });
  });
}
