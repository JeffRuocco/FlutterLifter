# FlutterLifter Styling System

## Overview
A comprehensive, scalable styling system for FlutterLifter that ensures consistent design throughout the app and makes it easy to adjust styling as the project grows.

## Architecture

### 📁 File Structure
```
lib/core/theme/
├── app_colors.dart       # Color palette
├── app_text_styles.dart  # Typography system
├── app_dimensions.dart   # Spacing, sizes, and layout
├── app_theme.dart        # Main theme configuration
└── theme_utils.dart      # Utilities and custom widgets
```

## 🎨 Color System

### Usage
```dart
import 'package:flutter_lifter/core/theme/app_colors.dart';

// Primary colors
AppColors.primary
AppColors.primaryLight
AppColors.primaryDark

// Status colors
AppColors.success
AppColors.error
AppColors.warning

// Fitness-specific colors
AppColors.cardio
AppColors.strength
AppColors.flexibility
```

### Features
- ✅ Consistent color palette
- ✅ Semantic color naming
- ✅ Status colors (success, error, warning)
- ✅ Social media brand colors
- ✅ Fitness-specific color coding
- ✅ Light/dark theme support

## ✏️ Typography System

### Usage
```dart
import 'package:flutter_lifter/core/theme/app_text_styles.dart';

Text(
  'Headline',
  style: AppTextStyles.headlineLarge,
)

Text(
  'Body text',
  style: AppTextStyles.bodyMedium,
)
```

### Style Categories
- **Display**: Large headings (57px - 36px)
- **Headline**: Section headings (32px - 24px)
- **Title**: Component titles (22px - 14px)
- **Body**: Main content text (16px - 12px)
- **Label**: Form labels and captions (14px - 11px)
- **Custom**: App-specific styles (workout titles, stats, etc.)

## 📐 Dimensions & Spacing

### Spacing System (8dp Grid)
```dart
import 'package:flutter_lifter/core/theme/app_dimensions.dart';

// Using spacing constants
Padding(
  padding: EdgeInsets.all(AppSpacing.md), // 16px
)

// Using spacing widgets
Column(
  children: [
    Text('Title'),
    VSpace.lg(), // 24px vertical space
    Text('Content'),
  ],
)
```

### Spacing Scale
- `xs`: 4px
- `sm`: 8px  
- `md`: 16px
- `lg`: 24px
- `xl`: 32px
- `xxl`: 48px
- `xxxl`: 64px

### Component Dimensions
```dart
// Button heights
AppDimensions.buttonHeightSmall  // 32px
AppDimensions.buttonHeightMedium // 44px
AppDimensions.buttonHeightLarge  // 56px

// Border radius
AppDimensions.borderRadiusSmall  // 4px
AppDimensions.borderRadiusLarge  // 12px
AppDimensions.borderRadiusRound  // 24px

// Icon sizes
AppDimensions.iconSmall   // 16px
AppDimensions.iconMedium  // 24px
AppDimensions.iconLarge   // 32px
```

## 🎭 Theme Configuration

### Usage
```dart
import 'package:flutter_lifter/core/theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

### Features
- ✅ Material 3 design system
- ✅ Automatic light/dark theme
- ✅ Consistent component styling
- ✅ Custom color schemes
- ✅ Typography integration

## 🔧 Utility Widgets

### Quick Spacing
```dart
// Vertical spacing
VSpace.xs()   // 4px
VSpace.sm()   // 8px
VSpace.md()   // 16px
VSpace.lg()   // 24px
VSpace.xl()   // 32px

// Horizontal spacing  
HSpace.md()   // 16px horizontal space
```

### App Components
```dart
// Consistent cards
AppCard(
  child: Text('Content'),
  padding: EdgeInsets.all(AppSpacing.md),
)

// Styled buttons
AppButton(
  text: 'Sign In',
  onPressed: () {},
  isLoading: false,
  type: AppButtonType.elevated,
)

// Form fields
AppTextFormField(
  labelText: 'Email',
  validator: (value) => ...,
  prefixIcon: Icon(Icons.email),
)
```

### Theme Extensions
```dart
// Easy theme access
context.primaryColor
context.surfaceColor
context.isDarkMode
context.textTheme.headlineLarge
```

## 🎯 Benefits

### For Development
- **Consistency**: Same styling across all screens
- **Maintainability**: Change colors/sizes in one place
- **Speed**: Pre-built components and utilities
- **Scalability**: Easy to extend and modify

### For Design
- **Professional**: Material 3 design system
- **Accessible**: Proper contrast and sizing
- **Responsive**: Consistent spacing and layout
- **Brand**: Custom color palette for FlutterLifter

## 🔄 Making Changes

### Adding New Colors
1. Add to `AppColors` class
2. Update theme configuration if needed
3. Document the new color's purpose

### Modifying Spacing
1. Update `AppSpacing` constants
2. Components automatically inherit changes
3. Test across different screen sizes

### Custom Components
1. Create in `theme_utils.dart`
2. Follow existing naming conventions
3. Use system colors and dimensions

## 📱 Usage Examples

### Screen Layout
```dart
Scaffold(
  backgroundColor: AppColors.backgroundGrey,
  body: Padding(
    padding: EdgeInsets.all(AppSpacing.screenPadding),
    child: Column(
      children: [
        Text(
          'Screen Title',
          style: AppTextStyles.headlineLarge,
        ),
        VSpace.lg(),
        AppCard(
          child: Text('Card content'),
        ),
      ],
    ),
  ),
)
```

### Form Styling
```dart
Form(
  child: Column(
    children: [
      AppTextFormField(
        labelText: 'Email',
        validator: emailValidator,
      ),
      VSpace.md(),
      AppButton(
        text: 'Submit',
        onPressed: onSubmit,
      ),
    ],
  ),
)
```

This styling system provides a solid foundation for FlutterLifter's design while remaining flexible for future enhancements!
