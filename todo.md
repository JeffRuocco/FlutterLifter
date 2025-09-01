# TODO

- [X] **Add logging service**
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
- [ ] **Rest timer**
- [ ] **Workout summary**
- [ ] **Add Hive for local storage (all platforms)**
  - [ ] Add hive dependencies to pubspec.yaml
  - [ ] Implement HiveStorageService
  - [ ] Update ServiceLocator to use Hive
  - [ ] Test storage persistence in PWA
- [ ] **Start program functionality**
  - [ ] Start new program and end any previous ones
- [ ] **Create exercises page**
- [ ] **Create progress page**
- [ ] **Create program creation pages**
- [ ] **Implement user authentication**
- [ ] **Add unit tests for all pages**
  - [ ] Add WorkoutService unit tests
- [ ] **Decide on API vs. Firebase**

## Next Steps Priority

1. **Integrate WorkoutService with existing UI** - Update your workout_screen.dart to use the new service
2. **Test the auto-save functionality** - Verify it works in real usage
3. **Add rest timer functionality** - Now that saving is handled, focus on UX features
4. **Implement Hive for persistent storage** - Replace in-memory storage with real persistence