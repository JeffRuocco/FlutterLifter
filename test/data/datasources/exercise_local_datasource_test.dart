import 'package:flutter_lifter/data/datasources/local/exercise_local_datasource.dart';
import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/models/user_exercise_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseLocalDataSource', () {
    late ExerciseLocalDataSource datasource;

    setUp(() {
      // Clear static caches before each test to ensure isolation
      ExerciseLocalDataSourceImpl.clearAllCaches();
      datasource = ExerciseLocalDataSourceImpl();
    });

    group('Custom Exercises Cache', () {
      late Exercise testExercise;

      setUp(() {
        testExercise = Exercise(
          id: 'test_exercise',
          name: 'Test Exercise',
          category: ExerciseCategory.strength,
          targetMuscleGroups: ['Test'],
          defaultSets: 3,
          defaultReps: 10,
          isDefault: false,
        );
      });

      test('cacheCustomExercise should store exercise', () async {
        await datasource.cacheCustomExercise(testExercise);

        final exercises = await datasource.getCachedCustomExercises();
        expect(exercises.length, equals(1));
        expect(exercises.first.id, equals('test_exercise'));
      });

      test('cacheCustomExercise should update existing exercise', () async {
        await datasource.cacheCustomExercise(testExercise);

        final updated = testExercise.copyWith(name: 'Updated Name');
        await datasource.cacheCustomExercise(updated);

        final exercises = await datasource.getCachedCustomExercises();
        expect(exercises.length, equals(1));
        expect(exercises.first.name, equals('Updated Name'));
      });

      test('cacheCustomExercises should replace all exercises', () async {
        await datasource.cacheCustomExercise(testExercise);

        final newExercises = [
          Exercise(
            id: 'new_1',
            name: 'New Exercise 1',
            category: ExerciseCategory.cardio,
            targetMuscleGroups: ['Legs'],
            defaultSets: 1,
            defaultReps: 30,
            isDefault: false,
          ),
          Exercise(
            id: 'new_2',
            name: 'New Exercise 2',
            category: ExerciseCategory.flexibility,
            targetMuscleGroups: ['Full Body'],
            defaultSets: 2,
            defaultReps: 60,
            isDefault: false,
          ),
        ];

        await datasource.cacheCustomExercises(newExercises);

        final exercises = await datasource.getCachedCustomExercises();
        expect(exercises.length, equals(2));
        expect(exercises.any((e) => e.id == 'test_exercise'), isFalse);
        expect(exercises.any((e) => e.id == 'new_1'), isTrue);
        expect(exercises.any((e) => e.id == 'new_2'), isTrue);
      });

      test('getCachedCustomExerciseById should find exercise', () async {
        await datasource.cacheCustomExercise(testExercise);

        final found = await datasource.getCachedCustomExerciseById(
          'test_exercise',
        );

        expect(found, isNotNull);
        expect(found!.name, equals('Test Exercise'));
      });

      test('getCachedCustomExerciseById should use exact key matching',
          () async {
        await datasource.cacheCustomExercise(testExercise);

        // Datasource uses exact key matching (repository handles case conversion)
        final found = await datasource.getCachedCustomExerciseById(
          'test_exercise',
        );
        final notFound = await datasource.getCachedCustomExerciseById(
          'TEST_EXERCISE',
        );

        expect(found, isNotNull);
        expect(notFound, isNull);
      });

      test('getCachedCustomExerciseById should return null for non-existent',
          () async {
        final found = await datasource.getCachedCustomExerciseById(
          'does_not_exist',
        );

        expect(found, isNull);
      });

      test('removeCustomExercise should delete exercise', () async {
        await datasource.cacheCustomExercise(testExercise);
        expect((await datasource.getCachedCustomExercises()).length, equals(1));

        await datasource.removeCustomExercise('test_exercise');

        expect((await datasource.getCachedCustomExercises()).length, equals(0));
      });

      test('removeCustomExercise should use exact key matching', () async {
        await datasource.cacheCustomExercise(testExercise);

        // Wrong case won't remove
        await datasource.removeCustomExercise('TEST_EXERCISE');
        expect((await datasource.getCachedCustomExercises()).length, equals(1));

        // Correct case removes
        await datasource.removeCustomExercise('test_exercise');
        expect((await datasource.getCachedCustomExercises()).length, equals(0));
      });

      test('clearCustomExercisesCache should remove all exercises', () async {
        await datasource.cacheCustomExercise(testExercise);
        await datasource.cacheCustomExercise(
          testExercise.copyWith(id: 'test_2'),
        );

        await datasource.clearCustomExercisesCache();

        expect((await datasource.getCachedCustomExercises()).length, equals(0));
      });
    });

    group('User Preferences Cache', () {
      late UserExercisePreferences testPreference;

      setUp(() {
        testPreference = UserExercisePreferences.create(
          exerciseId: 'bench',
          preferredSets: 5,
          preferredReps: 5,
          preferredWeight: 225.0,
        );
      });

      test('cachePreference should store preference', () async {
        await datasource.cachePreference(testPreference);

        final prefs = await datasource.getCachedPreferences();
        expect(prefs.length, equals(1));
        expect(prefs.first.exerciseId, equals('bench'));
      });

      test('cachePreference should update existing preference', () async {
        await datasource.cachePreference(testPreference);

        final updated = testPreference.copyWith(preferredSets: 8);
        await datasource.cachePreference(updated);

        final prefs = await datasource.getCachedPreferences();
        expect(prefs.length, equals(1));
        expect(prefs.first.preferredSets, equals(8));
      });

      test('cachePreferences should replace all preferences', () async {
        await datasource.cachePreference(testPreference);

        final newPrefs = [
          UserExercisePreferences.create(
            exerciseId: 'squat',
            preferredSets: 4,
          ),
          UserExercisePreferences.create(
            exerciseId: 'deadlift',
            preferredSets: 3,
          ),
        ];

        await datasource.cachePreferences(newPrefs);

        final prefs = await datasource.getCachedPreferences();
        expect(prefs.length, equals(2));
        expect(prefs.any((p) => p.exerciseId == 'bench'), isFalse);
        expect(prefs.any((p) => p.exerciseId == 'squat'), isTrue);
        expect(prefs.any((p) => p.exerciseId == 'deadlift'), isTrue);
      });

      test('getCachedPreferenceForExercise should find preference', () async {
        await datasource.cachePreference(testPreference);

        final found = await datasource.getCachedPreferenceForExercise('bench');

        expect(found, isNotNull);
        expect(found!.preferredSets, equals(5));
      });

      test('getCachedPreferenceForExercise should return null for non-existent',
          () async {
        final found = await datasource.getCachedPreferenceForExercise(
          'does_not_exist',
        );

        expect(found, isNull);
      });

      test('removePreference should delete preference', () async {
        await datasource.cachePreference(testPreference);
        expect((await datasource.getCachedPreferences()).length, equals(1));

        await datasource.removePreference('bench');

        expect((await datasource.getCachedPreferences()).length, equals(0));
      });

      test('clearPreferencesCache should remove all preferences', () async {
        await datasource.cachePreference(testPreference);
        await datasource.cachePreference(
          UserExercisePreferences.create(
            exerciseId: 'squat',
            preferredSets: 4,
          ),
        );

        await datasource.clearPreferencesCache();

        expect((await datasource.getCachedPreferences()).length, equals(0));
      });
    });

    group('Cache Timestamps', () {
      test('getLastCustomExercisesCacheUpdate should return null when empty',
          () async {
        final timestamp = await datasource.getLastCustomExercisesCacheUpdate();

        expect(timestamp, isNull);
      });

      test(
          'getLastCustomExercisesCacheUpdate should return timestamp after caching',
          () async {
        final before = DateTime.now();

        await datasource.cacheCustomExercise(
          Exercise(
            id: 'test',
            name: 'Test',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Test'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );

        final timestamp = await datasource.getLastCustomExercisesCacheUpdate();
        final after = DateTime.now();

        expect(timestamp, isNotNull);
        expect(timestamp!.isAfter(before) || timestamp.isAtSameMomentAs(before),
            isTrue);
        expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after),
            isTrue);
      });

      test('getLastPreferencesCacheUpdate should return null when empty',
          () async {
        final timestamp = await datasource.getLastPreferencesCacheUpdate();

        expect(timestamp, isNull);
      });

      test(
          'getLastPreferencesCacheUpdate should return timestamp after caching',
          () async {
        final before = DateTime.now();

        await datasource.cachePreference(
          UserExercisePreferences.create(
            exerciseId: 'bench',
            preferredSets: 5,
          ),
        );

        final timestamp = await datasource.getLastPreferencesCacheUpdate();
        final after = DateTime.now();

        expect(timestamp, isNotNull);
        expect(timestamp!.isAfter(before) || timestamp.isAtSameMomentAs(before),
            isTrue);
        expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after),
            isTrue);
      });
    });

    group('Cache Expiration', () {
      test('isCustomExercisesCacheExpired should return true when empty',
          () async {
        final expired = await datasource.isCustomExercisesCacheExpired(
          maxAge: const Duration(minutes: 5),
        );

        expect(expired, isTrue);
      });

      test('isCustomExercisesCacheExpired should return false when fresh',
          () async {
        await datasource.cacheCustomExercise(
          Exercise(
            id: 'test',
            name: 'Test',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Test'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );

        final expired = await datasource.isCustomExercisesCacheExpired(
          maxAge: const Duration(minutes: 5),
        );

        expect(expired, isFalse);
      });

      test('isPreferencesCacheExpired should return true when empty', () async {
        final expired = await datasource.isPreferencesCacheExpired(
          maxAge: const Duration(minutes: 5),
        );

        expect(expired, isTrue);
      });

      test('isPreferencesCacheExpired should return false when fresh',
          () async {
        await datasource.cachePreference(
          UserExercisePreferences.create(
            exerciseId: 'bench',
            preferredSets: 5,
          ),
        );

        final expired = await datasource.isPreferencesCacheExpired(
          maxAge: const Duration(minutes: 5),
        );

        expect(expired, isFalse);
      });
    });

    group('Static Cache Clearing', () {
      test('clearAllCaches should reset all caches across instances', () async {
        // Use one instance to cache data
        await datasource.cacheCustomExercise(
          Exercise(
            id: 'test',
            name: 'Test',
            category: ExerciseCategory.strength,
            targetMuscleGroups: ['Test'],
            defaultSets: 3,
            defaultReps: 10,
            isDefault: false,
          ),
        );
        await datasource.cachePreference(
          UserExercisePreferences.create(
            exerciseId: 'bench',
            preferredSets: 5,
          ),
        );

        // Clear all static caches
        ExerciseLocalDataSourceImpl.clearAllCaches();

        // Create new instance and verify caches are empty
        final newDatasource = ExerciseLocalDataSourceImpl();
        expect(
          (await newDatasource.getCachedCustomExercises()).length,
          equals(0),
        );
        expect(
          (await newDatasource.getCachedPreferences()).length,
          equals(0),
        );
      });
    });

    group('Default Cache Max Age', () {
      test('defaultCacheMaxAge should be 5 minutes', () {
        expect(
          ExerciseLocalDataSource.defaultCacheMaxAge,
          equals(const Duration(minutes: 5)),
        );
      });
    });
  });
}
