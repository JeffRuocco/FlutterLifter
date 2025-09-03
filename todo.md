# TODO

- [x] **Add logging service**
  - [ ] **Connect Firebase logging**
- [ ] **Add exercise repository**
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
- [ ] **Workout complete validation (warn about incomplete)**
  - [ ] Warn about finishing workout before completing all sets (✅ WorkoutService ready)
  - [ ] Warn about leaving workout page with sets recorded, but not marked complete (✅ WorkoutService ready)
- [ ] **Add Hive for local storage (all platforms)**
  - [ ] Add hive dependencies to pubspec.yaml
  - [ ] Implement HiveStorageService
  - [ ] Update ServiceLocator to use Hive
  - [ ] Test storage persistence in PWA
- [ ] **Rest timer**
- [ ] **Workout summary**
- [ ] **Start program functionality**
  - [ ] Start new program and end any previous ones
- [ ] **Add exercises page**
- [ ] **Add progress page**
- [ ] **Add program creation pages**
- [ ] **Implement user authentication**
- [ ] **Add unit tests for all pages**
  - [ ] Add WorkoutService unit tests
- [ ] **Decide on API vs. Firebase**
- [ ] **Implement backend service**

## Next Steps Priority

1. **Integrate WorkoutService with existing UI** - Update your workout_screen.dart to use the new service
1. **Test the auto-save functionality** - Verify it works in real usage
1. **Implement Hive for persistent storage** - Replace in-memory storage with real persistence
1. **Add rest timer functionality** - Now that saving is handled, focus on UX features