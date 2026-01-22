# FlutterLifter - GitHub Copilot Instructions

**ALWAYS follow these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Project Overview
FlutterLifter is a Flutter mobile application for comprehensive fitness and workout tracking. The app includes features for workout logging, progress tracking, and personalized fitness plans. It supports iOS, Android, and Progressive Web App (PWA) functionality across multiple platforms.

## Working Effectively

### Flutter Installation and Setup
**CRITICAL**: You must install Flutter 3.32.x or compatible version first:

```bash
# Install Flutter (Linux/macOS)
cd /tmp
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz
tar xf flutter_linux_3.32.0-stable.tar.xz
export PATH="$PATH:/tmp/flutter/bin"

# Or use snap (Linux)
snap install flutter --classic

# Verify installation
flutter --version
flutter doctor
```

### Bootstrap and Build the Repository
**ALWAYS run these commands in sequence for a fresh setup:**

```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis - takes 30-60 seconds
flutter analyze --fatal-infos

# 3. Check code formatting - takes 10-15 seconds  
dart format --output=none --set-exit-if-changed .

# 4. Run tests - takes 1-2 minutes. NEVER CANCEL.
flutter test --coverage
```

### Platform-Specific Builds

#### Web Build (Development - Fastest)
```bash
# Quick web build for development - takes 2-3 minutes. NEVER CANCEL.
flutter build web --release --base-href "/FlutterLifter/"

# For local testing without base-href
flutter build web --release
```

#### Android Build (Production)
**Requires Java 17. Build takes 5-10 minutes. NEVER CANCEL. Set timeout to 15+ minutes.**
```bash
# Ensure Java 17 is installed
java -version

# Build APK for multiple architectures - takes 5-10 minutes
flutter build apk --release --split-per-abi

# Build App Bundle for Google Play Store - takes 3-5 minutes  
flutter build appbundle --release

# Artifacts location:
# APK files: build/app/outputs/flutter-apk/*.apk
# App Bundle: build/app/outputs/bundle/release/*.aab
```

#### Windows Build (Production)
**Windows only. Build takes 3-7 minutes. NEVER CANCEL. Set timeout to 10+ minutes.**
```bash
# Build Windows desktop app - takes 3-7 minutes
flutter build windows --release

# Artifacts location: build/windows/x64/runner/Release/
```

### Running the Application

#### Development Server (Web)
```bash
# Start development server - takes 30-60 seconds to start
flutter run -d chrome

# Alternative for web debugging
flutter run -d web-server --web-port 8080
```

#### Physical Device/Emulator
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run with hot reload enabled (default)
flutter run --hot
```

## Testing and Validation

### Unit Tests
```bash
# Run all tests - takes 1-2 minutes. NEVER CANCEL.
flutter test

# Run tests with coverage - takes 1-3 minutes. NEVER CANCEL.
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Integration Testing
```bash
# Run widget tests (if any exist)
flutter test test/

# Test file structure:
# test/widget_test.dart - Main widget tests
```

### Manual Validation Scenarios
**ALWAYS test these scenarios after making changes:**

1. **Login Flow Validation**:
   - Launch app and verify login screen appears
   - Check that FlutterLifter title and "Your Personal Fitness Journey" text display
   - Verify email/password fields and Sign In button are present
   - Confirm social login buttons (Google, Facebook, Apple) are visible

2. **Build Validation**:
   - Ensure web build completes without errors
   - Verify PWA functionality if applicable
   - Test responsive design on different screen sizes

3. **Code Quality Validation**:
   - Run `flutter analyze --fatal-infos` and ensure no errors
   - Run `dart format --output=none --set-exit-if-changed .` and ensure no formatting issues
   - All tests in `flutter test` must pass

## Deployment Workflows

### Automatic Deployment Triggers
The repository uses GitHub Actions for automated builds:

| Trigger | Platforms Built | Expected Time | Description |
|---------|----------------|---------------|-------------|
| **Push to main** | Web only | 3-5 minutes | Quick web deployment to GitHub Pages |
| **Create release** | All platforms | 15-25 minutes | Full production build for web, Android, Windows |
| **Manual trigger** | Configurable | 5-25 minutes | Choose specific platforms via GitHub Actions UI |

### Manual Deployment Commands
```bash
# Quick web deployment (push to main)
git add .
git commit -m "Deploy to web"
git push origin main

# Full release deployment (all platforms)
git tag v1.0.0
git push origin v1.0.0
```

### Deployment Validation
**After deployment, ALWAYS verify:**
- Web app accessible at: `https://jeffruocco.github.io/FlutterLifter/`
- GitHub Actions build status is green
- No build failures in Actions tab
- All artifacts are available for download if it's a release build

## Project Structure and Key Locations

### Repository Root
```
.
├── .github/              # GitHub Actions workflows and configuration
│   ├── workflows/        # CI/CD pipeline definitions
│   └── copilot-instructions.md
├── android/              # Android-specific configuration
├── docs/                 # Comprehensive project documentation
├── ios/                  # iOS-specific configuration  
├── lib/                  # Main Dart/Flutter source code
│   ├── core/            # Core functionality (theme, providers, router)
│   │   ├── providers/   # Riverpod providers for state management
│   │   ├── router/      # GoRouter configuration and routes
│   │   └── theme/       # Theme definitions and utilities
│   ├── data/            # Data layer (repositories, datasources)
│   ├── models/          # Domain models and entities
│   ├── screens/         # UI screens and pages
│   ├── services/        # Business logic services
│   ├── utils/           # Utility functions and helpers
│   ├── widgets/         # Reusable UI components
│   └── main.dart        # Application entry point
├── scripts/             # Deployment and setup scripts
├── test/                # Unit and widget tests
├── web/                 # Web-specific configuration
├── windows/             # Windows desktop configuration
├── pubspec.yaml         # Flutter dependencies and configuration
└── analysis_options.yaml # Dart analyzer configuration
```

### Important Files to Know
- **pubspec.yaml**: Dependencies, Flutter SDK constraints, app metadata
- **lib/main.dart**: Application entry point, ProviderScope, and GoRouter setup
- **lib/core/theme/**: App theming system (colors, text styles, dimensions)
- **lib/core/providers/**: Riverpod providers for dependency injection
- **lib/core/router/**: GoRouter configuration and route definitions
- **lib/models/**: Domain models organized by feature (exercise, program, workout)
- **lib/data/repositories/**: Data access layer with caching strategies
- **test/widget_test.dart**: Main widget tests covering login flow
- **.github/workflows/deploy.yml**: Complete CI/CD pipeline for all platforms
- **docs/**: Extensive documentation including data architecture, deployment guide

### Frequently Modified Locations
When making changes, commonly edited files include:
- **lib/screens/**: UI implementations and user flows
- **lib/widgets/**: Reusable components and custom widgets
- **lib/models/**: Domain logic and data structures
- **lib/core/theme/**: Visual styling and design system

## Common Tasks and Commands

### Code Quality and Linting
```bash
# Always run these before committing - CI will fail otherwise
flutter analyze --fatal-infos    # Takes 30-60 seconds
dart format --output=none --set-exit-if-changed .  # Takes 10-15 seconds
flutter test                     # Takes 1-2 minutes
```

### Package Management
```bash
# Add new dependency
flutter pub add package_name

# Update dependencies
flutter pub upgrade

# Get dependencies after clone/checkout
flutter pub get
```

### Platform Support
```bash
# Enable web support (if not already enabled)
flutter config --enable-web

# Enable Windows desktop support
flutter config --enable-windows-desktop

# Check supported platforms
flutter devices
```

### Troubleshooting Commands
```bash
# Clean build artifacts
flutter clean && flutter pub get

# Doctor check for issues
flutter doctor -v

# Verbose build for debugging
flutter build web --verbose
flutter build apk --verbose
```

## Build Timing Expectations

**CRITICAL TIMING INFORMATION - NEVER CANCEL BUILDS:**

| Command | Platform | Expected Time | Timeout Setting | Notes |
|---------|----------|---------------|-----------------|--------|
| `flutter test` | All | 1-2 minutes | 5 minutes | Unit and widget tests |
| `flutter build web` | Web | 2-3 minutes | 10 minutes | Fastest build option |
| `flutter build apk` | Android | 5-10 minutes | 15 minutes | Multiple architecture APKs |
| `flutter build appbundle` | Android | 3-5 minutes | 10 minutes | Google Play Store bundle |
| `flutter build windows` | Windows | 3-7 minutes | 10 minutes | Desktop executable |
| **Full CI Pipeline** | All | 15-25 minutes | 30 minutes | Complete build and test cycle |

**⚠️ NEVER CANCEL WARNING**: Flutter builds may appear to hang but are processing. Wait for completion. Android builds are particularly time-intensive due to Gradle compilation.

## Validation Requirements

### Pre-Commit Validation
**ALWAYS run these commands before committing:**
1. `flutter analyze --fatal-infos` - Must pass with no errors
2. `dart format --output=none --set-exit-if-changed .` - Must pass with no changes needed
3. `flutter test` - All tests must pass
4. Manual testing of login screen functionality

### Post-Change Validation  
**After making any UI changes:**
1. Build and run the web version: `flutter run -d chrome`
2. Verify login screen loads correctly with all expected elements
3. Test basic navigation and user interactions
4. **Test in BOTH light mode and dark mode** for contrast issues
5. Verify cards are visually distinct from backgrounds with visible borders
6. Take screenshots of UI changes for documentation

### Release Validation
**Before creating releases:**
1. All builds (web, Android, Windows) must complete successfully
2. Automated tests must pass
3. Manual testing of core user flows
4. Verify deployment to GitHub Pages works correctly

## Key Dependencies and Versions

- **Flutter SDK**: 3.32.x (as specified in .github/workflows/deploy.yml)
- **Dart SDK**: ^3.10.0
- **Java**: Version 17 required for Android builds
- **State Management**: flutter_riverpod ^3.1.0 (uses modern Notifier API)
- **Navigation**: go_router ^14.8.1
- **Icons**: hugeicons ^0.0.7 (use strokeRounded variant only)
- **Other**: cupertino_icons ^1.0.2, flutter_lints ^6.0.0

## Common Tasks Output Reference

### Repository Root Contents
```
ls -la [repo-root]
.github/              # GitHub Actions and configuration
.gitignore           # Git ignore patterns
.metadata            # Flutter metadata
.vscode/             # VS Code settings
DEPLOYMENT.md        # Quick deployment reference  
README.md            # Project overview
analysis_options.yaml # Dart analyzer configuration
android/             # Android platform files
docs/                # Documentation directory
ios/                 # iOS platform files
lib/                 # Main Dart source code
pubspec.lock         # Locked dependency versions
pubspec.yaml         # Project configuration and dependencies
scripts/             # Build and deployment scripts
test/                # Test files
web/                 # Web platform files
windows/             # Windows platform files
```

### Key Configuration Files
```
cat pubspec.yaml | grep -A 5 -B 5 "sdk:"
environment:
  sdk: '>=2.18.0-66.0.dev <3.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  hugeicons: ^0.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

## Documentation Resources

- **Design Guidelines**: `docs/design-guidelines.md` - Architecture overview, UI patterns, conventions
- **Riverpod Guide**: `docs/riverpod-guide.md` - Complete state management reference
- **Widget Gallery**: `docs/widget-gallery.md` - Component library documentation and maintenance
- **Deployment Guide**: `docs/deployment-guide.md` - Comprehensive deployment instructions
- **Data Architecture**: `docs/data-architecture.md` - Clean architecture patterns and data flow  
- **Authentication**: `docs/authentication.md` - Authentication implementation details
- **Color Theming Guide**: `docs/color-theming-guide.md` - Color usage patterns for light/dark mode
- **Programs Feature**: `docs/programs-feature.md` - Feature-specific documentation

## Architecture Patterns

### State Management (Riverpod)
This project uses **Riverpod** for state management. Key patterns:

```dart
// Accessing providers in widgets
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    // Read provider once
    final repo = ref.read(programRepositoryProvider);
    
    // Watch provider for reactive updates
    final theme = ref.watch(themeModeNotifierProvider);
  }
}
```

Provider files are located in `lib/core/providers/`.

### Navigation (GoRouter)
This project uses **GoRouter** for declarative navigation:

```dart
// Navigate (replace)
context.go(AppRoutes.home);

// Push (can go back)
context.push(AppRoutes.createProgram);

// Pop
context.pop();
```

Route configuration is in `lib/core/router/app_router.dart`.

### Icons (HugeIcons)
**ALWAYS use HugeIcons** with the `strokeRounded` variant:

```dart
// ✅ Correct
HugeIcons.strokeRoundedSearch01

// ❌ NEVER use Material Icons
Icon(Icons.home)
```

### Theme Access
Use context extensions for colors and `AppTextStyles` for typography:

```dart
// Colors via context
context.primaryColor
context.surfaceContainer
context.onSurface
context.textPrimary

// Text styles (static class)
AppTextStyles.headlineMedium
AppTextStyles.titleSmall
AppTextStyles.bodyLarge
```

### Contrast and Accessibility Guidelines
**CRITICAL: All UI changes must maintain adequate contrast in BOTH light and dark modes.**

#### Minimum Contrast Ratios
| Element Type | Minimum Ratio | Notes |
|--------------|---------------|-------|
| Body text | 4.5:1 | Against background |
| Large text (18pt+) | 3:1 | Against background |
| UI components | 3:1 | Buttons, inputs, borders |
| Card surfaces | 1.5:1 | Against app background |
| Card borders | 1.8:1 | Against card background |

#### Card Contrast Rules
- **ALWAYS use `AppCard` widget** - it handles contrast automatically
- Cards MUST be visually distinct from the app background
- Cards include subtle borders in both light and dark modes
- **NEVER rely solely on shadows** for card contrast (shadows are barely visible in dark mode)

#### Dark Mode Surface Hierarchy
```
Background:    #121212  (surfaceDark)
Container:     #1E1E1E  (surfaceContainerDark)
High:          #282828  (surfaceContainerHighDark) ← Default card background
Highest:       #323232  (surfaceContainerHighestDark)
Border:        #404040  (outlineVariantDark) ← Card borders
```

#### Light Mode Surface Hierarchy
```
Background:    #FFFFFF  (surface)
Container:     #F5F6F8  (surfaceContainer)
High:          #EEF0F2  (surfaceContainerHigh)
Highest:       #E5E8EB  (surfaceContainerHighest)
Border:        #CED4DA  (outlineVariant) ← Card borders
```

#### Before Committing UI Changes
1. Test in **BOTH** light mode and dark mode
2. Verify cards are visually distinct from background
3. Verify borders are visible
4. Quick test: Squint at screen - elements should not disappear

#### Common Contrast Mistakes to AVOID
```dart
// ❌ WRONG: Card without border in dark mode
Container(
  color: context.surfaceColor,
  // Missing border - blends into dark background!
)

// ❌ WRONG: Border too subtle
Border.all(color: Colors.white.withOpacity(0.1))  // Invisible!

// ✅ CORRECT: Use AppCard
AppCard(child: content)  // Handles contrast automatically
```

## Development Guidelines
- Follow the most recent Flutter best practices and Material Design guidelines
- Maintain compatibility with at minimum Flutter 3.32.x
- Use proper widget composition and state management
- Implement responsive design principles
- Follow Dart naming conventions (camelCase for variables, PascalCase for classes)
- Use proper error handling and null safety
- Write clean, maintainable, and well-documented code
- Implement reusable components and widgets to avoid code duplication
- Prefer stateless widgets when state is not needed
- Use const constructors when possible for better performance
- Follow the Flutter file structure conventions
- Maintain a consistent code style throughout the project
- Create comprehensive unit tests for critical components
- Ensure compatibility with mobile platforms (iOS and Android) as well as PWA for web support
- Maintain a consistent theme and styling system across the app
- Use context-aware theming for colors and styles to support light/dark mode
- **Ensure adequate contrast in both light and dark modes** - see Contrast Guidelines above
- **Always use `AppCard` for card components** to ensure automatic contrast handling
- **Test UI changes in both light and dark mode** before committing
- Implement optimistic UI updates for better user experience
- Implement offline-first support using a Stream where applicable
- Utilize Riverpod providers for dependency injection and state management instead of instantiate services directly (see `docs/riverpod-guide.md` and `docs/data-architecture.md` documents for more info)
- When in doubt, reference `docs/design-guidelines.md` for architectural and design patterns

## Code Quality
- Use meaningful variable and function names
- Add comments for complex business logic
- Follow the single responsibility principle
- Use proper imports (prefer relative imports for local files)
- Implement proper error handling and user feedback

---

> **Remember**: Always validate every command works before making code changes. This project has comprehensive CI/CD that will catch issues, but local validation saves time and ensures smooth development workflows.
