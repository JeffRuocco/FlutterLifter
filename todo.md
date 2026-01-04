# TODO

## MVP

- [x] **Add logging service**
  - [ ] **Connect Firebase logging**
- [x] **Add exercise repository**
  - [x] Create ExerciseRepository with default and custom exercise support
  - [x] Add UserExercisePreferences model for customizing default exercises
  - [x] Add ExerciseSource enum for filtering queries
  - [x] Expand default exercises to 40+ covering all categories
  - [x] Deprecate exercise methods in ProgramRepository
- [x] **WorkoutService Implementation**
  - [x] Create WorkoutService class with auto-save functionality
  - [x] Add workout session methods to ProgramRepository
  - [x] Integrate WorkoutService with ServiceLocator
  - [x] Create usage examples and integration guide
- [x] **Integrate WorkoutService with UI**
  - [x] Update WorkoutScreen to use WorkoutService
  - [x] Add unfinished sets validation dialog
  - [x] Test auto-save functionality in UI
- [x] **Data persistance**
  - [x] Workout session persistance (✅ WorkoutService ready)
  - [x] Program cycle persistance
- [x] **Workout complete validation (warn about incomplete)**
  - [x] Warn about finishing workout before completing all sets (✅ WorkoutService ready)
  - [x] Warn about leaving workout page with sets recorded, but not marked complete (✅ WorkoutService ready)
- [x] **Add exercise library pages** (see `exercise-library-feature.md`)
  - [x] Normalize exercise name capitilization
- [ ] **Remove sets from workout**
- [ ] **Start program functionality**
  - [ ] Start new program and end any previous ones
- [ ] **Determine best option for location storage (Hive?)**
- [ ] **Add Hive for local storage (all platforms)**
  - [ ] Add hive dependencies to pubspec.yaml
  - [ ] Implement HiveStorageService
  - [ ] Update ServiceLocator to use Hive
  - [ ] Test storage persistence in PWA
- [ ] **Add program creation pages**
  - [ ] Shareable programs (link/code, eventually a public program library)

## Incremental updates

- [ ] **Implement user authentication**
  - [ ] Migrate custom exercise storage to per-user keys when auth is implemented
- [ ] **UI overhaul**
  - [x] Migrate ServiceLocator to Riverpod state management
  - [x] Implement GoRouter for declarative navigation
  - [x] Add bottom navigation shell (Home, Progress, Programs)
  - [x] Add theme provider with light/dark mode persistence
  - [x] Standardize icons to HugeIcons (strokeRounded)
  - [x] Create widget gallery screen for component reference
  - [x] Create design-guidelines.md and widget-gallery.md docs
  - [ ] Add riverpod_generator + build_runner for type-safe providers
  - [ ] Add hero animations between screens for cards
  - [x] Better styling/theme
  - [ ] Additional optional themes (blue and red, white and gold, etc.). Custom themes?
- [ ] **Rest timer**
- [ ] **Add progress page**
- [ ] **Workout summary**
- [ ] **Determine best option cloud storage (Firebase?, API?)**
- [ ] **Implement backend service**
- [ ] **Add unit tests for all pages**
  - [ ] Add WorkoutService unit tests
  - [x] Add ExerciseRepository unit tests
- [ ] **Add automated UI testing**
- [ ] **Public exercise library**
  - [ ] Allow users to publish custom exercises to public library
  - [ ] Allow users to import exercises from public library
  - [ ] Add exercise discovery/search in public library
- [ ] **Public program library**

## Next Steps Priority

1. **Integrate WorkoutService with existing UI** - Update your workout_screen.dart to use the new service
1. **Test the auto-save functionality** - Verify it works in real usage
1. **Implement Hive for persistent storage** - Replace in-memory storage with real persistence
1. **Add rest timer functionality** - Now that saving is handled, focus on UX feature
