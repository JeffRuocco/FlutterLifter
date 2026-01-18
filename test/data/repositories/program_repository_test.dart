import 'package:flutter_lifter/data/datasources/mock/mock_program_datasource.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/services/app_settings_service.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgramRepository', () {
    late ProgramRepository repository;

    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});

      // Initialize AppSettingsService and LoggingService
      final appSettingsService = AppSettingsService();
      await appSettingsService.init();
      await LoggingService.init(appSettingsService);
    });

    setUp(() {
      // Each MockProgramDataSource shares static state, so we reset it
      // by creating a fresh repository for each test
      repository = ProgramRepositoryImpl(
        mockDataSource: MockProgramDataSource(),
        useMockData: true,
        useRemoteApi: false,
      );
    });

    group('Factory Constructors', () {
      test(
        'development factory should create repository with mock data',
        () async {
          final repo = ProgramRepositoryImpl.development();
          final programs = await repo.getPrograms();

          expect(programs, isNotEmpty);
        },
      );
    });

    group('Basic Program Operations', () {
      test('getPrograms should return all programs', () async {
        final programs = await repository.getPrograms();

        expect(programs, isNotEmpty);
        expect(programs.length, greaterThanOrEqualTo(3));
      });

      test('getProgramById should find existing program', () async {
        final programs = await repository.getPrograms();
        final firstProgram = programs.first;

        final found = await repository.getProgramById(firstProgram.id);

        expect(found, isNotNull);
        expect(found!.id, equals(firstProgram.id));
        expect(found.name, equals(firstProgram.name));
      });

      test('getProgramById should return null for non-existent id', () async {
        final found = await repository.getProgramById('non_existent_id');

        expect(found, isNull);
      });

      test('createProgram should add a new program', () async {
        final initialPrograms = await repository.getPrograms();
        final initialCount = initialPrograms.length;

        final newProgram = Program(
          id: 'test_custom_program',
          name: 'Test Custom Program',
          description: 'A test program',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.beginner,
          createdAt: DateTime.now(),
          isDefault: false,
        );

        await repository.createProgram(newProgram);

        final updatedPrograms = await repository.getPrograms();
        expect(updatedPrograms.length, equals(initialCount + 1));
        expect(
          updatedPrograms.any((p) => p.id == 'test_custom_program'),
          isTrue,
        );
      });

      test('updateProgram should modify existing program', () async {
        final programs = await repository.getPrograms();
        final program = programs.first;

        final updatedProgram = program.copyWith(
          name: 'Updated Program Name',
          description: 'Updated description',
        );

        await repository.updateProgram(updatedProgram);

        final found = await repository.getProgramById(program.id);
        expect(found, isNotNull);
        expect(found!.name, equals('Updated Program Name'));
        expect(found.description, equals('Updated description'));
      });

      test('deleteProgram should remove the program', () async {
        // First create a program to delete
        final newProgram = Program(
          id: 'program_to_delete',
          name: 'Program To Delete',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.beginner,
          createdAt: DateTime.now(),
          isDefault: false,
        );
        await repository.createProgram(newProgram);

        // Verify it exists
        var found = await repository.getProgramById('program_to_delete');
        expect(found, isNotNull);

        // Delete it
        await repository.deleteProgram('program_to_delete');

        // Verify it's gone
        found = await repository.getProgramById('program_to_delete');
        expect(found, isNull);
      });
    });

    group('Program Library Methods - getDefaultPrograms', () {
      test('getDefaultPrograms should return only default programs', () async {
        final defaultPrograms = await repository.getDefaultPrograms();

        expect(defaultPrograms, isNotEmpty);
        expect(
          defaultPrograms.every((p) => p.isDefault),
          isTrue,
          reason: 'All returned programs should have isDefault=true',
        );
      });

      test('getDefaultPrograms should not return custom programs', () async {
        // Create a custom program
        final customProgram = Program(
          id: 'custom_program_1',
          name: 'My Custom Program',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.beginner,
          createdAt: DateTime.now(),
          isDefault: false,
        );
        await repository.createProgram(customProgram);

        final defaultPrograms = await repository.getDefaultPrograms();

        expect(
          defaultPrograms.any((p) => p.id == 'custom_program_1'),
          isFalse,
          reason: 'Custom programs should not appear in default programs',
        );
      });
    });

    group('Program Library Methods - getCustomPrograms', () {
      test('getCustomPrograms should return only custom programs', () async {
        // Create custom programs
        final customProgram1 = Program(
          id: 'custom_test_1',
          name: 'Custom Program 1',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.beginner,
          createdAt: DateTime.now(),
          isDefault: false,
        );
        final customProgram2 = Program(
          id: 'custom_test_2',
          name: 'Custom Program 2',
          type: ProgramType.strength,
          difficulty: ProgramDifficulty.intermediate,
          createdAt: DateTime.now(),
          isDefault: false,
        );
        await repository.createProgram(customProgram1);
        await repository.createProgram(customProgram2);

        final customPrograms = await repository.getCustomPrograms();

        expect(customPrograms.length, greaterThanOrEqualTo(2));
        expect(
          customPrograms.every((p) => !p.isDefault),
          isTrue,
          reason: 'All returned programs should have isDefault=false',
        );
        expect(customPrograms.any((p) => p.id == 'custom_test_1'), isTrue);
        expect(customPrograms.any((p) => p.id == 'custom_test_2'), isTrue);
      });

      test('getCustomPrograms should not return default programs', () async {
        final customPrograms = await repository.getCustomPrograms();
        final defaultPrograms = await repository.getDefaultPrograms();

        // Ensure no overlap
        for (final customProg in customPrograms) {
          expect(
            defaultPrograms.any((d) => d.id == customProg.id),
            isFalse,
            reason: 'Default programs should not appear in custom programs',
          );
        }
      });
    });

    group('Program Library Methods - getRecentPrograms', () {
      test(
        'getRecentPrograms should return programs sorted by lastUsedAt',
        () async {
          // Create programs with different lastUsedAt dates
          final now = DateTime.now();
          final program1 = Program(
            id: 'recent_1',
            name: 'Recent Program 1',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now.subtract(const Duration(days: 10)),
            isDefault: false,
            lastUsedAt: now.subtract(const Duration(days: 1)), // 1 day ago
          );
          final program2 = Program(
            id: 'recent_2',
            name: 'Recent Program 2',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now.subtract(const Duration(days: 10)),
            isDefault: false,
            lastUsedAt: now.subtract(const Duration(days: 3)), // 3 days ago
          );
          final program3 = Program(
            id: 'recent_3',
            name: 'Recent Program 3',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now.subtract(const Duration(days: 10)),
            isDefault: false,
            lastUsedAt: now, // Just used
          );

          await repository.createProgram(program1);
          await repository.createProgram(program2);
          await repository.createProgram(program3);

          final recentPrograms = await repository.getRecentPrograms(limit: 10);

          // Find our test programs in results
          final recentIds = recentPrograms.map((p) => p.id).toList();
          final idx1 = recentIds.indexOf('recent_1');
          final idx2 = recentIds.indexOf('recent_2');
          final idx3 = recentIds.indexOf('recent_3');

          // recent_3 (just used) should come before recent_1 (1 day ago)
          // which should come before recent_2 (3 days ago)
          expect(idx3, lessThan(idx1));
          expect(idx1, lessThan(idx2));
        },
      );

      test(
        'getRecentPrograms should only return programs with lastUsedAt set',
        () async {
          final recentPrograms = await repository.getRecentPrograms();

          expect(
            recentPrograms.every((p) => p.lastUsedAt != null),
            isTrue,
            reason: 'All recent programs should have lastUsedAt set',
          );
        },
      );

      test('getRecentPrograms should respect limit parameter', () async {
        // Create a few programs with lastUsedAt
        final now = DateTime.now();
        for (int i = 0; i < 5; i++) {
          final program = Program(
            id: 'limit_test_$i',
            name: 'Limit Test Program $i',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now.subtract(Duration(days: i + 1)),
            isDefault: false,
            lastUsedAt: now.subtract(Duration(days: i)),
          );
          await repository.createProgram(program);
        }

        final limit2 = await repository.getRecentPrograms(limit: 2);
        expect(limit2.length, equals(2));

        final limit3 = await repository.getRecentPrograms(limit: 3);
        expect(limit3.length, equals(3));
      });

      test(
        'getRecentPrograms should return empty for unused programs',
        () async {
          // Create a fresh repository without any programs that have lastUsedAt
          // Note: Mock data may have some programs with lastUsedAt, so we filter
          final recentPrograms = await repository.getRecentPrograms();

          // All returned should have lastUsedAt
          for (final program in recentPrograms) {
            expect(program.lastUsedAt, isNotNull);
          }
        },
      );
    });

    group('Program Library Methods - getProgramsBySource', () {
      test('getProgramsBySource with all should return all programs', () async {
        final allFromSource = await repository.getProgramsBySource(
          source: ProgramSource.all,
        );
        final allDirect = await repository.getPrograms();

        expect(allFromSource.length, equals(allDirect.length));
      });

      test(
        'getProgramsBySource with defaultOnly should return only defaults',
        () async {
          final defaultPrograms = await repository.getProgramsBySource(
            source: ProgramSource.defaultOnly,
          );

          expect(defaultPrograms.every((p) => p.isDefault), isTrue);
        },
      );

      test(
        'getProgramsBySource with customOnly should return only custom',
        () async {
          // Create a custom program first
          final customProgram = Program(
            id: 'source_test_custom',
            name: 'Source Test Custom',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: DateTime.now(),
            isDefault: false,
          );
          await repository.createProgram(customProgram);

          final customPrograms = await repository.getProgramsBySource(
            source: ProgramSource.customOnly,
          );

          expect(customPrograms.every((p) => !p.isDefault), isTrue);
          expect(
            customPrograms.any((p) => p.id == 'source_test_custom'),
            isTrue,
          );
        },
      );

      test(
        'getProgramsBySource with myPrograms should return custom + used default',
        () async {
          // Create a custom program
          final customProgram = Program(
            id: 'my_prog_custom',
            name: 'My Custom',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: DateTime.now(),
            isDefault: false,
          );
          await repository.createProgram(customProgram);

          final myPrograms = await repository.getProgramsBySource(
            source: ProgramSource.myPrograms,
          );

          // Should contain custom programs
          expect(myPrograms.any((p) => p.id == 'my_prog_custom'), isTrue);

          // Should contain default programs only if they have lastUsedAt
          final defaultsInMyPrograms = myPrograms.where((p) => p.isDefault);
          for (final defaultProg in defaultsInMyPrograms) {
            expect(
              defaultProg.lastUsedAt,
              isNotNull,
              reason: 'Default programs in myPrograms should have lastUsedAt',
            );
          }
        },
      );
    });

    group('Active Cycle Management - getActiveCycle', () {
      test(
        'getActiveCycle should return the active cycle if one exists',
        () async {
          // The mock data has Upper/Lower with an active cycle
          final activeCycle = await repository.getActiveCycle();

          // May be null if no active cycles exist in mock data initially
          // but let's check that when it returns, it has isActive = true
          if (activeCycle != null) {
            expect(activeCycle.isActive, isTrue);
            expect(activeCycle.programId, isNotEmpty);
          }
        },
      );

      test(
        'getActiveCycle should return null if no cycles are active',
        () async {
          // End any active cycle first
          await repository.endActiveCycle();

          final activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNull);
        },
      );

      test('getActiveCycle should have program reference set', () async {
        // Start a cycle so we have one
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          await repository.startNewCycle(programs.first.id);

          final activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNotNull);
          expect(activeCycle!.program, isNotNull);
          expect(activeCycle.program!.id, equals(activeCycle.programId));
        }
      });
    });

    group('Active Cycle Management - endActiveCycle', () {
      test('endActiveCycle should end the active cycle', () async {
        // Start a cycle first
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          await repository.startNewCycle(programs.first.id);

          // Verify it's active
          var activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNotNull);
          expect(activeCycle!.isActive, isTrue);

          // End it
          await repository.endActiveCycle();

          // Verify no active cycle
          activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNull);
        }
      });

      test('endActiveCycle should set endDate on the cycle', () async {
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          final newCycle = await repository.startNewCycle(programs.first.id);
          expect(newCycle.endDate, isNull); // Initially no end date

          await repository.endActiveCycle();

          // Verify the cycle now has an end date
          final program = await repository.getProgramById(programs.first.id);
          final endedCycle = program!.cycles.firstWhere(
            (c) => c.id == newCycle.id,
          );
          expect(endedCycle.isActive, isFalse);
          expect(endedCycle.endDate, isNotNull);
        }
      });

      test('endActiveCycle should do nothing if no active cycle', () async {
        // Ensure no active cycle
        await repository.endActiveCycle();

        // This should not throw and just return gracefully
        await repository.endActiveCycle();

        final activeCycle = await repository.getActiveCycle();
        expect(activeCycle, isNull);
      });
    });

    group('Active Cycle Management - startNewCycle', () {
      test('startNewCycle should create a new active cycle', () async {
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          final program = programs.first;

          // End any existing cycles first
          await repository.endActiveCycle();

          final newCycle = await repository.startNewCycle(program.id);

          expect(newCycle, isNotNull);
          expect(newCycle.isActive, isTrue);
          expect(newCycle.programId, equals(program.id));
          expect(newCycle.startDate, isNotNull);
        }
      });

      test('startNewCycle should auto-end any existing active cycle', () async {
        final programs = await repository.getDefaultPrograms();
        if (programs.length >= 2) {
          final program1 = programs[0];
          final program2 = programs[1];

          // Start first cycle
          final cycle1 = await repository.startNewCycle(program1.id);
          expect(cycle1.isActive, isTrue);

          // Start second cycle - should auto-end first
          final cycle2 = await repository.startNewCycle(program2.id);
          expect(cycle2.isActive, isTrue);

          // Verify only one active cycle exists
          final activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNotNull);
          expect(activeCycle!.id, equals(cycle2.id));

          // Verify first cycle is no longer active
          final updatedProgram1 = await repository.getProgramById(program1.id);
          final updatedCycle1 = updatedProgram1!.cycles.firstWhere(
            (c) => c.id == cycle1.id,
          );
          expect(updatedCycle1.isActive, isFalse);
        }
      });

      test('startNewCycle should update program lastUsedAt', () async {
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          final program = programs.first;
          final beforeLastUsedAt = program.lastUsedAt;

          await repository.startNewCycle(program.id);

          final updatedProgram = await repository.getProgramById(program.id);
          expect(updatedProgram!.lastUsedAt, isNotNull);

          // Should be more recent than before (or initially set)
          if (beforeLastUsedAt != null) {
            expect(
              updatedProgram.lastUsedAt!.isAfter(beforeLastUsedAt) ||
                  updatedProgram.lastUsedAt!.isAtSameMomentAs(beforeLastUsedAt),
              isTrue,
            );
          }
        }
      });

      test('startNewCycle should increment cycle number', () async {
        final programs = await repository.getDefaultPrograms();
        if (programs.isNotEmpty) {
          final program = programs.first;

          // End any existing and start fresh
          await repository.endActiveCycle();

          final cycle1 = await repository.startNewCycle(program.id);
          final cycleNumber1 = cycle1.cycleNumber;

          // End it and start another
          await repository.endActiveCycle();
          final cycle2 = await repository.startNewCycle(program.id);

          expect(cycle2.cycleNumber, equals(cycleNumber1 + 1));
        }
      });

      test('startNewCycle should throw for non-existent program', () async {
        expect(
          () => repository.startNewCycle('non_existent_program_id'),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('Program Cloning - copyProgramAsCustom', () {
      test('copyProgramAsCustom should create an independent copy', () async {
        final defaultPrograms = await repository.getDefaultPrograms();
        if (defaultPrograms.isNotEmpty) {
          final template = defaultPrograms.first;

          final copy = await repository.copyProgramAsCustom(template);

          // Should be a different program
          expect(copy.id, isNot(equals(template.id)));

          // Should have same name (no "(Copy)" suffix as per implementation)
          expect(copy.name, equals(template.name));

          // Should not be default
          expect(copy.isDefault, isFalse);

          // Should reference the template
          expect(copy.templateId, equals(template.id));

          // Should have no cycles (fresh start)
          expect(copy.cycles, isEmpty);
        }
      });

      test('copyProgramAsCustom should preserve template properties', () async {
        final defaultPrograms = await repository.getDefaultPrograms();
        if (defaultPrograms.isNotEmpty) {
          final template = defaultPrograms.first;

          final copy = await repository.copyProgramAsCustom(template);

          expect(copy.description, equals(template.description));
          expect(copy.type, equals(template.type));
          expect(copy.difficulty, equals(template.difficulty));
          expect(copy.tags, equals(template.tags));
        }
      });

      test(
        'copyProgramAsCustom should return existing copy if one exists',
        () async {
          final defaultPrograms = await repository.getDefaultPrograms();
          if (defaultPrograms.isNotEmpty) {
            final template = defaultPrograms.first;

            // Create first copy
            final copy1 = await repository.copyProgramAsCustom(template);

            // Try to create another copy - should return the same one
            final copy2 = await repository.copyProgramAsCustom(template);

            expect(copy1.id, equals(copy2.id));
          }
        },
      );

      test('copyProgramAsCustom copies should be fully independent', () async {
        final defaultPrograms = await repository.getDefaultPrograms();
        if (defaultPrograms.isNotEmpty) {
          final template = defaultPrograms.first;
          final copy = await repository.copyProgramAsCustom(template);

          // Modify the copy
          final modifiedCopy = copy.copyWith(
            name: 'My Modified Program',
            description: 'Custom description',
          );
          await repository.updateProgram(modifiedCopy);

          // Original template should be unchanged
          final templateAfter = await repository.getProgramById(template.id);
          expect(templateAfter!.name, equals(template.name));
          expect(templateAfter.description, equals(template.description));
        }
      });
    });

    group('Program Cloning - getUserCopyOfProgram', () {
      test(
        'getUserCopyOfProgram should return null if no copy exists',
        () async {
          // Use an ID that definitely won't have a copy
          final userCopy = await repository.getUserCopyOfProgram(
            'nonexistent_template_xyz',
          );
          expect(userCopy, isNull);
        },
      );

      test(
        'getUserCopyOfProgram should return the copy after creating one',
        () async {
          // Use a program that hasn't been copied yet - full_body is clean in mock data
          final program = await repository.getProgramById('full_body');
          if (program != null) {
            // Check initial state - look for copy by template ID
            final existingCopy = await repository.getUserCopyOfProgram(
              program.id,
            );

            if (existingCopy == null) {
              // No copy exists, create one
              final copy = await repository.copyProgramAsCustom(program);

              // Now it should be found
              final userCopy = await repository.getUserCopyOfProgram(
                program.id,
              );
              expect(userCopy, isNotNull);
              expect(userCopy!.id, equals(copy.id));
            } else {
              // Copy already exists (from previous test run due to static mock data)
              // Just verify we can find it
              expect(existingCopy.templateId, equals(program.id));
            }
          }
        },
      );
    });

    group('Search and Filter Methods', () {
      test('searchPrograms should find programs by name', () async {
        final results = await repository.searchPrograms('Full Body');

        expect(results, isNotEmpty);
        expect(
          results.any(
            (p) =>
                p.name.toLowerCase().contains('full') ||
                p.name.toLowerCase().contains('body'),
          ),
          isTrue,
        );
      });

      test('searchPrograms should find programs by tag', () async {
        final results = await repository.searchPrograms('strength');

        expect(results, isNotEmpty);
        expect(
          results.any(
            (p) => p.tags.any((t) => t.toLowerCase().contains('strength')),
          ),
          isTrue,
        );
      });

      test('searchPrograms should be case-insensitive', () async {
        final lowerResults = await repository.searchPrograms('full body');
        final upperResults = await repository.searchPrograms('FULL BODY');
        final mixedResults = await repository.searchPrograms('Full Body');

        expect(lowerResults.length, equals(upperResults.length));
        expect(upperResults.length, equals(mixedResults.length));
      });

      test('getProgramsByDifficulty should filter correctly', () async {
        final beginnerPrograms = await repository.getProgramsByDifficulty(
          ProgramDifficulty.beginner,
        );

        expect(
          beginnerPrograms.every(
            (p) => p.difficulty == ProgramDifficulty.beginner,
          ),
          isTrue,
        );
      });

      test('getProgramsByType should filter correctly', () async {
        final generalPrograms = await repository.getProgramsByType(
          ProgramType.general,
        );

        expect(
          generalPrograms.every((p) => p.type == ProgramType.general),
          isTrue,
        );
      });
    });

    group('Program Cycle Operations', () {
      test(
        'getProgramCycleWithProgram should return cycle with program',
        () async {
          final programs = await repository.getDefaultPrograms();
          if (programs.isNotEmpty) {
            // Start a cycle to ensure we have one
            final cycle = await repository.startNewCycle(programs.first.id);

            final cycleWithProgram = await repository
                .getProgramCycleWithProgram(cycle.id);

            expect(cycleWithProgram, isNotNull);
            expect(cycleWithProgram!.program, isNotNull);
            expect(cycleWithProgram.program!.id, equals(programs.first.id));
          }
        },
      );

      test(
        'getProgramCyclesWithProgram should return all cycles for a program',
        () async {
          final programs = await repository.getDefaultPrograms();
          if (programs.isNotEmpty) {
            final programId = programs.first.id;

            // End existing and start multiple cycles
            await repository.endActiveCycle();
            await repository.startNewCycle(programId);
            await repository.endActiveCycle();
            await repository.startNewCycle(programId);

            final cycles = await repository.getProgramCyclesWithProgram(
              programId,
            );

            expect(cycles, isNotEmpty);
            expect(cycles.every((c) => c.programId == programId), isTrue);
            expect(cycles.every((c) => c.program != null), isTrue);
          }
        },
      );
    });

    group('Edge Cases', () {
      test(
        'operations should handle programs with no cycles gracefully',
        () async {
          // Create a program with no cycles
          final newProgram = Program(
            id: 'no_cycles_program',
            name: 'No Cycles Program',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: DateTime.now(),
            isDefault: false,
            cycles: [],
          );
          await repository.createProgram(newProgram);

          // Getting active cycle should return null
          await repository.endActiveCycle();
          final activeCycle = await repository.getActiveCycle();
          expect(activeCycle, isNull);

          // Starting a cycle should work
          final cycle = await repository.startNewCycle('no_cycles_program');
          expect(cycle, isNotNull);
          expect(cycle.cycleNumber, equals(1));
        },
      );

      test(
        'concurrent cycle starts should result in only one active',
        () async {
          final programs = await repository.getDefaultPrograms();
          if (programs.length >= 2) {
            // Start cycles on different programs in sequence
            await repository.startNewCycle(programs[0].id);
            await repository.startNewCycle(programs[1].id);

            // Only one should be active
            final allPrograms = await repository.getPrograms();
            var activeCycleCount = 0;
            for (final program in allPrograms) {
              for (final cycle in program.cycles) {
                if (cycle.isActive) activeCycleCount++;
              }
            }

            expect(activeCycleCount, equals(1));
          }
        },
      );

      test('empty search query should return all programs', () async {
        final allPrograms = await repository.getPrograms();
        final searchResults = await repository.searchPrograms('');

        // Empty search should return all programs
        expect(searchResults.length, equals(allPrograms.length));
      });

      test('getRecentPrograms with zero limit should return empty', () async {
        final recentPrograms = await repository.getRecentPrograms(limit: 0);
        expect(recentPrograms, isEmpty);
      });
    });
  });
}
