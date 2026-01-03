# Exercise Library Feature

A central hub for browsing, filtering, and viewing detailed information about
exercises. Includes user statistics tracking, personal records, and a
placeholder for future community "Discover" functionality.

## Overview

The Exercise Library will be accessible via:

- **Bottom navigation tab** (5th tab, index 2)
- **Home screen quick-action card** (replacing "coming soon" message)

### Key Features

- Browse all exercises with search and filtering
- Filter by category, muscle group (with collapsible region sections), and
  source
- View detailed exercise information including instructions and media
- Track personal records (PRs) and exercise history
- Create and edit custom exercises
- Placeholder "Discover" tab for future community exercise sharing

---

## Implementation Checklist

### Phase 1: Data Layer Updates ✅

- [x] **1. Add MuscleGroup enum** (`lib/models/shared_enums.dart`)
  - Define enum with all muscle groups:
    - Chest, Upper Chest, Triceps, Shoulders, Side Delts, Rear Delts
    - Lats, Rhomboids, Back, Lower Back, Rotator Cuff, Traps
    - Biceps, Brachialis, Forearms
    - Quadriceps, Glutes, Hamstrings, Calves, Hip Flexors, Legs
    - Core, Abs, Lower Abs
    - Arms, Full Body, Cardiovascular
  - Add `displayName` extension
  - Add `MuscleGroupRegion` enum (upperPush, upperPull, legs, core, cardio,
    other)
  - Add `region` getter on MuscleGroup for UI grouping

- [x] **2. Update Exercise model** (`lib/models/exercise_models.dart`)
  - Change `targetMuscleGroups` from `List<String>` to `List<MuscleGroup>`
  - Update `fromJson` to parse enum values
  - Update `toJson` to serialize enum values
  - Update `copyWith` method signature
  - Update `WorkoutExercise.targetMuscleGroups` getter
  - Update `primaryMuscleGroupsText` helper to use `displayName`

- [x] **3. Migrate default exercises**
  (`lib/data/datasources/mock/default_exercises.dart`)
  - Replace all string literals with `MuscleGroup` enum values
  - Example: `['Chest', 'Triceps']` → `[MuscleGroup.chest, MuscleGroup.triceps]`

- [x] **4. Update exercise repository**
  (`lib/data/repositories/exercise_repository.dart`)
  - Change `getExercisesByMuscleGroup(String)` to `getExercisesByMuscleGroup(MuscleGroup)`
  - Update implementation to compare enum values

- [x] **5. Update existing tests** (`test/models/`, `test/data/`)
  - Replace string muscle group references with enum values
  - Ensure all tests pass after migration (134 tests passing)

---

### Phase 2: Navigation & Routing ✅

- [x] **6. Add exercise routes** (`lib/core/router/app_router.dart`)
  - Add to `AppRoutes` class:

    ```dart
    static const String exercises = '/exercises';
    static const String exerciseDetail = '/exercises/:id';
    static const String createExercise = '/exercises/create';
    static const String editExercise = '/exercises/:id/edit';
    ```

  - Add `exercises` to ShellRoute with `FadeTransition`
  - Add nested routes with `parentNavigatorKey: _rootNavigatorKey` for
    full-screen display
  - Add router extensions:

    ```dart
    void goToExercises() => go(AppRoutes.exercises);
    void pushExerciseDetail(String id) => push('/exercises/$id');
    void pushCreateExercise() => push(AppRoutes.createExercise);
    void pushEditExercise(String id) => push('/exercises/$id/edit');
    ```

- [x] **7. Update shell navigation** (`lib/widgets/app_shell.dart`)
  - Insert `ShellTab.exercises` at index 2:

    ```dart
    enum ShellTab {
      home(0),
      programs(1),
      exercises(2),  // NEW
      workout(3),    // was 2
      progress(4);   // was 3
    }
    ```

  - Add `NavigationDestination` with `strokeRoundedBookOpen01` icon
  - Update `_getCurrentIndex()` to handle `/exercises` path
  - Update `_onTabSelected()` switch cases

- [x] **8. Wire Home quick-action card** (`lib/screens/home_screen.dart`)
  - Replace "coming soon" snackbar with:

    ```dart
    onTap: () => context.go(AppRoutes.exercises),
    ```

---

### Phase 3: UI Components

- [x] **9. Create MuscleGroupFilterSheet** (inline in
  `lib/screens/exercise_library_screen.dart`)
  - Implemented as `_FilterBottomSheet` with collapsible region sections
  - Note: Can be extracted to separate file later if needed

- [ ] **9b. Extract to separate widget**
  (`lib/widgets/exercise/muscle_group_filter_sheet.dart`) *(optional)*
  - Bottom sheet or modal with collapsible sections
  - Group by `MuscleGroupRegion`:
    - Upper Push: Chest, Upper Chest, Triceps, Shoulders, Side Delts
    - Upper Pull: Lats, Rhomboids, Back, Lower Back, Rear Delts, Biceps, etc.
    - Legs: Quadriceps, Glutes, Hamstrings, Calves, Hip Flexors
    - Core: Core, Abs, Lower Abs
    - Cardio: Cardiovascular, Full Body
  - Use `ExpansionTile` for collapsible sections
  - Use `FilterChip` or `ChoiceChip` for muscle group selection
  - Support multi-select with `Set<MuscleGroup>` state
  - Include "Clear All" and "Apply" buttons

---

### Phase 4: Screens

- [x] **10. Create ExerciseLibraryScreen**
  (`lib/screens/exercise_library_screen.dart`)
  - Search bar at top
  - Horizontal scrolling category filter chips
  - "Filter" button → opens `_FilterBottomSheet`
  - Tab toggle: "My Exercises" | "Discover"
  - My Exercises tab:
    - ListView of exercise cards grouped by muscle region (collapsible)
    - Source filter (All, Default, Custom)
    - Empty state when no results
  - Discover tab:
    - Placeholder empty state for future community features
    - Message: "Community exercises coming soon!"
  - FAB for creating new exercise *(shows "coming soon" for now)*

- [x] **11. Create ExerciseDetailScreen**
  (`lib/screens/exercise_detail_screen.dart`)
  - Hero gradient section with category icon
  - Exercise name and category/source badges
  - Muscle group chips (from enum, using displayName)
  - Default values section (sets, reps, rest time, weight)
  - Instructions text section
  - Notes section (displays exercise.notes if available)
  - Media section (placeholder for future video/images)
  - Edit/Share menu (for custom exercises)
  - **Pending:** User notes editing, PR stats with Epley score, history chart

- [x] **12. Create CreateExerciseScreen**
  (`lib/screens/create_exercise_screen.dart`)
  - Reusable for both create and edit modes
  - Form fields:
    - Name (required)
    - Short name (optional)
    - Category dropdown (ExerciseCategory enum)
    - Muscle groups (collapsible multi-select, reuse
      MuscleGroupFilterSheet pattern)
    - Default sets (number input)
    - Default reps (number input)
    - Default weight (number input, optional)
    - Default rest time (seconds input)
    - Instructions (multi-line text area)
    - Image URL (text input, future: file picker with Firebase Storage)
    - Video URL (text input, future: YouTube embed support)
  - Validation
  - Save/Update button
  - Cancel button

---

### Phase 5: State Management & Data ✅

- [x] **13. Add Exercise History Models** (`lib/models/exercise/`)
  
  **13a. ExerciseSetRecord** - Individual set within a session:

    ```dart
    class ExerciseSetRecord {
      final String id;
      final int setNumber;
      final double weight;
      final int reps;
      final bool isWarmup;
      final double? rpe;  // Rate of Perceived Exertion (optional)
      final String? notes;
      final double epleyScore;  // Calculated: weight × (1 + reps/30)
    }
    ```
  
  **13b. ExerciseSessionRecord** - All sets from a single workout session:

    ```dart
    class ExerciseSessionRecord {
      final String id;
      final String exerciseId;
      final String workoutSessionId;  // Links to workout
      final DateTime performedAt;
      final List<ExerciseSetRecord> sets;
      final double? sessionPR;  // Best Epley score this session
      final String? notes;
      
      // Computed getters:
      int get totalSets => sets.length;
      int get workingSets => sets.where((s) => !s.isWarmup).length;
      double get totalVolume => sets.fold(0, (sum, s) => sum + s.weight *
          s.reps);
      double get maxWeight => sets.map((s) => s.weight).reduce(max);
      int get maxReps => sets.map((s) => s.reps).reduce(max);
    }
    ```
  
  **13c. ExerciseHistory** - Complete history for an exercise:

    ```dart
    class ExerciseHistory {
      final String exerciseId;
      final List<ExerciseSessionRecord> sessions;  // Sorted by date desc
      final ExerciseSetRecord? allTimePR;  // Best ever Epley score
      final DateTime? prSetAt;
      final int totalTimesPerformed;
      
      // Computed getters:
      ExerciseSessionRecord? get lastSession => sessions.firstOrNull;
      DateTime? get lastPerformedAt => lastSession?.performedAt;
      List<double> get prProgression => /* PR over time for chart */;
      double get averageWeight => /* across all working sets */;
      int get averageReps => /* across all working sets */;
    }
    ```

- [x] **14. Add ExerciseHistoryRepository**
  (`lib/data/repositories/exercise_history_repository.dart`)
  - Methods:

    ```dart
    Future<ExerciseHistory?> getHistoryForExercise(String exerciseId);
    Future<List<ExerciseSessionRecord>> getRecentSessions(String exerciseId,
        {int limit = 10});
    Future<void> recordSession(ExerciseSessionRecord session);
    Future<void> updateSession(ExerciseSessionRecord session);
    Future<void> deleteSession(String sessionId);
    Stream<ExerciseHistory> watchHistory(String exerciseId);
    ```

  - Mock implementation with in-memory storage (`DevExerciseHistoryRepository`)
  - Includes mock data for bench press, squat, and deadlift
  - Future: Firebase/local database implementation

- [x] **15. Create exercise filter provider**
  (`lib/core/providers/exercise_filter_provider.dart`)
  - State class:

    ```dart
    class ExerciseFilterState {
      final String searchQuery;
      final Set<ExerciseCategory> selectedCategories;
      final Set<MuscleGroup> selectedMuscleGroups;
      final ExerciseSource? sourceFilter;
      final ExerciseSortOption sortOption;
      final bool favoritesFirst;
    }
    ```

  - StateNotifier with methods:
    - `setSearchQuery(String query)` / `clearSearchQuery()`
    - `toggleCategory(ExerciseCategory)` / `setCategories()` / `clearCategories()`
    - `toggleMuscleGroup(MuscleGroup)` / `setMuscleGroups()` / `clearMuscleGroups()`
    - `setSourceFilter(ExerciseSource?)` / `clearSourceFilter()`
    - `setSortOption(ExerciseSortOption)`
    - `toggleFavoritesFirst()` / `setFavoritesFirst(bool)`
    - `clearAllFilters()` / `clearFiltersKeepSort()`
  - Extension `ExerciseFilterExtension` on `List<Exercise>` for applying filters
  - Sort options: alphabetical, reverseAlphabetical, recentlyUsed, mostUsed, muscleGroup

---

### Phase 6: Exercise History UI ✅

- [x] **16. Add ExerciseHistoryScreen**
  (`lib/screens/exercise_history_screen.dart`)
  - Full history view for a single exercise
  - Header with exercise name, all-time PR badge
  - PR progression chart (line graph over time)
  - Scrollable list of all sessions, newest first
  - Each session card shows:
    - Date performed
    - Workout name (if available)
    - List of sets: weight × reps (highlight PR sets)
    - Session volume
    - Notes (if any)
  - Tap session to expand/collapse set details
  - Option to edit/delete past sessions

- [x] **17. Update ExerciseDetailScreen**
  (`lib/screens/exercise_detail_screen.dart`)
  - Add "History" section with:
    - All-time PR card with Epley score
    - Last performed date
    - Quick stats (total sessions, best weight, best reps)
    - "View Full History" button → navigates to ExerciseHistoryScreen
    - Mini preview of last 3 sessions
  - Add PR badge animation when viewing a PR exercise

- [x] **18. Add exercise history route** (`lib/core/router/app_router.dart`)
  - Add route: `/exercises/:id/history`
  - Add router extension: `pushExerciseHistory(String id)`

---

### Phase 7: Integration with Workouts ✅

- [x] **19. Auto-record exercise sessions**
  - When a workout is completed, automatically create
    `ExerciseSessionRecord` entries
  - Link session records to workout via `workoutSessionId`
  - Calculate and store Epley scores for each set
  - Update all-time PR if beaten

- [x] **20. Show PR indicators in workout logging**
  - During active workout, show if current set beats PR
  - Celebrate new PRs with animation/confetti
  - Show "last time" reference (e.g., "Last: 135 lbs × 8")

---

## Technical Notes

### Epley Formula for PR Score

```dart
double calculateEpleyScore(double weight, int reps) {
  if (reps == 1) return weight;
  return weight * (1 + reps / 30.0);
}
```

### Why Track Full History?

- **Progress Visualization**: See strength gains over weeks/months
- **Pattern Recognition**: Identify plateaus, optimal rep ranges
- **Workout Planning**: Reference previous performance for progressive overload
- **Motivation**: Celebrate PRs and see cumulative work

### Muscle Group Regions

```dart
enum MuscleGroupRegion {
  upperPush,   // Chest, Shoulders, Triceps
  upperPull,   // Back, Lats, Biceps
  legs,        // Quads, Glutes, Hamstrings, Calves
  core,        // Abs, Core
  cardio,      // Cardiovascular
  other,       // Full Body, misc
}
```

### Future Considerations

- **Firebase Storage** for exercise images
- **YouTube API** integration for video embeds
- **Community Discover** feature with user-published exercises
- **Exercise favorites** system
- **Exercise history** detailed view with charts

---

## File Structure (New Files)

```text
lib/
├── core/
│   └── providers/
│       ├── exercise_filter_provider.dart       # Step 15
│       └── exercise_history_provider.dart      # Step 14 (watches history)
├── data/
│   └── repositories/
│       └── exercise_history_repository.dart    # Step 14
├── models/
│   └── exercise/
│       ├── exercise_set_record.dart            # Step 13a
│       ├── exercise_session_record.dart        # Step 13b
│       └── exercise_history.dart               # Step 13c
├── screens/
│   ├── exercise_library_screen.dart            # Step 10 ✅
│   ├── exercise_detail_screen.dart             # Step 11 ✅ (to be enhanced
│       in Step 17)
│   └── exercise_history_screen.dart            # Step 16
└── widgets/
    └── exercise/
        ├── muscle_group_filter_sheet.dart      # Step 9b (optional extraction)
        ├── pr_badge.dart                       # PR indicator widget
        └── session_card.dart                   # Session history card
```

---

## Progress Log

|Date|Step|Notes|
|------|------|-------|
|2026-01-01|1-5|Phase 1 complete: enum, model, tests|
|2026-01-01|6-8|Phase 2 complete: routes, nav, home|
|2026-01-01|9-11|Phase 3-4 partial: screens, filter|
|2026-01-01|Bug fixes|Fixed enum usage in widgets|
|2026-01-03|12|Phase 4 complete: CreateExerciseScreen with full CRUD|
|2026-01-03|16-18|Phase 6 complete: ExerciseHistoryScreen, route, history section in detail|
|2026-01-03|19-20|Phase 7 complete: Auto-record sessions on workout finish, PR indicators in ExerciseCard|
