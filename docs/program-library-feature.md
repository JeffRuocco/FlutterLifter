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

### Phase 2: Repository Updates

- [ ] **Add source-aware methods** to `ProgramRepository` interface
  ```dart
  Future<List<Program>> getDefaultPrograms();
  Future<List<Program>> getCustomPrograms();
  Future<List<Program>> getPrograms({ProgramSource source = ProgramSource.all});
  Future<List<Program>> getRecentPrograms({int limit = 5});
  ```

- [ ] **Add active cycle management methods**
  ```dart
  Future<ProgramCycle?> getActiveCycle();
  Future<void> endActiveCycle();
  Future<ProgramCycle> startNewCycle(String programId);
  ```

- [ ] **Add program cloning method**
  ```dart
  Future<Program> copyProgramAsCustom(Program template);
  ```

- [ ] **Add community sharing methods** (can stub for now)
  ```dart
  Future<void> publishProgram(String programId);
  Future<Program> importProgram(Program program);
  ```

- [ ] **Implement methods** in `InMemoryProgramRepository`
  - [ ] `getDefaultPrograms()` - filter where `isDefault == true`
  - [ ] `getCustomPrograms()` - filter where `isDefault == false`
  - [ ] `getPrograms({ProgramSource})` - unified filter method
  - [ ] `getRecentPrograms({limit})` - sort by `lastUsedAt` descending
  - [ ] `getActiveCycle()` - find cycle where `isActive == true`
  - [ ] `endActiveCycle()` - set `isActive = false`, `endDate = now`
  - [ ] `startNewCycle()` - auto-end active, create new cycle, update `lastUsedAt`
  - [ ] `copyProgramAsCustom()` - deep copy with new ID, `isDefault = false`

---

### Phase 3: Provider Updates

- [ ] **Create `ProgramLibraryFilter` class** in `lib/core/providers/program_library_filter_provider.dart`
  ```dart
  class ProgramLibraryFilter {
    final String searchQuery;
    final ProgramType? selectedType;
    final ProgramDifficulty? selectedDifficulty;
    final ProgramSource selectedSource;
    final ProgramSortOption sortOption; // lastUsed, name, createdAt
  }
  ```

- [ ] **Create `ProgramLibraryFilterNotifier`** provider

- [ ] **Add program library providers** in `lib/core/providers/program_providers.dart`
  - [ ] `activeCycleProvider` - watches for active cycle
  - [ ] `recentProgramsProvider` - fetches recent 5 programs
  - [ ] `filteredProgramsProvider` - responds to filter changes

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
