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
8. [Animation System](#animation-system)
9. [Context Extensions](#context-extensions)
10. [Common Patterns](#common-patterns)

---

## Design Principles

### Modern, Sleek, Simple, Functional

Our design philosophy centers on:

- **Clarity**: UI elements should be immediately understandable
- **Consistency**: Same patterns across all screens
- **Simplicity**: Avoid visual clutter and unnecessary complexity
- **Functionality**: Every element serves a purpose
- **Delight**: Subtle animations and micro-interactions enhance UX

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
    └── animations/      # Animation widgets
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

### Color Palette

Our warm, energetic color palette:

```dart
// Primary colors - Warm Coral
static const Color primary = Color(0xFFFF6B4A);
static const Color primaryDark = Color(0xFFFF8A70);

// Secondary colors - Teal
static const Color secondary = Color(0xFF26A69A);
static const Color secondaryDark = Color(0xFF4DB6AC);

// Gradients
static const List<Color> primaryGradient = [primary, Color(0xFFFF8A70)];
static const List<Color> secondaryGradient = [secondary, Color(0xFF4DB6AC)];
static const List<Color> sunsetGradient = [Color(0xFFFF6B4A), Color(0xFFFFD54F)];
static const List<Color> oceanGradient = [Color(0xFF26A69A), Color(0xFF42A5F5)];

// Muscle Group Colors (for visual exercise indicators)
static const Color muscleChest = Color(0xFFE53935);
static const Color muscleBack = Color(0xFF1E88E5);
static const Color muscleLegs = Color(0xFF43A047);
static const Color muscleShoulders = Color(0xFFFB8C00);
static const Color muscleArms = Color(0xFF8E24AA);
static const Color muscleCore = Color(0xFFFFB300);
static const Color muscleFullBody = Color(0xFF00897B);
```

### Glassmorphism Colors

For frosted glass effects on cards and modals:

```dart
// Light mode glass
static const Color glassWhite = Color(0x80FFFFFF);
static const Color glassBorder = Color(0x40FFFFFF);

// Dark mode glass
static const Color glassBlack = Color(0x40000000);
static const Color glassBorderDark = Color(0x30FFFFFF);
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

### AppCard Variants

Use `AppCard` with different style variants:

```dart
// Standard elevated card (default)
AppCard(
  child: content,
  onTap: () => handleTap(),
)

// Outlined card with border
AppCard.outlined(
  child: content,
)

// Filled card with solid background
AppCard.filled(
  child: content,
)

// Glassmorphism card with blur effect
AppCard.glass(
  child: content,
)

// Gradient background card
AppCard.gradient(
  gradientColors: AppColors.primaryGradient,
  child: content,
)
```

### AppButton System

Use `AppButton` with various types and features:

```dart
// Standard elevated button
AppButton.elevated(
  text: 'Start Workout',
  onPressed: () => startWorkout(),
)

// Outlined button
AppButton.outlined(
  text: 'Cancel',
  onPressed: () => cancel(),
)

// Text-only button
AppButton.text(
  text: 'Skip',
  onPressed: () => skip(),
)

// Icon-only button (circular)
AppButton.icon(
  icon: HugeIcon(icon: HugeIcons.strokeRoundedPlay, color: Colors.white),
  onPressed: () => play(),
)

// Pill-shaped button
AppButton.pill(
  text: 'Get Started',
  icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.white),
  onPressed: () => getStarted(),
)

// Gradient button
AppButton.gradient(
  text: 'Sign In',
  gradientColors: AppColors.primaryGradient,
  onPressed: () => signIn(),
  isLoading: _isLoading,  // Shows shimmer loading effect
)
```

### Input Fields

Use themed `TextField` with consistent styling:

```dart
AppTextFormField(
  labelText: 'Exercise Name',
  prefixIcon: HugeIcon(
    icon: HugeIcons.strokeRoundedDumbbell01,
    color: context.onSurface,
  ),
  validator: (value) => value?.isEmpty == true ? 'Required' : null,
)
```

### Progress Indicators

```dart
// Standard progress ring
ProgressRing(
  progress: 0.75,
  size: 120,
  strokeWidth: 10,
  progressColor: context.primaryColor,
  child: Text('75%'),
)

// Animated progress ring with entrance animation
AnimatedProgressRing(
  progress: 0.75,
  size: 80,
  animationDuration: Duration(milliseconds: 1000),
)

// Mini progress ring for compact spaces
MiniProgressRing(
  progress: 0.5,
  size: 24,
)
```

### Skeleton Loaders

For loading states:

```dart
// Text placeholder
SkeletonText(width: 200, height: 16)

// Avatar placeholder
SkeletonAvatar(size: 48)

// Card placeholder
SkeletonCard(height: 120)

// Exercise card skeleton
SkeletonExerciseCard()

// Workout card skeleton
SkeletonWorkoutCard()

// List of skeletons
SkeletonList(
  itemCount: 3,
  itemBuilder: (context, index) => SkeletonCard(height: 80),
)
```

### Empty States

For empty/error screens with Lottie animations:

```dart
// No workouts
EmptyState.noWorkouts(
  onCreateWorkout: () => navigateToCreate(),
)

// No programs
EmptyState.noPrograms(
  onCreateProgram: () => createProgram(),
)

// Error state with retry
EmptyState.error(
  message: 'Failed to load data',
  onRetry: () => retry(),
)

// No search results
EmptyState.noResults(
  searchQuery: 'biceps',
)

// Offline state
EmptyState.offline(
  onRetry: () => checkConnection(),
)
```

---

## Animation System

### Entrance Animations

Use the animation widgets from `lib/widgets/animations/`:

```dart
// Fade in widget
FadeInWidget(
  delay: Duration(milliseconds: 200),
  child: Text('Hello'),
)

// Slide in from bottom
SlideInWidget(
  delay: Duration(milliseconds: 300),
  child: MyCard(),
)

// Staggered list animation
StaggeredList(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(items[index]),
)
```

### Animated Counter

For numeric value animations:

```dart
AnimatedCounter(
  value: 1234,
  duration: Duration(milliseconds: 1500),
  style: AppTextStyles.headlineLarge,
)
```

### Pulse Widget

For attention-grabbing elements:

```dart
PulseWidget(
  child: Icon(HugeIcons.strokeRoundedNotification01),
)
```

### Success Confetti

For celebration moments:

```dart
SuccessConfetti(
  isPlaying: _showConfetti,
  onComplete: () => setState(() => _showConfetti = false),
  child: MyContent(),
)

// Or use the extension
myWidget.withConfetti(
  isPlaying: _celebrate,
  particleCount: 50,
)
```

### Animation Best Practices

1. **Stagger entrance animations**: Use increasing delays (100ms, 200ms, 300ms...)
2. **Keep animations subtle**: 150-300ms for most transitions
3. **Respect reduce motion**: Check accessibility settings
4. **Use consistent curves**: Prefer `Curves.easeOutQuart` for emphasis

---

## Context Extensions

Access theme values through context extensions in `lib/core/theme/theme_utils.dart`:

### Colors

```dart
// Surface colors
context.primaryColor        // Primary brand color
context.surfaceColor        // Card/container background
context.surfaceVariant      // Alternate surface
context.onSurface           // Text on surface
context.onSurfaceVariant    // Secondary text on surface

// Semantic colors
context.successColor        // Success state
context.warningColor        // Warning state
context.errorColor          // Error state
context.infoColor           // Info state
```

### Text Colors

```dart
context.textPrimary         // Primary text color
context.textSecondary       // Secondary/dimmed text
context.textDisabled        // Disabled text
```

### Theme State

```dart
context.isDarkMode          // Check if dark mode is active
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
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
  return Column(
    children: [
      SkeletonCard(height: 120),
      VSpace.md(),
      SkeletonList(itemCount: 3),
    ],
  );
}
```

### Status Messages

```dart
// Success message
showSuccessMessage(context, 'Workout completed! 🎉');

// Error message
showErrorMessage(context, 'Failed to save');

// Info message
showInfoMessage(context, 'Changes saved');

// Warning message
showWarningMessage(context, 'Low battery');
```

### Dialogs

```dart
showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(
      'Confirm',
      style: AppTextStyles.headlineSmall.copyWith(
        color: dialogContext.textPrimary,
      ),
    ),
    content: Text(
      'Are you sure?',
      style: AppTextStyles.bodyMedium.copyWith(
        color: dialogContext.textSecondary,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
      AppButton.elevated(
        text: 'Confirm',
        onPressed: () {
          Navigator.pop(dialogContext);
          // Perform action
        },
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
2. **State**: Access state through Riverpod providers
3. **Navigation**: Use GoRouter methods (`context.go`, `context.push`, `context.pop`)
4. **Theming**: Use context extensions for colors, `AppTextStyles` for typography
5. **Components**: Use custom widgets (`AppCard`, `AppButton`, etc.)
6. **Animations**: Use animation widgets for entrances, keep durations subtle
7. **Loading**: Use skeleton loaders instead of spinners where possible
8. **Empty States**: Always provide helpful empty states with actions
9. **Haptics**: Add haptic feedback on important interactions
10. **Testing**: Wrap widgets in `ProviderScope` with necessary overrides

---

## See Also

- [Widget Gallery Documentation](widget-gallery.md)
- [Data Architecture](data-architecture.md)
- [Authentication](authentication.md)
- [Deployment Guide](deployment-guide.md)
