import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_lifter/services/storage_service.dart';

void main() {
  group('HiveStorageService', () {
    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});

      // Initialize AppSettingsService and LoggingService for error handling tests
      final appSettingsService = AppSettingsService();
      await appSettingsService.init();
      await LoggingService.init(appSettingsService);

      // Initialize Hive for testing with a temporary directory
      Hive.init('./test_hive');
      await HiveStorageService.initializeBoxes();
    });

    tearDownAll(() async {
      await HiveStorageService.clearAllData();
      await HiveStorageService.closeBoxes();
    });

    group('initialization', () {
      test('isInitialized returns true after initializeBoxes', () {
        expect(HiveStorageService.isInitialized, isTrue);
      });

      test('init() calls initializeBoxes', () async {
        final service = HiveStorageService();
        // Should not throw since already initialized
        await service.init();
        expect(HiveStorageService.isInitialized, isTrue);
      });
    });

    group('general storage operations', () {
      final service = HiveStorageService();

      setUp(() async {
        await service.clear();
      });

      test('store and retrieve string value', () async {
        await service.store('test_key', 'test_value');
        final result = await service.retrieve<String>('test_key');
        expect(result, equals('test_value'));
      });

      test('store and retrieve int value', () async {
        await service.store('int_key', 42);
        final result = await service.retrieve<int>('int_key');
        expect(result, equals(42));
      });

      test('store and retrieve double value', () async {
        await service.store('double_key', 3.14);
        final result = await service.retrieve<double>('double_key');
        expect(result, equals(3.14));
      });

      test('store and retrieve bool value', () async {
        await service.store('bool_key', true);
        final result = await service.retrieve<bool>('bool_key');
        expect(result, isTrue);
      });

      test('store and retrieve list value', () async {
        await service.store('list_key', [1, 2, 3]);
        final result = await service.retrieve<List>('list_key');
        expect(result, equals([1, 2, 3]));
      });

      test('store and retrieve complex object as JSON', () async {
        final obj = {'name': 'Test', 'value': 123};
        await service.store('obj_key', obj);
        final result = await service.retrieve<Map<String, dynamic>>('obj_key');
        expect(result, equals(obj));
      });

      test('retrieve returns null for non-existent key', () async {
        final result = await service.retrieve<String>('non_existent');
        expect(result, isNull);
      });

      test('remove deletes a key', () async {
        await service.store('remove_key', 'value');
        expect(await service.containsKey('remove_key'), isTrue);
        await service.remove('remove_key');
        expect(await service.containsKey('remove_key'), isFalse);
      });

      test('containsKey returns correct result', () async {
        expect(await service.containsKey('new_key'), isFalse);
        await service.store('new_key', 'value');
        expect(await service.containsKey('new_key'), isTrue);
      });

      test('getAllKeys returns all stored keys', () async {
        await service.store('key1', 'value1');
        await service.store('key2', 'value2');
        final keys = await service.getAllKeys();
        expect(keys, containsAll(['key1', 'key2']));
      });

      test('clear removes all data', () async {
        await service.store('key1', 'value1');
        await service.store('key2', 'value2');
        await service.clear();
        expect(await service.getAllKeys(), isEmpty);
      });
    });

    group('programs box operations', () {
      setUp(() async {
        await HiveStorageService.clearPrograms();
      });

      test('storeProgram and getProgram work correctly', () async {
        final program = {'id': 'prog1', 'name': 'Test Program', 'days': 3};
        await HiveStorageService.storeProgram('prog1', program);
        final result = HiveStorageService.getProgram('prog1');
        expect(result, equals(program));
      });

      test('getProgram returns null for non-existent program', () {
        final result = HiveStorageService.getProgram('non_existent');
        expect(result, isNull);
      });

      test('getAllPrograms returns all programs', () async {
        final prog1 = {'id': 'prog1', 'name': 'Program 1'};
        final prog2 = {'id': 'prog2', 'name': 'Program 2'};
        await HiveStorageService.storeProgram('prog1', prog1);
        await HiveStorageService.storeProgram('prog2', prog2);

        final all = HiveStorageService.getAllPrograms();
        expect(all.length, equals(2));
        expect(all['prog1'], equals(prog1));
        expect(all['prog2'], equals(prog2));
      });

      test('deleteProgram removes a program', () async {
        await HiveStorageService.storeProgram('prog1', {'id': 'prog1'});
        expect(HiveStorageService.getProgram('prog1'), isNotNull);
        await HiveStorageService.deleteProgram('prog1');
        expect(HiveStorageService.getProgram('prog1'), isNull);
      });

      test('clearPrograms removes all programs', () async {
        await HiveStorageService.storeProgram('prog1', {'id': 'prog1'});
        await HiveStorageService.storeProgram('prog2', {'id': 'prog2'});
        await HiveStorageService.clearPrograms();
        expect(HiveStorageService.getAllPrograms(), isEmpty);
      });

      test('programsBox getter returns the box', () {
        expect(HiveStorageService.programsBox, isNotNull);
        expect(HiveStorageService.programsBox, isA<Box<String>>());
      });
    });

    group('custom exercises box operations', () {
      setUp(() async {
        await HiveStorageService.clearCustomExercises();
      });

      test(
        'storeCustomExercise and getCustomExercise work correctly',
        () async {
          final exercise = {
            'id': 'ex1',
            'name': 'Custom Squat',
            'muscleGroup': 'legs',
          };
          await HiveStorageService.storeCustomExercise('ex1', exercise);
          final result = HiveStorageService.getCustomExercise('ex1');
          expect(result, equals(exercise));
        },
      );

      test('custom exercise IDs are case-insensitive', () async {
        final exercise = {'id': 'EX1', 'name': 'Custom Exercise'};
        await HiveStorageService.storeCustomExercise('EX1', exercise);
        expect(HiveStorageService.getCustomExercise('ex1'), isNotNull);
        expect(HiveStorageService.getCustomExercise('EX1'), isNotNull);
      });

      test('getCustomExercise returns null for non-existent exercise', () {
        final result = HiveStorageService.getCustomExercise('non_existent');
        expect(result, isNull);
      });

      test('getAllCustomExercises returns all exercises', () async {
        await HiveStorageService.storeCustomExercise('ex1', {
          'id': 'ex1',
          'name': 'Exercise 1',
        });
        await HiveStorageService.storeCustomExercise('ex2', {
          'id': 'ex2',
          'name': 'Exercise 2',
        });

        final all = HiveStorageService.getAllCustomExercises();
        expect(all.length, equals(2));
      });

      test('deleteCustomExercise removes an exercise', () async {
        await HiveStorageService.storeCustomExercise('ex1', {'id': 'ex1'});
        await HiveStorageService.deleteCustomExercise('ex1');
        expect(HiveStorageService.getCustomExercise('ex1'), isNull);
      });

      test('clearCustomExercises removes all exercises', () async {
        await HiveStorageService.storeCustomExercise('ex1', {'id': 'ex1'});
        await HiveStorageService.storeCustomExercise('ex2', {'id': 'ex2'});
        await HiveStorageService.clearCustomExercises();
        expect(HiveStorageService.getAllCustomExercises(), isEmpty);
      });

      test('customExercisesBox getter returns the box', () {
        expect(HiveStorageService.customExercisesBox, isNotNull);
        expect(HiveStorageService.customExercisesBox, isA<Box<String>>());
      });
    });

    group('user preferences box operations', () {
      setUp(() async {
        await HiveStorageService.clearUserPreferences();
      });

      test(
        'storeUserPreference and getUserPreference work correctly',
        () async {
          final prefs = {
            'exerciseId': 'bench-press',
            'notes': 'Keep elbows at 45 degrees',
            'photoPath': '/path/to/photo.jpg',
          };
          await HiveStorageService.storeUserPreference('bench-press', prefs);
          final result = HiveStorageService.getUserPreference('bench-press');
          expect(result, equals(prefs));
        },
      );

      test('user preference IDs are case-insensitive', () async {
        final prefs = {'exerciseId': 'Squat'};
        await HiveStorageService.storeUserPreference('SQUAT', prefs);
        expect(HiveStorageService.getUserPreference('squat'), isNotNull);
      });

      test('getUserPreference returns null for non-existent preference', () {
        final result = HiveStorageService.getUserPreference('non_existent');
        expect(result, isNull);
      });

      test('getAllUserPreferences returns all preferences', () async {
        await HiveStorageService.storeUserPreference('ex1', {
          'notes': 'Note 1',
        });
        await HiveStorageService.storeUserPreference('ex2', {
          'notes': 'Note 2',
        });

        final all = HiveStorageService.getAllUserPreferences();
        expect(all.length, equals(2));
      });

      test('deleteUserPreference removes a preference', () async {
        await HiveStorageService.storeUserPreference('ex1', {'notes': 'Test'});
        await HiveStorageService.deleteUserPreference('ex1');
        expect(HiveStorageService.getUserPreference('ex1'), isNull);
      });

      test('clearUserPreferences removes all preferences', () async {
        await HiveStorageService.storeUserPreference('ex1', {
          'notes': 'Note 1',
        });
        await HiveStorageService.storeUserPreference('ex2', {
          'notes': 'Note 2',
        });
        await HiveStorageService.clearUserPreferences();
        expect(HiveStorageService.getAllUserPreferences(), isEmpty);
      });

      test('userPreferencesBox getter returns the box', () {
        expect(HiveStorageService.userPreferencesBox, isNotNull);
        expect(HiveStorageService.userPreferencesBox, isA<Box<String>>());
      });
    });

    group('sync metadata box operations', () {
      setUp(() async {
        await HiveStorageService.clearSyncMetadata();
      });

      test('storeSyncMetadata and getSyncMetadata work correctly', () async {
        final metadata = {
          'id': 'sync1',
          'lastSynced': '2026-01-11T10:00:00Z',
          'version': 1,
        };
        await HiveStorageService.storeSyncMetadata('sync1', metadata);
        final result = HiveStorageService.getSyncMetadata('sync1');
        expect(result, equals(metadata));
      });

      test('getSyncMetadata returns null for non-existent metadata', () {
        final result = HiveStorageService.getSyncMetadata('non_existent');
        expect(result, isNull);
      });

      test('getAllSyncMetadata returns all metadata', () async {
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        await HiveStorageService.storeSyncMetadata('sync2', {'id': 'sync2'});

        final all = HiveStorageService.getAllSyncMetadata();
        expect(all.length, equals(2));
      });

      test('deleteSyncMetadata removes metadata', () async {
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        await HiveStorageService.deleteSyncMetadata('sync1');
        expect(HiveStorageService.getSyncMetadata('sync1'), isNull);
      });

      test('clearSyncMetadata removes all metadata', () async {
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        await HiveStorageService.storeSyncMetadata('sync2', {'id': 'sync2'});
        await HiveStorageService.clearSyncMetadata();
        expect(HiveStorageService.getAllSyncMetadata(), isEmpty);
      });

      test('syncMetadataBox getter returns the box', () {
        expect(HiveStorageService.syncMetadataBox, isNotNull);
        expect(HiveStorageService.syncMetadataBox, isA<Box<String>>());
      });
    });

    group('photo storage operations', () {
      setUp(() async {
        await HiveStorageService.clearAllPhotos();
      });

      test('storePhoto stores bytes and returns hive URI', () async {
        final bytes = [1, 2, 3, 4, 5];
        final uri = await HiveStorageService.storePhoto('photo1', bytes);

        expect(uri, equals('hive://photo/photo1'));
      });

      test('getPhotoBytes retrieves stored photo bytes', () async {
        final bytes = [10, 20, 30, 40, 50];
        await HiveStorageService.storePhoto('photo2', bytes);

        final result = HiveStorageService.getPhotoBytes('photo2');
        expect(result, equals(bytes));
      });

      test('getPhotoBytes returns null for non-existent photo', () {
        final result = HiveStorageService.getPhotoBytes('non_existent');
        expect(result, isNull);
      });

      test('photoExists returns correct result', () async {
        expect(HiveStorageService.photoExists('photo3'), isFalse);
        await HiveStorageService.storePhoto('photo3', [1, 2, 3]);
        expect(HiveStorageService.photoExists('photo3'), isTrue);
      });

      test('deletePhoto removes a photo', () async {
        await HiveStorageService.storePhoto('photo4', [1, 2, 3]);
        expect(HiveStorageService.photoExists('photo4'), isTrue);
        await HiveStorageService.deletePhoto('photo4');
        expect(HiveStorageService.photoExists('photo4'), isFalse);
      });

      test('getAllPhotoIds returns all photo IDs', () async {
        await HiveStorageService.storePhoto('photo_a', [1]);
        await HiveStorageService.storePhoto('photo_b', [2]);
        await HiveStorageService.storePhoto('photo_c', [3]);

        final ids = HiveStorageService.getAllPhotoIds();
        expect(ids, containsAll(['photo_a', 'photo_b', 'photo_c']));
        expect(ids.length, equals(3));
      });

      test('clearAllPhotos removes all photos', () async {
        await HiveStorageService.storePhoto('photo_x', [1]);
        await HiveStorageService.storePhoto('photo_y', [2]);
        await HiveStorageService.clearAllPhotos();
        expect(HiveStorageService.getAllPhotoIds(), isEmpty);
      });

      test('getPhotoStorageSize returns approximate total size', () async {
        // Store some photos with known byte sizes
        final bytes1 = List<int>.generate(100, (i) => i % 256);
        final bytes2 = List<int>.generate(200, (i) => i % 256);

        await HiveStorageService.storePhoto('size_photo1', bytes1);
        await HiveStorageService.storePhoto('size_photo2', bytes2);

        final size = HiveStorageService.getPhotoStorageSize();
        // Base64 encoding increases size by ~33%, so stored size is larger
        // but getPhotoStorageSize estimates original binary size
        expect(size, greaterThan(0));
        expect(size, lessThan(500)); // Should be close to 300 (100 + 200)
      });

      test('storePhoto handles large binary data', () async {
        // Create a larger byte array (simulating a small image)
        final largeBytes = List<int>.generate(10000, (i) => i % 256);
        final uri = await HiveStorageService.storePhoto(
          'large_photo',
          largeBytes,
        );

        expect(uri, equals('hive://photo/large_photo'));

        final retrieved = HiveStorageService.getPhotoBytes('large_photo');
        expect(retrieved, equals(largeBytes));
      });

      test('photo data survives base64 encode/decode cycle', () async {
        // Test with various byte patterns including edge cases
        final testCases = [
          [0, 0, 0], // All zeros
          [255, 255, 255], // All max
          [0, 128, 255], // Mixed values
          List<int>.generate(256, (i) => i), // All byte values
        ];

        for (var i = 0; i < testCases.length; i++) {
          final bytes = testCases[i];
          await HiveStorageService.storePhoto('cycle_test_$i', bytes);
          final retrieved = HiveStorageService.getPhotoBytes('cycle_test_$i');
          expect(retrieved, equals(bytes), reason: 'Test case $i failed');
        }
      });
    });

    group('hive photo URI parsing', () {
      test('parseHivePhotoUri extracts photo ID correctly', () {
        expect(
          HiveStorageService.parseHivePhotoUri('hive://photo/abc123'),
          equals('abc123'),
        );
        expect(
          HiveStorageService.parseHivePhotoUri('hive://photo/my-photo-id'),
          equals('my-photo-id'),
        );
        expect(
          HiveStorageService.parseHivePhotoUri('hive://photo/'),
          equals(''),
        );
      });

      test('parseHivePhotoUri returns null for invalid URIs', () {
        expect(
          HiveStorageService.parseHivePhotoUri('http://example.com'),
          isNull,
        );
        expect(
          HiveStorageService.parseHivePhotoUri('/local/path/photo.jpg'),
          isNull,
        );
        expect(
          HiveStorageService.parseHivePhotoUri('blob:http://localhost/123'),
          isNull,
        );
        expect(
          HiveStorageService.parseHivePhotoUri('hive://other/abc'),
          isNull,
        );
      });

      test('isHivePhotoUri returns correct result', () {
        expect(HiveStorageService.isHivePhotoUri('hive://photo/abc'), isTrue);
        expect(HiveStorageService.isHivePhotoUri('hive://photo/'), isTrue);
        expect(
          HiveStorageService.isHivePhotoUri('http://example.com'),
          isFalse,
        );
        expect(HiveStorageService.isHivePhotoUri('/path/to/file'), isFalse);
        expect(HiveStorageService.isHivePhotoUri('blob:test'), isFalse);
      });

      test('hivePhotoScheme constant is correct', () {
        expect(HiveStorageService.hivePhotoScheme, equals('hive://photo/'));
      });
    });

    group('cache metadata operations', () {
      setUp(() async {
        final service = HiveStorageService();
        await service.clear();
      });

      test('setCacheTimestamp and getCacheTimestamp work correctly', () async {
        final timestamp = DateTime(2026, 1, 11, 10, 30, 0);
        await HiveStorageService.setCacheTimestamp('programs', timestamp);

        final result = HiveStorageService.getCacheTimestamp('programs');
        expect(result, equals(timestamp));
      });

      test('getCacheTimestamp returns null for non-existent cache type', () {
        final result = HiveStorageService.getCacheTimestamp('non_existent');
        expect(result, isNull);
      });

      test('clearCacheTimestamp removes timestamp', () async {
        final timestamp = DateTime.now();
        await HiveStorageService.setCacheTimestamp('exercises', timestamp);
        expect(HiveStorageService.getCacheTimestamp('exercises'), isNotNull);

        await HiveStorageService.clearCacheTimestamp('exercises');
        expect(HiveStorageService.getCacheTimestamp('exercises'), isNull);
      });

      test('different cache types are independent', () async {
        final time1 = DateTime(2026, 1, 1);
        final time2 = DateTime(2026, 2, 1);

        await HiveStorageService.setCacheTimestamp('type1', time1);
        await HiveStorageService.setCacheTimestamp('type2', time2);

        expect(HiveStorageService.getCacheTimestamp('type1'), equals(time1));
        expect(HiveStorageService.getCacheTimestamp('type2'), equals(time2));
      });
    });

    group('utility methods', () {
      setUp(() async {
        await HiveStorageService.clearAllData();
      });

      test('boxContainsKey checks programs box', () async {
        await HiveStorageService.storeProgram('prog1', {'id': 'prog1'});
        expect(
          HiveStorageService.boxContainsKey(
            HiveStorageService.programsBoxName,
            'prog1',
          ),
          isTrue,
        );
        expect(
          HiveStorageService.boxContainsKey(
            HiveStorageService.programsBoxName,
            'non_existent',
          ),
          isFalse,
        );
      });

      test(
        'boxContainsKey checks custom exercises box (case-insensitive)',
        () async {
          await HiveStorageService.storeCustomExercise('EX1', {'id': 'ex1'});
          expect(
            HiveStorageService.boxContainsKey(
              HiveStorageService.customExercisesBoxName,
              'ex1',
            ),
            isTrue,
          );
          expect(
            HiveStorageService.boxContainsKey(
              HiveStorageService.customExercisesBoxName,
              'EX1',
            ),
            isTrue,
          );
        },
      );

      test(
        'boxContainsKey checks user preferences box (case-insensitive)',
        () async {
          await HiveStorageService.storeUserPreference('PREF1', {
            'notes': 'test',
          });
          expect(
            HiveStorageService.boxContainsKey(
              HiveStorageService.userPreferencesBoxName,
              'pref1',
            ),
            isTrue,
          );
        },
      );

      test('boxContainsKey checks sync metadata box', () async {
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        expect(
          HiveStorageService.boxContainsKey(
            HiveStorageService.syncMetadataBoxName,
            'sync1',
          ),
          isTrue,
        );
      });

      test('boxContainsKey falls back to general box', () async {
        final service = HiveStorageService();
        await service.store('general_key', 'value');
        expect(
          HiveStorageService.boxContainsKey('unknown_box', 'general_key'),
          isTrue,
        );
      });

      test('boxLength returns correct count for programs box', () async {
        expect(
          HiveStorageService.boxLength(HiveStorageService.programsBoxName),
          equals(0),
        );

        await HiveStorageService.storeProgram('prog1', {'id': 'prog1'});
        await HiveStorageService.storeProgram('prog2', {'id': 'prog2'});

        expect(
          HiveStorageService.boxLength(HiveStorageService.programsBoxName),
          equals(2),
        );
      });

      test(
        'boxLength returns correct count for custom exercises box',
        () async {
          await HiveStorageService.storeCustomExercise('ex1', {'id': 'ex1'});
          expect(
            HiveStorageService.boxLength(
              HiveStorageService.customExercisesBoxName,
            ),
            equals(1),
          );
        },
      );

      test(
        'boxLength returns correct count for user preferences box',
        () async {
          await HiveStorageService.storeUserPreference('pref1', {
            'notes': 'test',
          });
          await HiveStorageService.storeUserPreference('pref2', {
            'notes': 'test2',
          });
          expect(
            HiveStorageService.boxLength(
              HiveStorageService.userPreferencesBoxName,
            ),
            equals(2),
          );
        },
      );

      test('boxLength returns correct count for sync metadata box', () async {
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        expect(
          HiveStorageService.boxLength(HiveStorageService.syncMetadataBoxName),
          equals(1),
        );
      });

      test('boxLength falls back to general box for unknown box name', () async {
        final service = HiveStorageService();
        await service.store('key1', 'value1');
        await service.store('key2', 'value2');
        // Note: general box may also contain cache timestamps, so we use greaterThanOrEqualTo
        expect(
          HiveStorageService.boxLength('unknown_box'),
          greaterThanOrEqualTo(2),
        );
      });

      test('clearAllData clears all boxes', () async {
        await HiveStorageService.storeProgram('prog1', {'id': 'prog1'});
        await HiveStorageService.storeCustomExercise('ex1', {'id': 'ex1'});
        await HiveStorageService.storeUserPreference('pref1', {
          'notes': 'test',
        });
        await HiveStorageService.storeSyncMetadata('sync1', {'id': 'sync1'});
        await HiveStorageService.storePhoto('photo1', [1, 2, 3]);

        await HiveStorageService.clearAllData();

        expect(HiveStorageService.getAllPrograms(), isEmpty);
        expect(HiveStorageService.getAllCustomExercises(), isEmpty);
        expect(HiveStorageService.getAllUserPreferences(), isEmpty);
        expect(HiveStorageService.getAllSyncMetadata(), isEmpty);
        expect(HiveStorageService.getAllPhotoIds(), isEmpty);
      });
    });

    group('error handling', () {
      test('getProgram handles corrupted JSON gracefully', () async {
        // Directly put corrupted data into the box
        HiveStorageService.programsBox.put('corrupted', 'not valid json {{{');
        final result = HiveStorageService.getProgram('corrupted');
        expect(result, isNull);
      });

      test('getCustomExercise handles corrupted JSON gracefully', () async {
        HiveStorageService.customExercisesBox.put('corrupted', 'invalid json');
        final result = HiveStorageService.getCustomExercise('corrupted');
        expect(result, isNull);
      });

      test('getUserPreference handles corrupted JSON gracefully', () async {
        HiveStorageService.userPreferencesBox.put('corrupted', '{{invalid}}');
        final result = HiveStorageService.getUserPreference('corrupted');
        expect(result, isNull);
      });

      test('getSyncMetadata handles corrupted JSON gracefully', () async {
        HiveStorageService.syncMetadataBox.put('corrupted', 'bad json');
        final result = HiveStorageService.getSyncMetadata('corrupted');
        expect(result, isNull);
      });

      test('getPhotoBytes handles corrupted base64 gracefully', () async {
        // Put invalid base64 data directly
        final box = await Hive.openBox<String>(
          HiveStorageService.photoStorageBoxName,
        );
        await box.put('corrupted_photo', 'not valid base64!!!');

        final result = HiveStorageService.getPhotoBytes('corrupted_photo');
        expect(result, isNull);
      });
    });
  });

  group('InMemoryStorageService', () {
    late InMemoryStorageService service;

    setUp(() async {
      service = InMemoryStorageService();
      await service.init();
      await service.clear();
    });

    test('init completes without error', () async {
      final newService = InMemoryStorageService();
      await expectLater(newService.init(), completes);
    });

    test('store and retrieve work correctly', () async {
      await service.store('key', 'value');
      final result = await service.retrieve<String>('key');
      expect(result, equals('value'));
    });

    test('retrieve returns null for non-existent key', () async {
      final result = await service.retrieve<String>('non_existent');
      expect(result, isNull);
    });

    test('remove deletes a key', () async {
      await service.store('key', 'value');
      await service.remove('key');
      expect(await service.containsKey('key'), isFalse);
    });

    test('containsKey returns correct result', () async {
      expect(await service.containsKey('new_key'), isFalse);
      await service.store('new_key', 'value');
      expect(await service.containsKey('new_key'), isTrue);
    });

    test('getAllKeys returns all stored keys', () async {
      await service.store('key1', 'value1');
      await service.store('key2', 'value2');
      final keys = await service.getAllKeys();
      expect(keys, containsAll(['key1', 'key2']));
    });

    test('clear removes all data', () async {
      await service.store('key1', 'value1');
      await service.store('key2', 'value2');
      await service.clear();
      expect(await service.getAllKeys(), isEmpty);
    });

    test('handles various data types', () async {
      await service.store('string', 'test');
      await service.store('int', 42);
      await service.store('double', 3.14);
      await service.store('bool', true);
      await service.store('list', [1, 2, 3]);
      await service.store('map', {'key': 'value'});

      expect(await service.retrieve<String>('string'), equals('test'));
      expect(await service.retrieve<int>('int'), equals(42));
      expect(await service.retrieve<double>('double'), equals(3.14));
      expect(await service.retrieve<bool>('bool'), isTrue);
      expect(await service.retrieve<List>('list'), equals([1, 2, 3]));
      expect(await service.retrieve<Map>('map'), equals({'key': 'value'}));
    });
  });
}
