# Storage Implementation Plan

## Overview

**Goal**: Implement offline-first local storage using Hive with Firebase (Firestore + Storage) for cloud sync.

**Architecture**:
- **Local Storage**: Hive as source of truth (offline-first)
- **Cloud Database**: Firestore with hybrid schema (nested programs, subcollection for workout sessions)
- **Cloud Storage**: Firebase Storage for exercise photos
- **Sync Strategy**: Periodic (5 min) + app lifecycle events, user-prompted conflict resolution
- **Auth**: Disabled until auth feature is implemented

---

## Phase 1: Hive Local Storage ✅

**Goal**: Replace in-memory storage with persistent Hive storage. App works fully offline after this phase.

**Status**: COMPLETED (2026-01-11)

### Dependencies
- [x] Add `hive: ^2.2.3` to pubspec.yaml
- [x] Add `hive_flutter: ^1.1.0` to pubspec.yaml
- [x] Run `flutter pub get`

### Initialization
- [x] Initialize Hive in `main.dart` before `runApp()`
  ```dart
  await Hive.initFlutter();
  ```
- [x] Register Hive boxes:
  - [x] `programs` - Program data with nested cycles
  - [x] `customExercises` - User-created exercises
  - [x] `userPreferences` - Exercise preferences (sets, reps, notes, photos)
  - [x] `exerciseHistory` - Historical workout data per exercise
  - [x] `syncMetadata` - Sync state tracking (for Phase 3)

### HiveStorageService
- [x] Complete `HiveStorageService` implementation in `lib/services/storage_service.dart`
  - [x] `init()` - Open all boxes
  - [x] `store<T>(key, value)` - Store JSON-encoded data
  - [x] `retrieve<T>(key)` - Retrieve and decode JSON data
  - [x] `remove(key)` - Delete entry
  - [x] `clear()` - Clear all boxes
  - [x] `containsKey(key)` - Check existence
  - [x] `getAllKeys()` - List all keys
- [x] Add box-specific helper methods for typed access
- [x] Add batch operation support for efficiency

### Update DataSources
- [x] Update `ProgramLocalDataSourceImpl` in `lib/data/datasources/local/program_local_datasource.dart`
  - [x] Replace in-memory `_programsCache` Map with Hive box operations
  - [x] Use existing `toJson()`/`fromJson()` for serialization
  - [x] Added `InMemoryProgramLocalDataSource` for testing
- [x] Update `ExerciseLocalDataSourceImpl` in `lib/data/datasources/local/exercise_local_datasource.dart`
  - [x] Replace in-memory `_customExercises` Map with Hive box operations
  - [x] Replace in-memory `_preferences` Map with Hive box operations
  - [x] Renamed in-memory version to `InMemoryExerciseLocalDataSource` for testing

### Update Providers
- [x] Update `storageServiceProvider` in `lib/core/providers/storage_provider.dart` to use `HiveStorageService`
- [x] Ensure `storageInitProvider` properly awaits Hive initialization

### Testing
- [x] All 268 tests pass
- [ ] Test data persists after app restart (hot restart doesn't count)
- [ ] Test on Android
- [ ] Test on iOS (simulator)
- [ ] Test on Web (PWA) - Hive uses IndexedDB
- [ ] Test on Windows desktop
- [ ] Verify no data loss during normal usage

---

## Phase 2: Firebase Setup

**Goal**: Add Firebase dependencies and configure Firestore/Storage. No sync logic yet.

### Dependencies
- [ ] Add `cloud_firestore: ^5.6.8` to pubspec.yaml
- [ ] Add `firebase_storage: ^12.4.4` to pubspec.yaml
- [ ] Add `firebase_auth: ^5.5.3` to pubspec.yaml
- [ ] Run `flutter pub get`

### Firebase Console Configuration
- [ ] Enable Firestore in Firebase Console
  - [ ] Select production mode (with security rules)
  - [ ] Choose region (us-central1 recommended)
- [ ] Enable Firebase Storage in Firebase Console
  - [ ] Set storage rules for authenticated users
- [ ] Enable Authentication providers (for future)
  - [ ] Email/Password
  - [ ] Google Sign-In (optional)
  - [ ] Apple Sign-In (optional, required for iOS)

### Security Rules
- [ ] Configure Firestore security rules:
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```
- [ ] Configure Storage security rules:
  ```
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /users/{userId}/{allPaths=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```

### Verify Setup
- [ ] App builds successfully with new dependencies
- [ ] Firebase initializes without errors
- [ ] No runtime crashes on any platform

---

## Phase 3: Sync Infrastructure

**Goal**: Create the sync service architecture without actual Firestore operations. Tracks changes locally.

### SyncMetadata Model
- [ ] Create `lib/models/sync_metadata.dart`
  ```dart
  class SyncMetadata {
    final String id;
    final String collectionType; // 'programs', 'exercises', etc.
    final String documentId;
    final SyncOperation operation; // create, update, delete
    final DateTime localTimestamp;
    final DateTime? remoteTimestamp;
    final Map<String, dynamic> data;
    final SyncStatus status; // pending, syncing, synced, conflict, failed
  }
  
  enum SyncOperation { create, update, delete }
  enum SyncStatus { pending, syncing, synced, conflict, failed }
  ```
- [ ] Add `toJson()`/`fromJson()` methods
- [ ] Store in `syncMetadata` Hive box

### SyncService
- [ ] Create `lib/services/sync_service.dart`
  - [ ] Track pending changes with `SyncMetadata`
  - [ ] Queue changes when data is modified locally
  - [ ] `// TODO: Enable sync prompt once auth is implemented` placeholder for sign-in trigger
- [ ] Implement periodic sync timer (5 minutes)
  ```dart
  Timer.periodic(Duration(minutes: 5), (_) => _syncIfNeeded());
  ```
- [ ] Implement `WidgetsBindingObserver` for app lifecycle
  - [ ] Sync on `AppLifecycleState.paused`
  - [ ] Sync on `AppLifecycleState.inactive`
  - [ ] Resume sync timer on `AppLifecycleState.resumed`

### Conflict Resolution UI
- [ ] Create `lib/widgets/sync_conflict_dialog.dart`
  - [ ] Show local vs remote data comparison
  - [ ] Options: "Keep Local", "Keep Remote", "Merge" (where applicable)
  - [ ] Display timestamps for both versions
- [ ] Create `lib/models/sync_conflict.dart` to represent conflicts

### Integration Points
- [ ] Add `SyncService` to providers in `lib/core/providers/`
- [ ] Hook DataSource write operations to queue sync metadata
  - [ ] `ProgramLocalDataSourceImpl.cacheProgram()` → queue sync
  - [ ] `ExerciseLocalDataSourceImpl.cacheCustomExercise()` → queue sync
  - [ ] `ExerciseLocalDataSourceImpl.cachePreference()` → queue sync

### Testing
- [ ] Verify changes are queued in `syncMetadata` box
- [ ] Verify timer fires every 5 minutes
- [ ] Verify lifecycle sync triggers on app background
- [ ] Test conflict dialog UI renders correctly

---

## Phase 4: Firestore Integration

**Goal**: Implement actual Firestore sync operations using the infrastructure from Phase 3.

### Firestore Schema
Document the hybrid schema:
```
users/{uid}/
├── programs/{programId}
│   ├── id, name, description, createdAt, updatedAt
│   ├── cycles: [{ nested ProgramCycle objects }]
│   └── workoutSessions/ (subcollection)
│       └── {sessionId}
│           ├── id, date, status, completedAt
│           └── exercises: [{ nested WorkoutExercise }]
├── customExercises/{exerciseId}
│   └── { Exercise fields }
└── preferences/{exerciseId}
    └── { UserExercisePreferences fields }
```

### FirestoreDataSource
- [ ] Create `lib/data/datasources/remote/firestore_datasource.dart`
  - [ ] `uploadProgram(userId, program)` - Create/update program doc
  - [ ] `uploadWorkoutSession(userId, programId, session)` - Write to subcollection
  - [ ] `uploadCustomExercise(userId, exercise)`
  - [ ] `uploadPreferences(userId, preferences)`
  - [ ] `downloadPrograms(userId)` - Fetch all user programs
  - [ ] `downloadWorkoutSessions(userId, programId)`
  - [ ] `downloadCustomExercises(userId)`
  - [ ] `downloadPreferences(userId)`
  - [ ] `deleteDocument(path)`

### SyncService Firestore Operations
- [ ] Implement `_syncPendingChanges()` in SyncService
  - [ ] Process queue by `localTimestamp` order
  - [ ] Handle create/update/delete operations
  - [ ] Update `SyncStatus` after each operation
  - [ ] Handle network errors gracefully (retry queue)
- [ ] Implement `_checkForRemoteChanges()`
  - [ ] Compare local vs remote `updatedAt` timestamps
  - [ ] Detect conflicts when both have changed
  - [ ] Trigger conflict resolution dialog when needed
- [ ] Implement conflict resolution handlers
  - [ ] `_keepLocal()` - Push local to remote
  - [ ] `_keepRemote()` - Pull remote to local
  - [ ] `_merge()` - Field-level merge where possible

### Initial Sync (First-time / New Device)
- [ ] Implement `performInitialSync(userId)`
  - [ ] Download all remote data
  - [ ] Merge with any local data (prompt on conflicts)
  - [ ] Mark all as synced

### Testing
- [ ] Test create sync (local → remote)
- [ ] Test update sync (local → remote)
- [ ] Test delete sync (local → remote)
- [ ] Test download (remote → local)
- [ ] Test conflict detection and resolution
- [ ] Test offline queue → online sync
- [ ] Test sync on app close

---

## Phase 5: Firebase Storage for Photos

**Goal**: Complete photo cloud sync using Firebase Storage.

### PhotoStorageService Cloud Methods
- [ ] Complete `uploadToCloud()` in `lib/services/photo_storage_service.dart`
  ```dart
  Future<String?> uploadToCloud(String localPath, String exerciseId) async {
    // Path: users/{uid}/exercise_photos/{exerciseId}/{filename}
    // Return download URL on success
  }
  ```
- [ ] Complete `downloadFromCloud()`
  - [ ] Download to local photos directory
  - [ ] Return local file path
- [ ] Complete `deleteFromCloud()`
- [ ] Complete `syncPendingUploads()`
  - [ ] Process `pendingPhotoUploads` list
  - [ ] Move URLs from pending to `cloudPhotoUrls`
  - [ ] Remove from `localPhotoPaths` after successful upload (optional)

### Integration with SyncService
- [ ] Add photo sync to periodic sync cycle
- [ ] Upload photos in background (don't block UI)
- [ ] Show upload progress indicator (optional)
- [ ] Handle large files gracefully (compress before upload)

### Storage Management
- [ ] Track storage usage per user (Firestore metadata doc)
- [ ] Consider cleanup of local files after cloud upload (optional, save device space)
- [ ] Handle storage quota errors gracefully

### Testing
- [ ] Test photo upload from camera
- [ ] Test photo upload from gallery
- [ ] Test photo sync on new device
- [ ] Test photo delete (local + cloud)
- [ ] Test large photo handling
- [ ] Test upload resume after interruption

---

## Phase 6: Polish & Production Readiness

**Goal**: Ensure robustness, handle edge cases, optimize performance.

### Error Handling
- [ ] Add retry logic with exponential backoff for failed syncs
- [ ] Show user-friendly error messages for sync failures
- [ ] Log sync errors to Firebase Crashlytics
- [ ] Add manual "Sync Now" button in settings

### Performance Optimization
- [ ] Batch Firestore writes where possible
- [ ] Implement incremental sync (only changed documents)
- [ ] Add sync debouncing (don't sync on every keystroke)
- [ ] Lazy load workout sessions (don't fetch all history upfront)

### User Experience
- [ ] Add sync status indicator (synced/syncing/pending/error)
- [ ] Show "Last synced: X minutes ago" in settings
- [ ] Add "Sync in progress" indicator during active sync
- [ ] Handle "no internet" state gracefully

### Data Migration
- [ ] Create migration path from in-memory to Hive (for existing users)
- [ ] Version the Hive schema for future migrations
- [ ] Add schema version to sync metadata

### Testing & Validation
- [ ] Unit tests for SyncService
- [ ] Unit tests for FirestoreDataSource
- [ ] Integration tests for full sync cycle
- [ ] Test with slow/unreliable network
- [ ] Test with large datasets (100+ workouts)
- [ ] Test multi-device sync scenario
- [ ] Load testing for Firestore read/write costs

### Documentation
- [ ] Document sync architecture in `docs/`
- [ ] Document Firestore schema
- [ ] Document conflict resolution behavior
- [ ] Add troubleshooting guide for sync issues

---

## Future Enhancements (Post-MVP)

These items are out of scope for initial implementation but documented for future reference:

- [ ] **Real-time listeners** - Option to enable instant sync for premium users
- [ ] **Selective sync** - Choose which programs to sync to cloud
- [ ] **Export/Import** - Manual backup to JSON file
- [ ] **Shared programs** - Sync programs between users (coach → athlete)
- [ ] **Offline indicator** - Show when app is in offline mode
- [ ] **Sync analytics** - Track sync success/failure rates
- [ ] **Background fetch** - iOS background app refresh for sync
- [ ] **WorkManager** - Android background sync when app is closed

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-11 | Use Hive for local storage | Cross-platform (including Web/PWA), pure Dart, JSON-compatible |
| 2026-01-11 | Firestore for cloud database | Already have Firebase, built-in offline support, fast MVP |
| 2026-01-11 | Firebase Storage for photos | Seamless integration with Firestore, matches auth model |
| 2026-01-11 | Offline-first (Hive as source of truth) | Best UX for workout logging, works without connectivity |
| 2026-01-11 | Periodic sync (5 min) + lifecycle | Balance between data safety and Firestore costs |
| 2026-01-11 | User-prompted conflict resolution | Safest approach, user decides on data conflicts |
| 2026-01-11 | Hybrid Firestore schema | Programs nested, WorkoutSessions as subcollection for frequent updates |
| 2026-01-11 | Auth disabled until ready | Allow local-only usage, add cloud sync when auth is implemented |
