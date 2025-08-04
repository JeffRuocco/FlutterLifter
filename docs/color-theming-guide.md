# Color Theming Guide for FlutterLifter

## 🎨 Overview
This guide explains how to properly reference colors in your Flutter app to ensure seamless light/dark mode support.

## ✅ Best Practices for Color References

### 1. **USE: ColorScheme Colors (Preferred)**
```dart
// ✅ GOOD: Uses theme-aware colors
Container(
  color: context.surfaceColor,           // Adapts automatically
  child: Text(
    'Hello',
    style: TextStyle(color: context.onSurface), // Adapts automatically
  ),
)

// ✅ GOOD: Button styling
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: context.primaryColor,
    foregroundColor: context.onPrimary,
  ),
  child: Text('Sign In'),
)
```

### 2. **USE: Context Extensions**
```dart
// ✅ GOOD: Use context extensions for theme colors
Text(
  'Welcome',
  style: TextStyle(color: context.textPrimary),
)

// ✅ GOOD: Success message with theme-aware color
SnackBar(
  content: Text('Success!'),
  backgroundColor: context.successColor, // Handles light/dark automatically
)
```

### 3. **AVOID: Hard-coded AppColors**
```dart
// ❌ BAD: Hard-coded colors don't adapt to theme changes
Container(
  color: AppColors.surface,        // Won't change in dark mode
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.onSurface), // Won't adapt
  ),
)

// ❌ BAD: Static color reference
SnackBar(
  backgroundColor: AppColors.success, // Same color in light & dark
)
```

## 🎯 Color Reference Patterns

### Primary Colors
```dart
context.primaryColor           // Main brand color
context.primaryContainer       // Lighter variant for containers
context.onPrimary             // Text/icons on primary color
context.onPrimaryContainer    // Text/icons on primary container
```

### Surface & Background Colors
```dart
context.surfaceColor          // Card backgrounds, sheets
context.surfaceVariant        // Alternative surface color
context.backgroundColor       // Screen backgrounds
context.onSurface            // Text on surface
context.onBackground         // Text on background
```

### Text Colors
```dart
context.textPrimary          // Main text color
context.textSecondary        // Secondary text color
context.textDisabled         // Disabled text (with opacity)
```

### Status Colors
```dart
context.successColor         // Success messages (auto light/dark)
context.errorColor          // Error messages
context.warningColor        // Warning messages
context.infoColor           // Info messages
```

### Border & Outline Colors
```dart
context.outlineColor        // Borders, dividers
context.outlineVariant      // Subtle borders
```

## 🌙 Dark Mode Implementation

### ColorScheme Setup (in app_theme.dart)
```dart
static const ColorScheme _lightColorScheme = ColorScheme.light(
  primary: AppColors.primary,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  // ... other light colors
);

static const ColorScheme _darkColorScheme = ColorScheme.dark(
  primary: AppColors.primaryLight,    // Lighter for dark mode
  surface: Color(0xFF121212),         // Dark surface
  onSurface: Colors.white,            // Light text on dark
  // ... other dark colors
);
```

### Custom Status Colors (in theme_utils.dart)
```dart
Color get successColor => isDarkMode 
    ? const Color(0xFF4ADE80)  // Lighter green for dark mode
    : const Color(0xFF10B981); // Darker green for light mode
```

## 🚀 Migration Examples

### Before (Hard-coded)
```dart
// ❌ Old way
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.border),
  ),
  child: Text(
    'Content',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

### After (Theme-aware)
```dart
// ✅ New way
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    border: Border.all(color: context.outlineColor),
  ),
  child: Text(
    'Content',
    style: TextStyle(color: context.textPrimary),
  ),
)
```

## 🔧 Usage in Different Scenarios

### Buttons
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: context.primaryColor,
    foregroundColor: context.onPrimary,
  ),
)

// Secondary button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: context.primaryColor,
    side: BorderSide(color: context.outlineColor),
  ),
)
```

### Cards & Containers
```dart
Card(
  color: context.surfaceColor,
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: context.outlineVariant),
    ),
  ),
)
```

### Text Styling
```dart
// Primary text
Text('Title', style: TextStyle(color: context.textPrimary))

// Secondary text
Text('Subtitle', style: TextStyle(color: context.textSecondary))

// On colored backgrounds
Container(
  color: context.primaryColor,
  child: Text('Title', style: TextStyle(color: context.onPrimary)),
)
```

### Status Messages
```dart
// Success
SnackBar(
  backgroundColor: context.successColor,
  content: Text('Success!'),
)

// Error
SnackBar(
  backgroundColor: context.errorColor,
  content: Text('Error occurred'),
)
```

## 📝 Quick Reference

| Use Case | Recommended Color | Example |
|----------|------------------|---------|
| App backgrounds | `context.backgroundColor` | Scaffold background |
| Card backgrounds | `context.surfaceColor` | Card, bottom sheets |
| Primary buttons | `context.primaryColor` | CTA buttons |
| Text on primary | `context.onPrimary` | Button text |
| Body text | `context.textPrimary` | Main content |
| Secondary text | `context.textSecondary` | Captions, hints |
| Borders | `context.outlineColor` | Input borders, dividers |
| Success messages | `context.successColor` | Success snackbars |
| Error messages | `context.errorColor` | Error states |

## 🎯 Key Benefits

1. **Automatic Adaptation**: Colors automatically adjust for light/dark mode
2. **Consistency**: Ensures consistent theming across the app
3. **Maintainability**: Easy to update theme colors globally
4. **Accessibility**: Better contrast ratios in different modes
5. **Material Design**: Follows Material 3 color guidelines

Remember: Always use `context.colorName` instead of `AppColors.colorName` for theme-aware coloring!
