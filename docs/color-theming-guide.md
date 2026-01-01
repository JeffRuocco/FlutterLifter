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

---

## 🔲 Contrast Guidelines

### Minimum Contrast Requirements

All UI elements must meet minimum contrast ratios for accessibility and visual clarity:

| Element Type | Minimum Contrast Ratio | Notes |
|--------------|----------------------|-------|
| Body text | 4.5:1 | Against background |
| Large text (18pt+) | 3:1 | Against background |
| UI components | 3:1 | Buttons, inputs, borders |
| Card surfaces | 1.5:1 | Against app background |
| Card borders | 1.8:1 | Against card background |

### Dark Mode Color Hierarchy

Dark mode uses a layered surface approach for depth perception:

```
Layer 0 (Background):    #121212  - App/scaffold background
Layer 1 (Container):     #1E1E1E  - Base card containers
Layer 2 (High):          #282828  - Elevated cards (default)
Layer 3 (Highest):       #323232  - Most prominent surfaces
Border (Outline):        #404040  - Visible card borders
Border (Primary):        #5C5C5C  - More prominent borders
```

### Light Mode Color Hierarchy

Light mode uses subtle differences with visible borders:

```
Layer 0 (Background):    #FFFFFF  - App/scaffold background
Layer 1 (Container):     #F5F6F8  - Base card containers
Layer 2 (High):          #EEF0F2  - Elevated surfaces
Layer 3 (Highest):       #E5E8EB  - Most distinct surfaces
Border (Outline):        #CED4DA  - Subtle card borders
Border (Primary):        #ADB5BD  - More prominent borders
```

### Card Contrast Rules

**ALWAYS ensure cards are visually distinct from the background:**

```dart
// ✅ GOOD: Cards have both surface color AND visible border
AppCard(
  // Automatically uses surfaceContainerHigh + outlineVariant border
  child: content,
)

// ✅ GOOD: Custom card with explicit contrast
Container(
  decoration: BoxDecoration(
    color: context.surfaceColor,
    border: Border.all(
      color: context.outlineVariant,  // Visible in both modes
      width: 1,
    ),
    borderRadius: BorderRadius.circular(12),
  ),
)

// ❌ BAD: Card blends into background (no border, similar color)
Container(
  color: context.surfaceColor,  // May be too similar to background
  // Missing border for definition!
)
```

### Testing Contrast

**Before committing UI changes, verify:**

1. **Light mode**: Cards are distinguishable from white background
2. **Dark mode**: Cards are distinguishable from dark background
3. **Borders visible**: Card edges are clearly defined
4. **Text readable**: All text has sufficient contrast against its background

**Quick test:** Squint at the screen - if elements disappear or blend together, contrast is too low.

### Color Values Reference

#### Dark Mode Surfaces (from AppColors)
```dart
surfaceDark:                  #121212  // App background
surfaceContainerDark:         #1E1E1E  // Base containers
surfaceContainerHighDark:     #282828  // Elevated cards
surfaceContainerHighestDark:  #323232  // Highest elevation
outlineDark:                  #5C5C5C  // Primary borders
outlineVariantDark:           #404040  // Card borders
```

#### Light Mode Surfaces (from AppColors)
```dart
surface:                      #FFFFFF  // App background
surfaceContainer:             #F5F6F8  // Base containers
surfaceContainerHigh:         #EEF0F2  // Elevated surfaces
surfaceContainerHighest:      #E5E8EB  // Highest elevation
outline:                      #ADB5BD  // Primary borders
outlineVariant:               #CED4DA  // Card borders
```

### Common Contrast Mistakes to Avoid

```dart
// ❌ WRONG: Using same color for card and background
Scaffold(
  backgroundColor: context.surfaceColor,  // White
  body: Container(
    color: context.surfaceColor,  // Also white - no distinction!
  ),
)

// ❌ WRONG: Border color too close to background
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.white.withOpacity(0.1)),  // Invisible!
  ),
)

// ❌ WRONG: Assuming shadows provide enough contrast in dark mode
Container(
  decoration: BoxDecoration(
    boxShadow: [BoxShadow(...)],  // Shadows barely visible on dark backgrounds
  ),
)

// ✅ CORRECT: Use AppCard which handles contrast automatically
AppCard(
  child: content,  // Has proper surface color + border in both modes
)
```
