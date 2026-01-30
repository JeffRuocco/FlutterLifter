import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'storage_service.dart';
import 'logging_service.dart';

/// Simple backup/restore service that exports all Hive boxes into a ZIP archive
/// and can import the archive back into Hive.
enum ConflictPolicy { overwrite, merge, skip }

class BackupService {
  /// Export all known boxes and photos into a ZIP encoded as bytes.
  /// Returns ZIP file bytes.
  static Future<Uint8List> exportBackup({bool includePhotos = true}) async {
    // Ensure boxes initialized
    await HiveStorageService.initializeBoxes();

    final archive = Archive();

    final manifest = <String, dynamic>{
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 1,
      'boxes': {},
    };

    final boxes = <String>[
      HiveStorageService.programsBoxName,
      HiveStorageService.customExercisesBoxName,
      HiveStorageService.userPreferencesBoxName,
      HiveStorageService.exerciseHistoryBoxName,
      HiveStorageService.syncMetadataBoxName,
      HiveStorageService.generalBoxName,
      HiveStorageService.photoStorageBoxName,
      HiveStorageService.workoutSessionsBoxName,
    ];

    for (final boxName in boxes) {
      try {
        final data = HiveStorageService.exportBox(boxName);
        manifest['boxes'][boxName] = {'itemCount': data.length};
        final content = utf8.encode(jsonEncode(data));
        archive.addFile(
          ArchiveFile('box_$boxName.json', content.length, content),
        );
      } catch (e, st) {
        LoggingService.logDataError(
          'backup',
          'export_box:$boxName',
          e,
          stackTrace: st,
        );
      }
    }

    if (includePhotos) {
      try {
        final photos = HiveStorageService.getAllPhotoIds();
        manifest['photoHandling'] = 'hive';
        manifest['photos'] = {'count': photos.length};
        for (final id in photos) {
          final bytes = HiveStorageService.getPhotoBytes(id);
          if (bytes != null) {
            archive.addFile(ArchiveFile('photos/$id.bin', bytes.length, bytes));
          }
        }
      } catch (e, st) {
        LoggingService.logDataError(
          'backup',
          'export_photos',
          e,
          stackTrace: st,
        );
      }
    }

    // Add manifest
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    final zipData = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(zipData);
  }

  /// Import a ZIP backup. Applies conflict resolution according to [policy].
  /// Returns a summary map with counts and errors (if any).
  static Future<Map<String, dynamic>> importBackup(
    Uint8List zipBytes, {
    ConflictPolicy policy = ConflictPolicy.overwrite,
  }) async {
    await HiveStorageService.initializeBoxes();

    final result = <String, dynamic>{'written': 0, 'skipped': 0, 'errors': []};

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      return {'error': 'invalid_zip', 'details': e.toString()};
    }

    // manifest (if present) is available in the archive as 'manifest.json'

    // Import boxes
    for (final file in archive) {
      if (!file.isFile) continue;
      if (file.name == 'manifest.json') continue;
      if (file.name.startsWith('box_') && file.name.endsWith('.json')) {
        final boxName = file.name.substring(4, file.name.length - 5);
        try {
          final content = utf8.decode(file.content as List<int>);
          final Map<String, dynamic> data =
              jsonDecode(content) as Map<String, dynamic>;
          for (final entryKey in data.keys) {
            final incoming = data[entryKey];
            try {
              // Conflict handling: compare timestamps if both sides are maps
              final existing = HiveStorageService.exportBox(boxName)[entryKey];
              var shouldWrite = true;
              if (existing != null && existing is Map && incoming is Map) {
                final existingTs = _extractTimestamp(existing);
                final incomingTs = _extractTimestamp(incoming);
                if (existingTs != null && incomingTs != null) {
                  shouldWrite = incomingTs.isAfter(existingTs);
                } else {
                  // fallback: import is source of truth -> overwrite
                  shouldWrite = true;
                }
              }

              if (shouldWrite) {
                await HiveStorageService.putBoxValue(
                  boxName,
                  entryKey,
                  incoming,
                );
                result['written'] = result['written'] + 1;
              } else {
                result['skipped'] = result['skipped'] + 1;
              }
            } catch (e, st) {
              result['errors'].add({
                'box': boxName,
                'key': entryKey,
                'error': e.toString(),
              });
              LoggingService.logDataError(
                'restore',
                'box:$boxName key:$entryKey',
                e,
                stackTrace: st,
              );
            }
          }
        } catch (e, st) {
          LoggingService.logDataError(
            'restore',
            'boxfile:${file.name}',
            e,
            stackTrace: st,
          );
          result['errors'].add({'file': file.name, 'error': e.toString()});
        }
      }
    }

    // Import photos: look for photos/ folder
    for (final file in archive) {
      if (!file.isFile) continue;
      if (file.name.startsWith('photos/')) {
        final photoId = file.name.substring('photos/'.length);
        try {
          final bytes = file.content as List<int>;
          // store as binary bytes in hive photo storage as base64 string
          await HiveStorageService.putBoxValue(
            HiveStorageService.photoStorageBoxName,
            photoId,
            base64Encode(bytes),
          );
          result['written'] = result['written'] + 1;
        } catch (e, st) {
          result['errors'].add({'photo': photoId, 'error': e.toString()});
          LoggingService.logDataError(
            'restore',
            'photo:$photoId',
            e,
            stackTrace: st,
          );
        }
      }
    }

    return result;
  }

  static DateTime? _extractTimestamp(Map data) {
    final candidates = [
      'updatedAt',
      'modifiedAt',
      'updated_at',
      'modified_at',
      'createdAt',
      'created_at',
    ];
    for (final c in candidates) {
      if (data.containsKey(c)) {
        try {
          final v = data[c];
          if (v is String) return DateTime.tryParse(v);
          if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        } catch (_) {}
      }
    }
    return null;
  }
}
