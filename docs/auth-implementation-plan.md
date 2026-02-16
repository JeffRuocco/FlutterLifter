# Authentication Implementation Plan

## Overview

**Goal**: Implement user authentication with Firebase Auth supporting Email/Password, Google Sign-In, and guest mode (skip login).

**Architecture**:
- **Auth Provider**: Firebase Authentication
- **Sign-In Methods**: Email/Password, Google Sign-In
- **Guest Mode**: Local-only usage without Firebase auth; guest data persists and migrates when user creates an account
- **State Management**: Riverpod `Notifier` API (consistent with existing patterns)
- **Navigation Guards**: GoRouter `redirect` + `refreshListenable` for auth-aware routing
- **Email Verification**: Deferred — allow immediate access after signup, prompt for verification later

**Deferred Items** (out of scope, tracked as follow-up):
- Facebook Sign-In
- Apple Sign-In (required if shipping to iOS App Store with social logins)
- Per-user storage key migration (Hive keys remain global; single-user device assumption)
- Guest-to-account cloud data migration (uploading existing local data to Firestore when guest signs up)
- Email verification enforcement

---

## Phase 0: Firebase Project Setup

**Goal**: Create and configure a real Firebase project from scratch, replacing the demo/placeholder credentials.

### Firebase Console Setup

- [x] Go to [Firebase Console](https://console.firebase.google.com/) and create a new project (or use existing)
  - Project name: `FlutterLifter` (or preferred name)
  - Enable Google Analytics (optional)
- [x] Enable **Authentication** in the Firebase Console
  - [x] Go to Authentication → Sign-in method
  - [x] Enable **Email/Password** provider
  - [x] Enable **Google** provider
    - [x] Configure OAuth consent screen in [Google Cloud Console](https://console.cloud.google.com/)
    - [x] Note the Web Client ID for `auth_config.dart`
- [x] Register app platforms in Firebase Console:
  - [x] **Web** — Add web app, copy config
  - [ ] **Android** — Register with package name `com.example.flutter_lifter` (or actual package name)
    - [ ] Download `google-services.json` → place in `android/app/`
    - [ ] Add SHA-1 fingerprint for Google Sign-In (`keytool -list -v -keystore ~/.android/debug.keystore`)
  - [ ] **iOS** — Register with bundle ID
    - [ ] Download `GoogleService-Info.plist` → place in `ios/Runner/`
  - [ ] **Windows** — Not supported by Firebase Auth natively (web fallback)

### FlutterFire CLI Configuration

- [ ] Install FlutterFire CLI (if not already installed):
  ```bash
  dart pub global activate flutterfire_cli
  ```
- [ ] Run configuration from project root:
  ```bash
  flutterfire configure --project=your-firebase-project-id
  ```
  - This regenerates `lib/firebase_options.dart` with real credentials
  - Automatically configures platform-specific files
- [ ] Verify `lib/firebase_options.dart` no longer contains `demo-api-key` or `flutter-lifter-demo`

### Google Sign-In Platform Setup

- [ ] **Android**: 
  - [ ] Add SHA-1 and SHA-256 fingerprints to Firebase Console → Project Settings → Android app
  - [ ] `google-services.json` is auto-updated by FlutterFire CLI
- [ ] **iOS**:
  - [ ] Add `GoogleService-Info.plist` to Xcode project
  - [ ] Add URL scheme to `ios/Runner/Info.plist` (reversed client ID from `GoogleService-Info.plist`)
- [ ] **Web**:
  - [ ] Google Sign-In works automatically with Firebase web config
  - [ ] Ensure authorized domains include `localhost` and deployment domain (`jeffruocco.github.io`)

### Verify Setup
- [ ] App builds successfully: `flutter build web --release`
- [ ] Firebase initializes without errors at runtime
- [ ] No `demo-api-key` references remain in codebase

---

## Phase 1: Dependencies

**Goal**: Add Firebase Auth and Google Sign-In packages.

### Add Dependencies
- [ ] Add to `pubspec.yaml` dependencies:
  ```yaml
  firebase_auth: ^5.5.3
  google_sign_in: ^6.2.1
  ```
- [ ] Run `flutter pub get`
- [ ] Verify `flutter analyze` passes with new dependencies

### Files Modified
- `pubspec.yaml`

---

## Phase 2: Models & Configuration

**Goal**: Create the user model and expand auth configuration enums.

### AppUser Model
- [ ] Create `lib/models/app_user.dart`
  ```dart
  class AppUser {
    final String uid;
    final String? email;
    final String? displayName;
    final String? photoURL;
    final AuthProvider authProvider;
    final DateTime createdAt;
    
    bool get isGuest => authProvider == AuthProvider.guest;
    
    // Factory constructors:
    factory AppUser.fromFirebaseUser(User user)
    factory AppUser.guest()  // uid: 'guest', provider: AuthProvider.guest
    
    // Serialization:
    Map<String, dynamic> toJson()
    factory AppUser.fromJson(Map<String, dynamic> json)
    AppUser copyWith(...)
  }
  ```
- [ ] Guest user uses deterministic UID `'guest'` (no Firebase call)

### Update AuthConfig
- [ ] Update `lib/config/auth_config.dart`:
  - [ ] Add `AuthProvider` enum: `email`, `google`, `guest`
  - [ ] Expand `AuthResult` enum with: `emailAlreadyInUse`, `weakPassword`, `userNotFound`, `tooManyRequests`
  - [ ] Update `googleClientId` placeholder comment
  - [ ] Remove `facebookAppId` placeholder (not implementing)

### Files Created
- `lib/models/app_user.dart`

### Files Modified
- `lib/config/auth_config.dart`

---

## Phase 3: Auth Service

**Goal**: Create the authentication service wrapping Firebase Auth operations.

### AuthService Implementation
- [ ] Create `lib/services/auth_service.dart`
  - [ ] Constructor accepts `FirebaseAuth` instance (injectable for testing)
  - [ ] Methods:
    ```dart
    Stream<User?> get authStateChanges
    User? get currentUser
    
    Future<AuthResult> signInWithEmail(String email, String password)
    Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName})
    Future<AuthResult> signInWithGoogle()
    Future<void> signOut()
    Future<AuthResult> sendPasswordResetEmail(String email)
    ```
  - [ ] Error handling: catch `FirebaseAuthException`, map error codes to `AuthResult`:
    | Firebase Error Code | AuthResult |
    |-------------------|------------|
    | `wrong-password` | `invalidCredentials` |
    | `user-not-found` | `userNotFound` |
    | `email-already-in-use` | `emailAlreadyInUse` |
    | `weak-password` | `weakPassword` |
    | `network-request-failed` | `networkError` |
    | `too-many-requests` | `tooManyRequests` |
    | `user-disabled` | `failed` |
    | (other) | `failed` |
  - [ ] Google Sign-In flow:
    1. `GoogleSignIn().signIn()` → get `GoogleSignInAccount`
    2. Get `GoogleSignInAuthentication` (idToken + accessToken)
    3. Create `GoogleAuthProvider.credential(idToken, accessToken)`
    4. `FirebaseAuth.signInWithCredential(credential)`
    5. Return `AuthResult.success` or handle cancellation/errors
  - [ ] `signOut()` calls both `FirebaseAuth.signOut()` and `GoogleSignIn().signOut()`

### Files Created
- `lib/services/auth_service.dart`

---

## Phase 4: Riverpod Providers

**Goal**: Create auth state management using the modern Notifier API pattern.

### Auth Providers
- [ ] Create `lib/core/providers/auth_providers.dart`
  - [ ] `authServiceProvider` — `Provider<AuthService>`:
    ```dart
    final authServiceProvider = Provider<AuthService>((ref) {
      return AuthService(FirebaseAuth.instance);
    });
    ```
  - [ ] `authStateChangesProvider` — `StreamProvider<User?>`:
    ```dart
    final authStateChangesProvider = StreamProvider<User?>((ref) {
      return ref.watch(authServiceProvider).authStateChanges;
    });
    ```
  - [ ] `authNotifierProvider` — `NotifierProvider<AuthNotifier, AuthState>`:
    ```dart
    class AuthNotifier extends Notifier<AuthState> {
      @override
      AuthState build() {
        // Listen to Firebase auth state changes
        final authState = ref.watch(authStateChangesProvider);
        return authState.when(
          data: (user) => user != null ? AuthState.authenticated : AuthState.unauthenticated,
          loading: () => AuthState.loading,
          error: (_, __) => AuthState.unauthenticated,
        );
      }
      
      // Guest mode: local state flag, no Firebase call
      bool _isGuest = false;
      bool get isGuest => _isGuest;
      
      Future<AuthResult> signInWithEmail(String email, String password) async { ... }
      Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName}) async { ... }
      Future<AuthResult> signInWithGoogle() async { ... }
      Future<void> signOut() async { ... }
      void continueAsGuest() { ... }  // Sets _isGuest = true, state = authenticated
    }
    ```
  - [ ] `currentUserProvider` — `Provider<AppUser?>`:
    - Derives from `authStateChangesProvider` + guest state
    - Maps `firebase_auth.User` → `AppUser.fromFirebaseUser(user)`
    - Returns `AppUser.guest()` when in guest mode
  - [ ] `isGuestProvider` — `Provider<bool>`:
    - Derives from `currentUserProvider`
    - Returns `currentUser?.isGuest ?? false`

- [ ] Export in `lib/core/providers/providers.dart`:
  ```dart
  export 'auth_providers.dart';
  ```

### Files Created
- `lib/core/providers/auth_providers.dart`

### Files Modified
- `lib/core/providers/providers.dart`

---

## Phase 5: Router Auth Guards

**Goal**: Protect app routes behind authentication and handle login/signup routing.

### GoRouter Redirect
- [ ] Update `routerProvider` in `lib/core/router/app_router.dart`:
  - [ ] Create `AuthNotifierListenable` class that adapts Riverpod → `Listenable` for GoRouter's `refreshListenable`:
    ```dart
    class AuthNotifierListenable extends ChangeNotifier {
      AuthNotifierListenable(Ref ref) {
        ref.listen(authNotifierProvider, (_, __) => notifyListeners());
      }
    }
    ```
  - [ ] Add `refreshListenable: AuthNotifierListenable(ref)` to `GoRouter`
  - [ ] Add `redirect` callback:
    ```dart
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      
      if (authState == AuthState.unauthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (authState == AuthState.authenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    ```

### Add Signup Route
- [ ] Add `signup` to `AppRoutes`:
  ```dart
  static const String signup = '/signup';
  ```
- [ ] Add signup route definition (outside shell, fade transition, same pattern as login)
- [ ] Add `goToSignup()` / `pushSignup()` to `AppRouterExtension`

### Files Modified
- `lib/core/router/app_router.dart`

---

## Phase 6: Login Screen Updates

**Goal**: Wire the existing login screen to real Firebase Auth and add guest mode.

### Convert to ConsumerStatefulWidget
- [ ] Update `lib/screens/login_screen.dart`:
  - [ ] Change `StatefulWidget` → `ConsumerStatefulWidget`
  - [ ] Change `State<LoginScreen>` → `ConsumerState<LoginScreen>`
  - [ ] Remove `_fakeSignIn()` method entirely

### Wire Auth Methods
- [ ] `_signInWithEmail()`:
  ```dart
  final result = await ref.read(authNotifierProvider.notifier).signInWithEmail(email, password);
  if (result != AuthResult.success) {
    setState(() => _errorMessage = _getErrorMessage(result));
  }
  // No manual navigation — router redirect handles it
  ```
- [ ] `_signInWithGoogle()`:
  ```dart
  final result = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  if (result == AuthResult.cancelled) return;
  if (result != AuthResult.success) {
    setState(() => _errorMessage = _getErrorMessage(result));
  }
  ```
- [ ] Add error message display (inline text above Sign In button or below form)
- [ ] Add `_getErrorMessage(AuthResult result)` helper mapping enum to user-friendly strings

### Update Social Login Buttons
- [ ] Keep Google Sign-In button (functional)
- [ ] Remove Facebook and Apple buttons from the UI (or show disabled with "Coming soon" tooltip)

### Add Guest Mode
- [ ] Add "Continue as Guest" button below the social login section / divider:
  ```dart
  TextButton(
    onPressed: () => ref.read(authNotifierProvider.notifier).continueAsGuest(),
    child: Text('Continue as Guest'),
  )
  ```
- [ ] Small subtitle text: "Your data stays on this device"

### Forgot Password
- [ ] Wire "Forgot Password?" button to show a dialog:
  - Email input field
  - "Send Reset Email" button → `authService.sendPasswordResetEmail(email)`
  - Success: show snackbar "Password reset email sent"
  - Error: show error message

### Wire Sign Up Link
- [ ] Change "Sign Up" button `onPressed` to `context.go(AppRoutes.signup)`

### Files Modified
- `lib/screens/login_screen.dart`

---

## Phase 7: Signup Screen

**Goal**: Create a separate registration screen with name, email, password, and confirm password.

### Screen Implementation
- [ ] Create `lib/screens/signup_screen.dart`:
  - [ ] `ConsumerStatefulWidget` with `ConsumerState`
  - [ ] Form fields:
    - Display Name (`AppTextFormField`, icon: `strokeRoundedUser`)
    - Email (`AppTextFormField`, icon: `strokeRoundedMail01`)
    - Password (`AppTextFormField`, obscured, icon: `strokeRoundedLockPassword`)
    - Confirm Password (`AppTextFormField`, obscured, icon: `strokeRoundedLockPassword`)
  - [ ] Form validation:
    - Display name: required, not empty
    - Email: required, valid format (reuse `emailRegex` from login)
    - Password: required, min 6 characters
    - Confirm password: must match password field
  - [ ] Submit button ("Create Account", `AppButton.gradient`)
  - [ ] On submit: `authNotifier.signUpWithEmail(email, password, displayName: name)`
  - [ ] Error handling for `AuthResult`:
    - `emailAlreadyInUse` → "An account with this email already exists"
    - `weakPassword` → "Password is too weak. Use at least 6 characters"
    - `networkError` → "No internet connection. Please try again"
  - [ ] "Already have an account? Sign In" link → `context.go(AppRoutes.login)`
  - [ ] Visual style: match login screen (gradient background, animated logo, staggered animations)

### Files Created
- `lib/screens/signup_screen.dart`

---

## Phase 8: Settings Screen — Account Section

**Goal**: Add account management UI to the settings screen.

### Account Section
- [ ] Update `lib/screens/settings_screen.dart`:
  - [ ] Add "Account" section at the **top** of settings (before "Appearance"):
    - [ ] **Authenticated users**: Show user avatar/icon, display name, email, auth provider badge
    - [ ] **Guest users**: Show "Guest Mode" with message "Your data is stored locally on this device" and a prominent "Create Account" button → navigates to `/signup`
  - [ ] Add "Sign Out" tile in the Account section:
    - [ ] Show confirmation dialog: "Are you sure you want to sign out?"
    - [ ] On confirm: `ref.read(authNotifierProvider.notifier).signOut()`
    - [ ] Navigation handled automatically by router redirect
  - [ ] For guest users, show "Sign In" instead of "Sign Out" → navigates to `/login`

### Files Modified
- `lib/screens/settings_screen.dart`

---

## Phase 9: Testing

**Goal**: Ensure all existing tests pass and add new tests for auth functionality.

### Update Existing Tests
- [ ] Update `test/widget_test.dart`:
  - [ ] Override `authNotifierProvider` with `AuthState.unauthenticated` (or use mock)
  - [ ] Account for the login screen now being a `ConsumerStatefulWidget`
  - [ ] Ensure all existing assertions still pass

### New Unit Tests
- [ ] Create `test/services/auth_service_test.dart`:
  - [ ] Test `signInWithEmail` success → returns `AuthResult.success`
  - [ ] Test `signInWithEmail` wrong password → returns `AuthResult.invalidCredentials`
  - [ ] Test `signInWithEmail` user not found → returns `AuthResult.userNotFound`
  - [ ] Test `signUpWithEmail` success → returns `AuthResult.success`
  - [ ] Test `signUpWithEmail` duplicate email → returns `AuthResult.emailAlreadyInUse`
  - [ ] Test `signUpWithEmail` weak password → returns `AuthResult.weakPassword`
  - [ ] Test `signOut` calls both Firebase and Google sign out
  - [ ] Test `sendPasswordResetEmail` success and failure
  - [ ] Test error code → `AuthResult` mapping for all known codes
  - [ ] Use mock `FirebaseAuth` (manual mock or `firebase_auth_mocks` package)

### New Widget Tests
- [ ] Create `test/screens/login_screen_test.dart`:
  - [ ] Test form validation: empty email shows error
  - [ ] Test form validation: invalid email format shows error
  - [ ] Test form validation: password too short shows error
  - [ ] Test sign-in button calls auth provider
  - [ ] Test "Continue as Guest" calls `continueAsGuest()`
  - [ ] Test Google Sign-In button triggers auth
  - [ ] Test error message displays on failed auth
  - [ ] Test "Sign Up" link navigates to signup route

- [ ] Create `test/screens/signup_screen_test.dart`:
  - [ ] Test form validation: empty display name
  - [ ] Test form validation: password mismatch shows error
  - [ ] Test successful registration calls `signUpWithEmail`
  - [ ] Test "Sign In" link navigates to login route
  - [ ] Test error display for duplicate email

### Verification Commands
- [ ] `flutter analyze --fatal-infos` — zero errors/warnings
- [ ] `dart format --output=none --set-exit-if-changed .` — zero changes needed
- [ ] `flutter test --coverage` — all tests pass (existing + new)
- [ ] `flutter build web --release --base-href "/FlutterLifter/"` — builds successfully

---

## Phase 10: Documentation Updates

**Goal**: Update existing docs to reflect implemented authentication.

### Files to Update
- [ ] Update `docs/authentication.md`:
  - [ ] Mark "Backend Integration" items as completed
  - [ ] Document actual auth flow (Email + Google + Guest)
  - [ ] Remove Facebook/Apple from "completed" status (they're deferred)
  - [ ] Add troubleshooting section for common auth issues
- [ ] Update `docs/design-guidelines.md`:
  - [ ] Verify `auth_providers.dart` reference is accurate (file now exists)
- [ ] Update `todo.md`:
  - [ ] Mark "Implement user authentication" as complete
  - [ ] Add follow-up items to incremental updates section

---

## Manual Testing Checklist

**After implementation, verify ALL of these scenarios:**

### Login Flow
- [ ] Launch app → login screen appears
- [ ] Email/password validation works (empty, invalid email, short password)
- [ ] Sign in with valid email/password → navigated to home
- [ ] Sign in with wrong password → error message displayed
- [ ] Sign in with Google → Google picker appears → navigated to home
- [ ] "Continue as Guest" → navigated to home, full app usable
- [ ] "Forgot Password?" → dialog appears → email sent on valid email
- [ ] "Sign Up" link → navigated to signup screen

### Signup Flow
- [ ] All form validations work (empty name, invalid email, short password, password mismatch)
- [ ] Successful registration → navigated to home
- [ ] Duplicate email → error message "account already exists"
- [ ] "Sign In" link → navigated back to login

### Auth Guards
- [ ] Authenticated user visiting `/login` → redirected to home
- [ ] Unauthenticated user visiting `/` → redirected to login
- [ ] Guest user can access all app routes
- [ ] Sign out from any screen → redirected to login

### Settings / Account
- [ ] Authenticated: shows email, display name, auth provider
- [ ] Guest: shows "Guest Mode" with "Create Account" button
- [ ] "Sign Out" with confirmation → redirected to login
- [ ] Guest "Create Account" → navigated to signup

### Visual / Accessibility
- [ ] Login screen renders correctly in **light mode**
- [ ] Login screen renders correctly in **dark mode**
- [ ] Signup screen renders correctly in both modes
- [ ] Error messages are visible and readable
- [ ] All buttons have adequate contrast
- [ ] Form fields are accessible via keyboard/tab navigation

### Data Persistence
- [ ] Guest creates workout → data persists after app restart
- [ ] Guest signs up → existing local data is still accessible
- [ ] Sign out → sign back in → data is still accessible
- [ ] Different user signs in → sees fresh state (single-device assumption for now)

---

## Follow-Up Items (Out of Scope)

These items are explicitly deferred and should be tracked separately:

### High Priority Follow-Ups
- [ ] **Per-user storage key migration** — Migrate Hive storage keys from global (`custom_exercises`) to per-user (`custom_exercises_{userId}`) format. Required before multi-user device support. Reference: `lib/data/datasources/local/exercise_local_datasource.dart` TODO comment.
- [ ] **Guest-to-account cloud data migration** — When a guest user creates an account, upload their existing Hive data to Firestore. Required before cloud sync feature (Phase 3+ of `storage-implementation-plan.md`).
- [ ] **Email verification prompting** — After signup, prompt users to verify their email. Don't block access, but show a dismissible banner or settings indicator. Consider restricting cloud sync to verified emails only.

### Medium Priority Follow-Ups
- [ ] **Apple Sign-In** — Required by Apple App Store policy if other social login providers are offered. Add `sign_in_with_apple` package. Configure in Apple Developer Console.
- [ ] **Facebook Sign-In** — Add `flutter_facebook_auth` package. Configure Facebook Developer Console app.
- [ ] **Account deletion** — GDPR/privacy requirement. Allow users to delete their account and all associated data (local + cloud).
- [ ] **Profile editing** — Allow users to update display name and profile photo.
- [ ] **Re-authentication** — Require re-authentication for sensitive operations (account deletion, email change, password change).

### Low Priority Follow-Ups
- [ ] **Biometric authentication** — Optional fingerprint/face unlock for quick app access.
- [ ] **Session timeout** — Auto-sign-out after configurable inactivity period (uses `AuthConfig.sessionTimeout`).
- [ ] **Auth analytics** — Track sign-up method distribution, login success/failure rates via Firebase Analytics.
- [ ] **Link accounts** — Allow users to link multiple auth providers (e.g., email + Google) to the same account.

---

## File Inventory

### New Files
| File | Description |
|------|-------------|
| `lib/models/app_user.dart` | User model with Firebase mapping and guest factory |
| `lib/services/auth_service.dart` | Firebase Auth wrapper service |
| `lib/core/providers/auth_providers.dart` | AuthNotifier, auth stream, current user providers |
| `lib/screens/signup_screen.dart` | Separate registration screen |
| `test/services/auth_service_test.dart` | Auth service unit tests |
| `test/screens/login_screen_test.dart` | Login screen widget tests |
| `test/screens/signup_screen_test.dart` | Signup screen widget tests |

### Modified Files
| File | Changes |
|------|---------|
| `pubspec.yaml` | Add `firebase_auth`, `google_sign_in` |
| `lib/firebase_options.dart` | Regenerated by FlutterFire CLI |
| `lib/config/auth_config.dart` | Expand enums, add `AuthProvider` |
| `lib/core/providers/providers.dart` | Export `auth_providers.dart` |
| `lib/core/router/app_router.dart` | Add redirect guard, refreshListenable, signup route |
| `lib/screens/login_screen.dart` | Convert to ConsumerStatefulWidget, wire real auth, add guest mode |
| `lib/screens/settings_screen.dart` | Add Account section with sign-out |
| `test/widget_test.dart` | Override auth providers for testing |
| `docs/authentication.md` | Update status to reflect implementation |
| `todo.md` | Mark auth task complete, add follow-ups |

### Unchanged Files
| File | Notes |
|------|-------|
| `lib/main.dart` | Firebase already initializes here; no changes needed |
| `lib/services/storage_service.dart` | Per-user key migration is a follow-up |
| `lib/data/datasources/local/*` | Per-user key migration is a follow-up |

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-16 | Email/Password + Google Sign-In only | Simplest viable set; Facebook/Apple deferred |
| 2026-02-16 | Guest mode with local state (no Firebase Anonymous Auth) | Simpler, no Firebase cost, guest data stays local |
| 2026-02-16 | Guest UID = `'guest'` (deterministic) | No Firebase call needed, consistent local state |
| 2026-02-16 | Separate signup screen (not inline toggle) | Per user preference; cleaner UX for registration flow |
| 2026-02-16 | Allow immediate access after signup (no email verification gate) | Better UX; email verification prompting added as follow-up |
| 2026-02-16 | No `flutter_secure_storage` | Firebase Auth handles token persistence internally |
| 2026-02-16 | Per-user storage keys deferred | Single-user device assumption for now; needed before cloud sync |
| 2026-02-16 | GoRouter redirect for auth guards | Declarative, consistent with existing GoRouter patterns |
| 2026-02-16 | `AuthNotifierListenable` adapter | Bridges Riverpod → Listenable for GoRouter `refreshListenable` |

---

## Estimated Timeline

| Phase | Description | Estimated Time |
|-------|-------------|---------------|
| Phase 0 | Firebase Project Setup | 30-60 min |
| Phase 1 | Dependencies | 5 min |
| Phase 2 | Models & Config | 30 min |
| Phase 3 | Auth Service | 1-2 hours |
| Phase 4 | Riverpod Providers | 1-2 hours |
| Phase 5 | Router Auth Guards | 30-60 min |
| Phase 6 | Login Screen Updates | 1-2 hours |
| Phase 7 | Signup Screen | 1-2 hours |
| Phase 8 | Settings Account Section | 30-60 min |
| Phase 9 | Testing | 2-3 hours |
| Phase 10 | Documentation | 30 min |
| **Total** | | **8-14 hours** |
