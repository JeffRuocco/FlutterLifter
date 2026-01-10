# Program Library Feature

This document outlines the implementation plan for the Program Library feature, which allows users to browse, manage, and start programs from a centralized library.

## Overview

The Program Library mirrors the Exercise Library pattern, supporting:
- **Default Programs**: Built-in program templates (read-only)
- **Custom Programs**: User-created programs (full CRUD)
- **Community Programs**: Programs shared by other users (future)

## User Flow

1. **Programs Screen** → Shows recommended programs and recent programs, with link to full library
2. **Program Library Screen** → Browse all programs with tabs (My Programs / Discover)
3. **Program Detail Screen** → View program info, cycle history, start/resume cycles

## Key Behaviors

- **Single Active Program**: Only one program cycle can be active at a time
- **Auto-End Previous Cycle**: Starting a new cycle silently ends any active cycle
- **Template Cloning**: Starting a default program creates a user copy for customization
- **Last Used Sorting**: Programs sorted by `lastUsedAt` for easy access to recent programs

---

## Implementation Checklist

### Phase 1: Model Updates ✅

- [x] **Add `ProgramSource` enum** in `lib/models/shared_enums.dart`
  ```dart
  enum ProgramSource {
    all,
    defaultOnly,
    customOnly,
    communityOnly,
  }
  ```

- [x] **Add fields to `Program` model** in `lib/models/program_models.dart`
  - [x] Add `isDefault` boolean field (default: `false`)
  - [x] Add `lastUsedAt` DateTime? field
  - [x] Update `copyWith()` method
  - [x] Update `toJson()` method
  - [x] Update `fromJson()` factory

- [x] **Update mock programs** in `lib/data/datasources/mock/mock_data.dart`
  - [x] Set `isDefault: true` for all default programs

- [x] **Export `ProgramSource`** from `lib/models/shared_enums.dart` (already exported via models barrel)

---

### Phase 2: Repository Updates ✅

- [x] **Add source-aware methods** to `ProgramRepository` interface
  ```dart
  Future<List<Program>> getDefaultPrograms();
  Future<List<Program>> getCustomPrograms();
  Future<List<Program>> getProgramsBySource({ProgramSource source = ProgramSource.all});
  Future<List<Program>> getRecentPrograms({int limit = 5});
  ```

- [x] **Add active cycle management methods**
  ```dart
  Future<ProgramCycle?> getActiveCycle();
  Future<void> endActiveCycle();
  Future<ProgramCycle> startNewCycle(String programId);
  ```

- [x] **Add program cloning method**
  ```dart
  Future<Program> copyProgramAsCustom(Program template);
  ```

- [x] **Add community sharing methods** (stubbed for future)
  ```dart
  Future<void> publishProgram(String programId);
  Future<Program> importProgram(Program program);
  ```

- [x] **Implement methods** in `ProgramRepositoryImpl`
  - [x] `getProgramsBySource({ProgramSource})` - unified filter method
  - [x] `getDefaultPrograms()` - filter where `isDefault == true`
  - [x] `getCustomPrograms()` - filter where `isDefault == false`
  - [x] `getRecentPrograms({limit})` - sort by `lastUsedAt` descending
  - [x] `getActiveCycle()` - find cycle where `isActive == true`
  - [x] `endActiveCycle()` - set `isActive = false`, `endDate = now`
  - [x] `startNewCycle()` - auto-end active, create new cycle, update `lastUsedAt`
  - [x] `copyProgramAsCustom()` - deep copy with new ID, `isDefault = false`

---

### Phase 3: Provider Updates ✅

- [x] **Create `ProgramLibraryFilterState` class** in `lib/core/providers/program_library_filter_provider.dart`
  ```dart
  class ProgramLibraryFilterState {
    final String searchQuery;
    final ProgramType? selectedType;
    final ProgramDifficulty? selectedDifficulty;
    final ProgramSource selectedSource;
    final ProgramSortOption sortOption; // lastUsed, name, createdAt, difficulty
  }
  ```

- [x] **Create `ProgramLibraryFilterNotifier`** provider with methods:
  - `setSearchQuery()`, `clearSearchQuery()`
  - `setTypeFilter()`, `clearTypeFilter()`
  - `setDifficultyFilter()`, `clearDifficultyFilter()`
  - `setSourceFilter()`
  - `setSortOption()`
  - `clearAllFilters()`, `clearFiltersKeepSort()`

- [x] **Create `ProgramSortOption` enum** with options:
  - `lastUsed`, `name`, `createdAt`, `difficulty`

- [x] **Create `ProgramFilterExtension`** on `List<Program>`:
  - `applyFilters(ProgramLibraryFilterState)` - applies all filters and sorting

- [x] **Add program library providers** in `lib/core/providers/repository_providers.dart`
  - [x] `activeCycleProvider` - watches for active cycle
  - [x] `recentProgramsProvider` - fetches recent 5 programs
  - [x] `defaultProgramsProvider` - fetches default programs
  - [x] `customProgramsProvider` - fetches custom programs
  - [x] `programsBySourceProvider` - fetches programs by source

- [x] **Update providers barrel file** to export new providers

---

### Phase 4: Route Updates

- [ ] **Add routes** in `lib/core/router/app_router.dart`
  ```dart
  static const String programLibrary = '/programs/library';
  static const String programDetail = '/programs/:id';
  static const String editProgram = '/programs/:id/edit';
  ```

- [ ] **Add GoRoute definitions** under programs shell route
  - [ ] `/programs/library` → `ProgramLibraryScreen`
  - [ ] `/programs/:id` → `ProgramDetailScreen`
  - [ ] `/programs/:id/edit` → `CreateProgramScreen` (edit mode)

- [ ] **Add navigation extensions**
  ```dart
  void pushProgramLibrary();
  void pushProgramDetail(String programId);
  void pushEditProgram(String programId);
  ```

---

### Phase 5: Program Library Screen

- [ ] **Create `ProgramLibraryScreen`** in `lib/screens/programs/program_library_screen.dart`
  - [ ] Implement `ConsumerStatefulWidget` with `TabController`
  - [ ] Add "My Programs" tab (custom + used default programs)
  - [ ] Add "Discover" tab (all default programs, community programs)
  - [ ] Add search bar with real-time filtering
  - [ ] Add filter button opening `_ProgramFilterBottomSheet`
  - [ ] Display active filter chips with "Clear all"
  - [ ] Group programs by `ProgramType` with collapsible sections
  - [ ] Add sort dropdown (Last Used, Name, Created Date)
  - [ ] Add FAB linking to `CreateProgramScreen`

- [ ] **Create `_ProgramFilterBottomSheet`** widget
  - [ ] Program type filter chips
  - [ ] Difficulty filter chips
  - [ ] Source filter (if on Discover tab)
  - [ ] Apply/Reset buttons

- [ ] **Create `_ProgramLibraryCard`** widget
  - [ ] Display program name, type, difficulty
  - [ ] Show active cycle indicator if applicable
  - [ ] Show last used date
  - [ ] Navigate to `ProgramDetailScreen` on tap

---

### Phase 6: Program Detail Screen

- [ ] **Create `ProgramDetailScreen`** in `lib/screens/programs/program_detail_screen.dart`
  - [ ] Display program header (name, description, type badge, difficulty badge)
  - [ ] Display workout structure preview (list of workout templates)
  - [ ] Display cycle history section

- [ ] **Implement cycle history section**
  - [ ] Show last 5 cycles by default
  - [ ] Add "Show All" expansion button when > 5 cycles
  - [ ] Display cycle cards with:
    - Start date / End date
    - Completion status (active, completed, abandoned)
    - Number of workouts completed

- [ ] **Implement action buttons**
  - [ ] "Resume Cycle" - shown if this program has an unfinished cycle
  - [ ] "Start New Cycle" - always shown for custom programs
  - [ ] "Use This Program" - shown for default programs (clones then starts)

- [ ] **Implement start cycle logic**
  - [ ] Call `repository.startNewCycle(programId)` (auto-ends any active)
  - [ ] Navigate to home or workout screen
  - [ ] Show success snackbar

---

### Phase 7: Programs Screen Updates

- [ ] **Update `ProgramsScreen`** in `lib/screens/programs/programs_screen.dart`
  - [ ] Keep "Recommended Programs" section as-is
  - [ ] Add "Recent Programs" section (3-5 programs from `recentProgramsProvider`)
  - [ ] Replace "Custom Programs" section with "Browse Library" card
  - [ ] Link "Browse Library" to `ProgramLibraryScreen`

- [ ] **Create `_RecentProgramCard`** widget
  - [ ] Compact card showing program name and last used date
  - [ ] Navigate to `ProgramDetailScreen` on tap

- [ ] **Create `_BrowseLibraryCard`** widget
  - [ ] Prominent card with icon and "Browse Program Library" text
  - [ ] Navigate to `ProgramLibraryScreen` on tap

---

### Phase 8: Testing

- [ ] **Add unit tests** for repository methods
  - [ ] `getDefaultPrograms()` returns only default programs
  - [ ] `getCustomPrograms()` returns only custom programs
  - [ ] `getRecentPrograms()` returns sorted by lastUsedAt
  - [ ] `startNewCycle()` auto-ends previous active cycle
  - [ ] `copyProgramAsCustom()` creates independent copy

- [ ] **Add widget tests** for new screens
  - [ ] `ProgramLibraryScreen` renders tabs correctly
  - [ ] `ProgramDetailScreen` displays program info
  - [ ] Cycle history shows last 5 with expansion

---

## File Structure

```
lib/
├── models/program/
│   ├── program.dart              # Add ProgramSource, isDefault, lastUsedAt
│   └── default_programs.dart     # Set isDefault: true
├── data/repositories/
│   └── program_repository.dart   # Add library methods
├── core/
│   ├── providers/
│   │   ├── program_providers.dart           # Add new providers
│   │   └── program_library_filter_provider.dart  # New file
│   └── router/
│       └── app_router.dart       # Add library routes
└── screens/programs/
    ├── programs_screen.dart      # Update with recent + library link
    ├── program_library_screen.dart   # New file
    └── program_detail_screen.dart    # New file
```

---

## Dependencies

No new packages required. Uses existing:
- `flutter_riverpod` for state management
- `go_router` for navigation
- `hugeicons` for icons

---

## Future Enhancements

- [ ] Community program sharing via deep links or codes
- [ ] Program ratings and reviews
- [ ] Program templates marketplace
- [ ] Import/export programs as JSON files
- [ ] Program recommendations based on user history
