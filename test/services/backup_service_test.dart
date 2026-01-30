import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';

import 'package:flutter_lifter/services/storage_service.dart';
import 'package:flutter_lifter/services/backup_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_backup_test_');
    Hive.init(tempDir.path);
    await HiveStorageService.initializeBoxes();

    // Initialize mock shared preferences and logging so tests can call logging safely
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettingsService();
    await settings.init();
    await LoggingService.init(settings);
  });

  tearDownAll(() async {
    try {
      await HiveStorageService.closeBoxes();
    } catch (_) {}
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await HiveStorageService.clearAllData();
  });

  test('export/import round trip preserves boxes and photos', () async {
    // prepare data
    await HiveStorageService.storeProgram('p1', {
      'name': 'prog1',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await HiveStorageService.storeCustomExercise('e1', {'title': 'ex1'});
    final photoBytes = utf8.encode('fake-photo-bytes');
    await HiveStorageService.storePhoto('photo1', photoBytes);

    final zipBytes = await BackupService.exportBackup();
    expect(zipBytes, isNotNull);

    // clear and import
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zipBytes);
    expect(res['errors'], isEmpty);

    final prog = HiveStorageService.getProgram('p1');
    expect(prog, isNotNull);
    expect(prog!['name'], 'prog1');

    final photoRestored = HiveStorageService.getPhotoBytes('photo1');
    expect(photoRestored, isNotNull);
    expect(utf8.decode(photoRestored!), 'fake-photo-bytes');
  });

  test('corrupted string entries are preserved as strings', () async {
    // Put a non-JSON string into programs box directly
    await HiveStorageService.putBoxValue(
      HiveStorageService.programsBoxName,
      'bad',
      'not-a-json',
    );
    final zipBytes = await BackupService.exportBackup();

    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zipBytes);
    expect(res['errors'], isEmpty);

    // After import, the bad key should exist and be retrievable as a string when reading raw box
    final raw = HiveStorageService.programsBox.get('bad');
    expect(raw, 'not-a-json');
  });

  test('import skips older incoming entries when existing is newer', () async {
    // Create backup with an older timestamp
    final older = DateTime.now().toIso8601String();
    await HiveStorageService.storeProgram('conflict', {
      'name': 'old',
      'updatedAt': older,
    });
    final zipBytes = await BackupService.exportBackup();

    // Clear and create an existing newer entry
    await HiveStorageService.clearAllData();
    final newer = DateTime.now().add(Duration(days: 1)).toIso8601String();
    await HiveStorageService.storeProgram('conflict', {
      'name': 'new',
      'updatedAt': newer,
    });

    final res = await BackupService.importBackup(zipBytes);
    // Since existing is newer, import should skip writing that key
    expect(res['skipped'] >= 1, isTrue);

    final current = HiveStorageService.getProgram('conflict');
    expect(current!['name'], 'new');
  });

  test('import reports invalid zip', () async {
    final res = await BackupService.importBackup(
      Uint8List.fromList([0, 1, 2, 3]),
    );
    expect(res['error'], 'invalid_zip');
  });

  test('programs box: export/import all fields', () async {
    final now = DateTime.now().toIso8601String();
    final program = {
      'id': 'prog_box',
      'name': 'All Fields Program',
      'description': 'Detailed program',
      'createdAt': now,
      'updatedAt': now,
      'tags': ['a', 'b'],
      'exercises': [
        {
          'id': 'ex1',
          'sets': 3,
          'reps': [8, 8, 6],
          'restSec': 90,
        },
      ],
      'metadata': {'notes': 'meta', 'level': 2},
    };
    await HiveStorageService.storeProgram('prog_box', program);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getProgram('prog_box');
    expect(restored, isNotNull);
    expect(restored, equals(program));
  });

  test('custom_exercises box: export/import all fields', () async {
    final ex = {
      'id': 'cust_box',
      'title': 'Fancy Curl',
      'muscles': ['biceps'],
      'equipment': ['dumbbell'],
      'description': 'Curl with pause',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await HiveStorageService.storeCustomExercise('cust_box', ex);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getCustomExercise('cust_box');
    expect(restored, isNotNull);
    expect(restored, equals(ex));
  });

  test('user_preferences box: export/import all fields', () async {
    final pref = {
      'weight': 55.0,
      'units': 'kg',
      'notes': 'pref notes',
      'lastUsed': DateTime.now().toIso8601String(),
      'settings': {'tempo': '2-0-1'},
    };
    await HiveStorageService.storeUserPreference('exercise_pref_full', pref);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getUserPreference('exercise_pref_full');
    expect(restored, isNotNull);
    expect(restored, equals(pref));
  });

  test('exercise_history box: export/import all fields', () async {
    final hist = {
      'date': DateTime.now().toIso8601String(),
      'exerciseId': 'ex_hist',
      'sets': [
        {'reps': 10, 'weight': 40},
        {'reps': 8, 'weight': 45},
      ],
      'notes': 'felt good',
    };
    await HiveStorageService.putBoxValue(
      HiveStorageService.exerciseHistoryBoxName,
      'hist_box',
      hist,
    );

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restoredRaw = Hive.box<String>(
      HiveStorageService.exerciseHistoryBoxName,
    ).get('hist_box');
    expect(restoredRaw, isNotNull);
    final restored = jsonDecode(restoredRaw!) as Map<String, dynamic>;
    expect(restored, equals(hist));
  });

  test('sync_metadata box: export/import all fields', () async {
    final meta = {
      'id': 'sync_box',
      'version': 7,
      'lastSynced': DateTime.now().toIso8601String(),
      'state': 'dirty',
    };
    await HiveStorageService.storeSyncMetadata('sync_box', meta);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getSyncMetadata('sync_box');
    expect(restored, isNotNull);
    expect(restored, equals(meta));
  });

  test('general_storage box: export/import various types', () async {
    await HiveStorageService.putBoxValue(
      HiveStorageService.generalBoxName,
      'gs_str',
      's',
    );
    await HiveStorageService.putBoxValue(
      HiveStorageService.generalBoxName,
      'gs_int',
      5,
    );
    await HiveStorageService.putBoxValue(
      HiveStorageService.generalBoxName,
      'gs_bool',
      false,
    );
    await HiveStorageService.putBoxValue(
      HiveStorageService.generalBoxName,
      'gs_list',
      ['a', 'b'],
    );

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final s = Hive.box<dynamic>(
      HiveStorageService.generalBoxName,
    ).get('gs_str');
    final i = Hive.box<dynamic>(
      HiveStorageService.generalBoxName,
    ).get('gs_int');
    final b = Hive.box<dynamic>(
      HiveStorageService.generalBoxName,
    ).get('gs_bool');
    final l = Hive.box<dynamic>(
      HiveStorageService.generalBoxName,
    ).get('gs_list');
    expect(s, 's');
    expect(i, 5);
    expect(b, false);
    expect(l, equals(['a', 'b']));
  });

  test('photo_storage box: export/import bytes', () async {
    final bytes = utf8.encode('photo_test_bytes');
    await HiveStorageService.storePhoto('photo_box', bytes);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getPhotoBytes('photo_box');
    expect(restored, isNotNull);
    expect(utf8.decode(restored!), 'photo_test_bytes');
  });

  test('workout_sessions box: export/import all fields', () async {
    final ws = {
      'date': DateTime.now().toIso8601String(),
      'duration': 1800,
      'calories': 300,
      'exercises': [
        {
          'id': 'e1',
          'sets': [10, 8],
        },
      ],
    };
    await HiveStorageService.storeWorkoutSession('ws_box', ws);

    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);

    final restored = HiveStorageService.getWorkoutSession('ws_box');
    expect(restored, isNotNull);
    expect(restored!['duration'], 1800);
  });

  test(
    'edge case: corrupted box file inside zip should report error and continue',
    () async {
      await HiveStorageService.storeProgram('edge1', {'name': 'e1'});
      await HiveStorageService.storeCustomExercise('edge_ex', {'title': 'te'});

      final zipBytes = await BackupService.exportBackup();

      // Corrupt the programs box file inside the zip
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final out = Archive();
      for (final file in archive) {
        if (file.isFile &&
            file.name == 'box_${HiveStorageService.programsBoxName}.json') {
          final bad = utf8.encode('this is not valid json');
          out.addFile(ArchiveFile(file.name, bad.length, bad));
        } else if (file.isFile) {
          out.addFile(
            ArchiveFile(
              file.name,
              (file.content as List<int>).length,
              file.content as List<int>,
            ),
          );
        }
      }
      final corrupted = Uint8List.fromList(ZipEncoder().encode(out)!);

      await HiveStorageService.clearAllData();
      final res = await BackupService.importBackup(corrupted);
      expect(res['errors'], isNotEmpty);
      // custom_exercises should still be restored
      final cust = HiveStorageService.getCustomExercise('edge_ex');
      expect(cust, isNotNull);
    },
  );

  test(
    'edge case: import overwrites when timestamps missing (import as source-of-truth)',
    () async {
      // Create a backup where item has no timestamp
      await HiveStorageService.storeProgram('no_ts', {'name': 'from_backup'});
      final zip = await BackupService.exportBackup();

      // Clear and create a conflicting existing value
      await HiveStorageService.clearAllData();
      await HiveStorageService.storeProgram('no_ts', {'name': 'existing'});

      final res = await BackupService.importBackup(zip);
      expect(res['errors'], isEmpty);
      final current = HiveStorageService.getProgram('no_ts');
      // import should overwrite when timestamps absent
      expect(current!['name'], 'from_backup');
    },
  );

  test('edge case: large photo export/import', () async {
    // create ~1MB photo
    final large = List<int>.generate(1024 * 1024, (i) => i % 256);
    await HiveStorageService.storePhoto('large_photo', large);
    final zip = await BackupService.exportBackup();
    await HiveStorageService.clearAllData();
    final res = await BackupService.importBackup(zip);
    expect(res['errors'], isEmpty);
    final restored = HiveStorageService.getPhotoBytes('large_photo');
    expect(restored, isNotNull);
    expect(restored!.length, large.length);
  });

  test('edge case: unknown box file in zip is ignored', () async {
    // create a zip with an unknown box file
    final archive = Archive();
    archive.addFile(
      ArchiveFile('box_unknown.json', 10, utf8.encode('{"k":1}')),
    );
    final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);

    final res = await BackupService.importBackup(zip);
    // should not throw; errors may be empty
    expect(res, isA<Map<String, dynamic>>());
  });
}
