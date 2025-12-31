# FlutterLifter Design Guidelines

This document outlines the design principles, patterns, and conventions used throughout the FlutterLifter application.

## Table of Contents

1. [Design Principles](#design-principles)
2. [Architecture Overview](#architecture-overview)
3. [State Management (Riverpod)](#state-management-riverpod)
4. [Navigation (GoRouter)](#navigation-gorouter)
5. [Theming System](#theming-system)
6. [Icons (HugeIcons)](#icons-hugeicons)
7. [UI Components](#ui-components)
8. [Context Extensions](#context-extensions)
9. [Common Patterns](#common-patterns)

---

## Design Principles

### Modern, Sleek, Simple, Functional

Our design philosophy centers on:

- **Clarity**: UI elements should be immediately understandable
- **Consistency**: Same patterns across all screens
- **Simplicity**: Avoid visual clutter and unnecessary complexity
- **Functionality**: Every element serves a purpose

### Material Design 3

We use Material Design 3 (Material You) with `useMaterial3: true` for:
- Dynamic color theming
- Updated component styles
- Improved accessibility
- Consistent visual language

---

## Architecture Overview

```
lib/
├── core/
│   ├── providers/       # Riverpod providers (state management)
│   ├── router/          # GoRouter configuration (navigation)
│   └── theme/           # Theme definitions and utilities
├── data/
│   ├── datasources/     # Data sources (local, remote)
│   └── repositories/    # Repository implementations
├── models/              # Domain models and entities
├── screens/             # Full-page UI screens
├── services/            # Business logic services
├── utils/               # Utility functions
└── widgets/             # Reusable UI components
```

---

## State Management (Riverpod)

### Why Riverpod?

- Type-safe provider access
- Automatic disposal of resources
- Easy testing with provider overrides
- No BuildContext dependency for accessing state

### Provider Types

```dart
// Simple value provider
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig());

// Async value provider
final userProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(authServiceProvider);
  return auth.getCurrentUser();
});

// State notifier for complex state
final themeModeNotifierProvider = 
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
```

### Accessing Providers in Widgets

```dart
// For StatelessWidget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeNotifierProvider);
    return Text('Theme: $theme');
  }
}

// For StatefulWidget
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(programRepositoryProvider);
    // ...
  }
}
```

### Provider Files

| File | Purpose |
|------|---------|
| `providers.dart` | Barrel file exporting all providers |
| `repository_providers.dart` | Data repository providers |
| `service_providers.dart` | Business logic service providers |
| `logger_providers.dart` | Logging (Talker) providers |
| `config_providers.dart` | App configuration providers |
| `auth_providers.dart` | Authentication providers |
| `workout_providers.dart` | Workout-related providers |

---

## Navigation (GoRouter)

### Route Configuration

Routes are defined in `lib/core/router/app_router.dart`:

```dart
// Route constants
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String progress = '/progress';
  static const String programs = '/programs';
  static const String workout = '/workout';
  static const String createProgram = '/programs/create';
  static const String settings = '/settings';
  static const String widgetGallery = '/widget-gallery';
}
```

### Navigation Patterns

```dart
// Navigate to route (replaces current)
context.go(AppRoutes.home);

// Push route onto stack (can go back)
context.push(AppRoutes.createProgram);

// Pop current route
context.pop();

// Navigate with path parameters
context.go('/workout/${workoutId}');

// Navigate with query parameters
context.go('/search?q=arms');
```

### Shell Routes (Bottom Navigation)

The app uses `StatefulShellRoute` for bottom navigation:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return AppShell(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(routes: [/* Home routes */]),
    StatefulShellBranch(routes: [/* Progress routes */]),
    StatefulShellBranch(routes: [/* Programs routes */]),
  ],
);
```

---

## Theming System

### Theme Configuration

Themes are defined in `lib/core/theme/app_theme.dart`:

```dart
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    // ...
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    // ...
  );
}
```

### Theme Mode Persistence

Theme preference is persisted using `SharedPreferences`:

```dart
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('theme_mode', mode.name);
    state = mode;
  }
}
```

### Toggling Theme

```dart
// In a ConsumerWidget
final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
themeNotifier.setThemeMode(ThemeMode.dark);
```

---

## Icons (HugeIcons)

### Standardized Icon Library

We use **HugeIcons** exclusively for visual consistency:

```dart
import 'package:hugeicons/hugeicons.dart';

// Correct usage
Icon(HugeIcons.strokeRoundedHome01)
Icon(HugeIcons.strokeRoundedDumbbell01)

// NEVER use Material Icons
Icon(Icons.home)  // ❌ Don't do this
```

### Icon Style

Always use `strokeRounded` variant for consistency:

```dart
// ✅ Correct
HugeIcons.strokeRoundedSettings01
HugeIcons.strokeRoundedSearch01

// ❌ Incorrect (using other variants)
HugeIcons.solidRoundedSettings01
HugeIcons.duotoneRoundedSettings01
```

### Common Icons Reference

| Purpose | Icon |
|---------|------|
| Home | `HugeIcons.strokeRoundedHome01` |
| Progress/Chart | `HugeIcons.strokeRoundedAnalytics01` |
| Programs | `HugeIcons.strokeRoundedFolder01` |
| Workout | `HugeIcons.strokeRoundedDumbbell01` |
| Settings | `HugeIcons.strokeRoundedSettings01` |
| Add | `HugeIcons.strokeRoundedAdd01` |
| Edit | `HugeIcons.strokeRoundedEdit01` |
| Delete | `HugeIcons.strokeRoundedDelete01` |
| Play | `HugeIcons.strokeRoundedPlay` |
| Timer | `HugeIcons.strokeRoundedTime01` |
| Check | `HugeIcons.strokeRoundedCheckmarkCircle01` |

---

## UI Components

### Custom Buttons

Use `AppButton` from `lib/widgets/buttons/app_button.dart`:

```dart
AppButton(
  label: 'Start Workout',
  onPressed: () => startWorkout(),
  type: AppButtonType.primary,
)

AppButton.secondary(
  label: 'Cancel',
  onPressed: () => context.pop(),
)

AppButton.text(
  label: 'Skip',
  onPressed: () => skip(),
)
```

### Cards

Use consistent card styling with `AppCard` or themed containers:

```dart
Container(
  decoration: BoxDecoration(
    color: context.surfaceContainer,
    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
  ),
  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
  child: content,
)
```

### Input Fields

Use themed `TextField` with consistent styling:

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Exercise Name',
    prefixIcon: Icon(HugeIcons.strokeRoundedDumbbell01),
  ),
)
```

---

## Context Extensions

Access theme values through context extensions in `lib/core/theme/theme_utils.dart`:

### Colors

```dart
// Surface colors
context.primaryColor        // Primary brand color
context.surfaceContainer    // Card/container background
context.onSurface           // Text on surface
context.onSurfaceVariant    // Secondary text on surface

// Semantic colors
context.error               // Error state color
```

### Text Colors

```dart
context.textPrimary         // Primary text color
context.textSecondary       // Secondary/dimmed text
context.textTertiary        // Tertiary/hint text
```

### Text Styles

Use static `AppTextStyles` class:

```dart
Text('Headline', style: AppTextStyles.headlineMedium)
Text('Title', style: AppTextStyles.titleSmall)
Text('Body', style: AppTextStyles.bodyLarge)
Text('Label', style: AppTextStyles.labelMedium)
```

---

## Common Patterns

### Screen Structure

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Title'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    // ...
  }
}
```

### Loading States

```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

### Error Handling with SnackBars

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error: $message'),
    backgroundColor: context.error,
  ),
);
```

### Dialogs

```dart
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Confirm'),
    content: const Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(dialogContext);
          // Perform action
        },
        child: const Text('Confirm'),
      ),
    ],
  ),
);
```

### Duration Constants

Use `AppDurations` for consistent animations:

```dart
AppDurations.fast       // 150ms - Quick transitions
AppDurations.medium     // 300ms - Standard animations
AppDurations.slow       // 500ms - Elaborate animations
```

---

## Best Practices Summary

1. **Icons**: Always use HugeIcons with `strokeRounded` variant
2. **State**: Access state through Riverpod providers, not ServiceLocator
3. **Navigation**: Use GoRouter methods (`context.go`, `context.push`, `context.pop`)
4. **Theming**: Use context extensions for colors, `AppTextStyles` for typography
5. **Components**: Use custom widgets (`AppButton`, etc.) over raw Material widgets
6. **Testing**: Wrap widgets in `ProviderScope` with necessary overrides

---

## See Also

- [Widget Gallery Documentation](widget-gallery.md)
- [Data Architecture](data-architecture.md)
- [Authentication](authentication.md)
- [Deployment Guide](deployment-guide.md)
