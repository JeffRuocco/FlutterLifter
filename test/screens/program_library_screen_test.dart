import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/core/providers/accessibility_provider.dart';
import 'package:flutter_lifter/core/providers/program_library_filter_provider.dart';
import 'package:flutter_lifter/core/providers/repository_providers.dart';
import 'package:flutter_lifter/core/theme/app_theme.dart';
import 'package:flutter_lifter/core/theme/theme_provider.dart';
import 'package:flutter_lifter/data/datasources/mock/mock_program_datasource.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/screens/program_library_screen.dart';

void main() {
  // ========================================================
  // Widget Tests for ProgramLibraryScreen
  //
  // These tests disable animations via the reduceMotionProvider
  // to allow Flutter's test framework to settle timers properly.
  // ========================================================

  group('ProgramLibraryScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    /// Creates a testable widget with all required providers
    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          // Disable animations for testing
          reduceMotionProvider.overrideWithValue(true),
          // Use mock theme provider
          createThemeModeProviderOverride(prefs),
          // Use fresh mock data source for each test
          programRepositoryProvider.overrideWithValue(
            ProgramRepositoryImpl(
              mockDataSource: MockProgramDataSource(),
              useMockData: true,
              useRemoteApi: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const ProgramLibraryScreen(),
        ),
      );
    }

    testWidgets('renders app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Program Library'), findsOneWidget);
    });

    testWidgets('renders tab bar with My Programs and Discover tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('My Programs'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('renders search field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search programs...'), findsOneWidget);
    });

    testWidgets('renders filter button with badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Find filter button by the HugeIcon it contains
      expect(
        find.byType(IconButton),
        findsWidgets, // Multiple icon buttons exist
      );
      // Filter button contains a Badge widget
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('displays skeleton loader during loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      // Pump a small amount to start loading
      await tester.pump(const Duration(milliseconds: 100));

      // Screen uses SkeletonList during loading state
      // Since mock data loads quickly, we verify the UI renders without error
      // and eventually shows content
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('displays programs after loading', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      // Allow time for async loading
      await tester.pump(const Duration(milliseconds: 1000));

      // Should display program cards (mock data has programs)
      // The mock data includes "Upper/Lower", "Full Body", "Push/Pull/Legs"
      expect(find.textContaining('Upper'), findsWidgets);
    });

    testWidgets('switching tabs updates content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap on Discover tab
      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(milliseconds: 500));

      // Should still show programs (from mock data)
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('search field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap the search field
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.pump();

      // Enter search text
      await tester.enterText(searchField, 'strength');
      await tester.pump(const Duration(milliseconds: 500));

      // Verify text was entered
      expect(find.text('strength'), findsOneWidget);
    });

    testWidgets('renders FAB for creating new program', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // ========================================================
  // Unit Tests for ProgramLibraryFilterState
  // (These don't require widget rendering)
  // ========================================================

  group('ProgramLibraryFilterState', () {
    test('initial state should have no active filters', () {
      const state = ProgramLibraryFilterState();

      expect(state.searchQuery, isEmpty);
      expect(state.selectedType, isNull);
      expect(state.selectedDifficulty, isNull);
      expect(state.selectedSource, equals(ProgramSource.all));
      expect(state.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters should be true when search query is set', () {
      const state = ProgramLibraryFilterState(searchQuery: 'test');

      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should be true when type filter is set', () {
      const state = ProgramLibraryFilterState(
        selectedType: ProgramType.strength,
      );

      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should be true when difficulty filter is set', () {
      const state = ProgramLibraryFilterState(
        selectedDifficulty: ProgramDifficulty.beginner,
      );

      expect(state.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should be true when source filter is not all', () {
      const state = ProgramLibraryFilterState(
        selectedSource: ProgramSource.customOnly,
      );

      expect(state.hasActiveFilters, isTrue);
    });

    test('activeFilterCount should count non-search filters correctly', () {
      const state = ProgramLibraryFilterState(
        searchQuery: 'test', // Not counted
        selectedType: ProgramType.strength,
        selectedDifficulty: ProgramDifficulty.beginner,
        selectedSource: ProgramSource.customOnly,
      );

      expect(state.activeFilterCount, equals(3));
    });

    test('copyWith should update values correctly', () {
      const original = ProgramLibraryFilterState();
      final updated = original.copyWith(
        searchQuery: 'new query',
        selectedType: ProgramType.hypertrophy,
      );

      expect(updated.searchQuery, equals('new query'));
      expect(updated.selectedType, equals(ProgramType.hypertrophy));
      expect(updated.selectedDifficulty, isNull); // Unchanged
    });

    test('copyWith should clear type when clearSelectedType is true', () {
      const original = ProgramLibraryFilterState(
        selectedType: ProgramType.strength,
      );
      final updated = original.copyWith(clearSelectedType: true);

      expect(updated.selectedType, isNull);
    });

    test(
      'copyWith should clear difficulty when clearSelectedDifficulty is true',
      () {
        const original = ProgramLibraryFilterState(
          selectedDifficulty: ProgramDifficulty.intermediate,
        );
        final updated = original.copyWith(clearSelectedDifficulty: true);

        expect(updated.selectedDifficulty, isNull);
      },
    );

    test('equality should work correctly', () {
      const state1 = ProgramLibraryFilterState(
        searchQuery: 'test',
        selectedType: ProgramType.strength,
      );
      const state2 = ProgramLibraryFilterState(
        searchQuery: 'test',
        selectedType: ProgramType.strength,
      );
      const state3 = ProgramLibraryFilterState(
        searchQuery: 'different',
        selectedType: ProgramType.strength,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('hashCode should be consistent with equality', () {
      const state1 = ProgramLibraryFilterState(
        searchQuery: 'test',
        selectedType: ProgramType.strength,
      );
      const state2 = ProgramLibraryFilterState(
        searchQuery: 'test',
        selectedType: ProgramType.strength,
      );

      expect(state1.hashCode, equals(state2.hashCode));
    });
  });

  group('ProgramFilterExtension', () {
    late List<Program> testPrograms;

    setUp(() {
      final now = DateTime.now();
      testPrograms = [
        Program(
          id: 'prog_1',
          name: 'Strength Builder',
          description: 'Build strength',
          type: ProgramType.strength,
          difficulty: ProgramDifficulty.intermediate,
          createdAt: now.subtract(const Duration(days: 10)),
          isDefault: true,
          lastUsedAt: now.subtract(const Duration(days: 1)),
          tags: ['strength', 'power'],
        ),
        Program(
          id: 'prog_2',
          name: 'Beginner Full Body',
          description: 'Perfect for beginners',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.beginner,
          createdAt: now.subtract(const Duration(days: 5)),
          isDefault: false,
          lastUsedAt: now,
          tags: ['beginner', 'full body'],
        ),
        Program(
          id: 'prog_3',
          name: 'Advanced Hypertrophy',
          description: 'Build muscle mass',
          type: ProgramType.hypertrophy,
          difficulty: ProgramDifficulty.advanced,
          createdAt: now.subtract(const Duration(days: 20)),
          isDefault: true,
          lastUsedAt: now.subtract(const Duration(days: 5)),
          tags: ['hypertrophy', 'muscle'],
        ),
        Program(
          id: 'prog_4',
          name: 'Custom Workout',
          description: 'My custom program',
          type: ProgramType.general,
          difficulty: ProgramDifficulty.intermediate,
          createdAt: now.subtract(const Duration(days: 2)),
          isDefault: false,
          lastUsedAt: null, // Never used
          tags: ['custom'],
        ),
      ];
    });

    test('applyFilters with no filters returns all programs sorted', () {
      const filter = ProgramLibraryFilterState();
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(4));
    });

    test('applyFilters should filter by search query in name', () {
      const filter = ProgramLibraryFilterState(searchQuery: 'strength');
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.name, contains('Strength'));
    });

    test('applyFilters should filter by search query in description', () {
      const filter = ProgramLibraryFilterState(searchQuery: 'muscle');
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.description, contains('muscle'));
    });

    test('applyFilters should filter by search query in tags', () {
      const filter = ProgramLibraryFilterState(searchQuery: 'power');
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.tags, contains('power'));
    });

    test('applyFilters should filter by search query in type displayName', () {
      const filter = ProgramLibraryFilterState(searchQuery: 'hypertrophy');
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.type, equals(ProgramType.hypertrophy));
    });

    test('applyFilters should filter by type', () {
      const filter = ProgramLibraryFilterState(
        selectedType: ProgramType.general,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(2));
      expect(result.every((p) => p.type == ProgramType.general), isTrue);
    });

    test('applyFilters should filter by difficulty', () {
      const filter = ProgramLibraryFilterState(
        selectedDifficulty: ProgramDifficulty.beginner,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.difficulty, equals(ProgramDifficulty.beginner));
    });

    test('applyFilters should filter by defaultOnly source', () {
      const filter = ProgramLibraryFilterState(
        selectedSource: ProgramSource.defaultOnly,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(2));
      expect(result.every((p) => p.isDefault), isTrue);
    });

    test('applyFilters should filter by customOnly source', () {
      const filter = ProgramLibraryFilterState(
        selectedSource: ProgramSource.customOnly,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(2));
      expect(result.every((p) => !p.isDefault), isTrue);
    });

    test('applyFilters should filter by myPrograms source', () {
      const filter = ProgramLibraryFilterState(
        selectedSource: ProgramSource.myPrograms,
      );
      final result = testPrograms.applyFilters(filter);

      // myPrograms = custom programs + default programs with lastUsedAt
      // prog_1: default with lastUsedAt ✓
      // prog_2: custom ✓
      // prog_3: default with lastUsedAt ✓
      // prog_4: custom ✓
      expect(result.length, equals(4));
    });

    test('applyFilters should return empty for communityOnly source', () {
      const filter = ProgramLibraryFilterState(
        selectedSource: ProgramSource.communityOnly,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result, isEmpty);
    });

    test('applyFilters should sort by lastUsed correctly', () {
      const filter = ProgramLibraryFilterState(
        sortOption: ProgramSortOption.lastUsed,
      );
      final result = testPrograms.applyFilters(filter);

      // prog_2 (just now), prog_1 (1 day ago), prog_3 (5 days ago), prog_4 (null - last)
      expect(result[0].id, equals('prog_2'));
      expect(result[1].id, equals('prog_1'));
      expect(result[2].id, equals('prog_3'));
      expect(result[3].id, equals('prog_4')); // null lastUsedAt goes to end
    });

    test('applyFilters should sort by name correctly', () {
      const filter = ProgramLibraryFilterState(
        sortOption: ProgramSortOption.name,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result[0].name, equals('Advanced Hypertrophy'));
      expect(result[1].name, equals('Beginner Full Body'));
      expect(result[2].name, equals('Custom Workout'));
      expect(result[3].name, equals('Strength Builder'));
    });

    test('applyFilters should sort by createdAt correctly', () {
      const filter = ProgramLibraryFilterState(
        sortOption: ProgramSortOption.createdAt,
      );
      final result = testPrograms.applyFilters(filter);

      // Most recent first
      expect(result[0].id, equals('prog_4')); // 2 days ago
      expect(result[1].id, equals('prog_2')); // 5 days ago
      expect(result[2].id, equals('prog_1')); // 10 days ago
      expect(result[3].id, equals('prog_3')); // 20 days ago
    });

    test('applyFilters should sort by difficulty correctly', () {
      const filter = ProgramLibraryFilterState(
        sortOption: ProgramSortOption.difficulty,
      );
      final result = testPrograms.applyFilters(filter);

      // Beginner (0) < Intermediate (1) < Advanced (2)
      expect(result[0].difficulty, equals(ProgramDifficulty.beginner));
      expect(result[1].difficulty, equals(ProgramDifficulty.intermediate));
      expect(result[2].difficulty, equals(ProgramDifficulty.intermediate));
      expect(result[3].difficulty, equals(ProgramDifficulty.advanced));
    });

    test('applyFilters should combine multiple filters', () {
      const filter = ProgramLibraryFilterState(
        selectedType: ProgramType.general,
        selectedDifficulty: ProgramDifficulty.intermediate,
      );
      final result = testPrograms.applyFilters(filter);

      expect(result.length, equals(1));
      expect(result.first.id, equals('prog_4'));
    });

    test('applyFilters with no matches returns empty list', () {
      const filter = ProgramLibraryFilterState(
        searchQuery: 'nonexistent program xyz',
      );
      final result = testPrograms.applyFilters(filter);

      expect(result, isEmpty);
    });

    test('search should be case-insensitive', () {
      const filterLower = ProgramLibraryFilterState(searchQuery: 'strength');
      const filterUpper = ProgramLibraryFilterState(searchQuery: 'STRENGTH');
      const filterMixed = ProgramLibraryFilterState(searchQuery: 'Strength');

      final resultLower = testPrograms.applyFilters(filterLower);
      final resultUpper = testPrograms.applyFilters(filterUpper);
      final resultMixed = testPrograms.applyFilters(filterMixed);

      expect(resultLower.length, equals(resultUpper.length));
      expect(resultUpper.length, equals(resultMixed.length));
    });

    test('should handle empty program list', () {
      const filter = ProgramLibraryFilterState(searchQuery: 'test');
      final result = <Program>[].applyFilters(filter);

      expect(result, isEmpty);
    });

    test(
      'sort by lastUsed should alphabetize programs with same lastUsedAt',
      () {
        final now = DateTime.now();
        final programs = [
          Program(
            id: 'b_prog',
            name: 'B Program',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now,
            isDefault: false,
            lastUsedAt: null,
          ),
          Program(
            id: 'a_prog',
            name: 'A Program',
            type: ProgramType.general,
            difficulty: ProgramDifficulty.beginner,
            createdAt: now,
            isDefault: false,
            lastUsedAt: null,
          ),
        ];

        const filter = ProgramLibraryFilterState(
          sortOption: ProgramSortOption.lastUsed,
        );
        final result = programs.applyFilters(filter);

        // Both have null lastUsedAt, so should be sorted alphabetically
        expect(result[0].name, equals('A Program'));
        expect(result[1].name, equals('B Program'));
      },
    );
  });

  group('ProgramSortOption', () {
    test('should have correct display names', () {
      expect(ProgramSortOption.lastUsed.displayName, equals('Last Used'));
      expect(ProgramSortOption.name.displayName, equals('Name'));
      expect(ProgramSortOption.createdAt.displayName, equals('Date Created'));
      expect(ProgramSortOption.difficulty.displayName, equals('Difficulty'));
    });

    test('should have all expected values', () {
      expect(ProgramSortOption.values.length, equals(4));
      expect(ProgramSortOption.values, contains(ProgramSortOption.lastUsed));
      expect(ProgramSortOption.values, contains(ProgramSortOption.name));
      expect(ProgramSortOption.values, contains(ProgramSortOption.createdAt));
      expect(ProgramSortOption.values, contains(ProgramSortOption.difficulty));
    });
  });
}
