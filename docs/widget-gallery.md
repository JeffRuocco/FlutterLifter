# Widget Gallery Documentation

This document describes the Widget Gallery screen and how to maintain it as the FlutterLifter design system evolves.

## Overview

The Widget Gallery is a development tool and reference screen that showcases all reusable UI components in the FlutterLifter app. It serves as:

1. **Living documentation** - See all components in context
2. **Design system reference** - Verify consistency across components
3. **Development tool** - Test components during implementation
4. **Onboarding resource** - Help new developers understand available components

## Accessing the Widget Gallery

The Widget Gallery is accessible via:

- **Route**: `/widget-gallery`
- **From Settings**: Navigate to Settings → Widget Gallery
- **Code navigation**: `context.push(AppRoutes.widgetGallery)`

## Gallery Structure

The screen is organized into tabbed sections:

### 1. Buttons Tab

Showcases all button variants:

```dart
// Primary button
AppButton(
  label: 'Primary',
  onPressed: () {},
  type: AppButtonType.primary,
)

// Secondary button
AppButton.secondary(
  label: 'Secondary',
  onPressed: () {},
)

// Text button
AppButton.text(
  label: 'Text Button',
  onPressed: () {},
)

// Icon buttons
IconButton(
  icon: Icon(HugeIcons.strokeRoundedAdd01),
  onPressed: () {},
)
```

### 2. Cards Tab

Displays card patterns:

```dart
// Basic card
Container(
  decoration: BoxDecoration(
    color: context.surfaceContainer,
    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
  ),
  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
  child: content,
)

// Elevated card
Card(
  elevation: 2,
  child: content,
)
```

### 3. Inputs Tab

Form input components:

```dart
// Text field
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Placeholder',
    prefixIcon: Icon(HugeIcons.strokeRoundedSearch01),
  ),
)

// Number input with steppers
Row(
  children: [
    IconButton(icon: Icon(HugeIcons.strokeRoundedRemove01)),
    Text('5'),
    IconButton(icon: Icon(HugeIcons.strokeRoundedAdd01)),
  ],
)
```

### 4. Colors Tab

Color palette display:

- Primary colors
- Surface colors
- Semantic colors (error, success, warning)
- Text colors

### 5. Typography Tab

Text style showcase:

```dart
Text('Headline Large', style: AppTextStyles.headlineLarge)
Text('Headline Medium', style: AppTextStyles.headlineMedium)
Text('Title Large', style: AppTextStyles.titleLarge)
Text('Title Medium', style: AppTextStyles.titleMedium)
Text('Body Large', style: AppTextStyles.bodyLarge)
Text('Body Medium', style: AppTextStyles.bodyMedium)
Text('Label Large', style: AppTextStyles.labelLarge)
Text('Label Medium', style: AppTextStyles.labelMedium)
```

## Adding New Components

When you create a new reusable component, add it to the Widget Gallery:

### Step 1: Identify the Appropriate Tab

Choose or create a tab that best categorizes your component:

| Component Type | Tab |
| -------------- | --- |
| Buttons, CTAs | Buttons |
| Containers, tiles | Cards |
| Form fields | Inputs |
| Color additions | Colors |
| Text styling | Typography |
| New category | Create new tab |

### Step 2: Add to Gallery Screen

Edit `lib/screens/widget_gallery_screen.dart`:

```dart
// Add to the appropriate tab builder method
Widget _buildButtonsTab() {
  return ListView(
    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
    children: [
      // Existing buttons...
      
      // Add your new button
      _buildSection(
        title: 'New Button Variant',
        child: YourNewButton(
          label: 'Example',
          onPressed: () {},
        ),
      ),
    ],
  );
}
```

### Step 3: Add Documentation

Document the component inline:

```dart
_buildSection(
  title: 'Danger Button',
  description: 'Use for destructive actions like delete',
  child: AppButton(
    label: 'Delete',
    type: AppButtonType.danger,
    onPressed: () {},
  ),
),
```

## Helper Methods

The gallery uses helper methods for consistent presentation:

### `_buildSection`

```dart
Widget _buildSection({
  required String title,
  String? description,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.titleSmall),
      if (description != null)
        Text(description, style: AppTextStyles.bodySmall),
      SizedBox(height: AppDimensions.paddingSmall),
      child,
      SizedBox(height: AppDimensions.paddingLarge),
    ],
  );
}
```

### `_buildColorSwatch`

```dart
Widget _buildColorSwatch(String name, Color color) {
  return Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name),
          Text('#${color.value.toRadixString(16).toUpperCase()}'),
        ],
      ),
    ],
  );
}
```

## Creating New Tabs

To add a new category tab:

### 1. Add Tab to TabBar

```dart
TabBar(
  tabs: [
    Tab(text: 'Buttons'),
    Tab(text: 'Cards'),
    Tab(text: 'Inputs'),
    Tab(text: 'Colors'),
    Tab(text: 'Typography'),
    Tab(text: 'New Category'), // Add new tab
  ],
)
```

### 2. Add TabBarView Child

```dart
TabBarView(
  children: [
    _buildButtonsTab(),
    _buildCardsTab(),
    _buildInputsTab(),
    _buildColorsTab(),
    _buildTypographyTab(),
    _buildNewCategoryTab(), // Add new builder
  ],
)
```

### 3. Implement Tab Builder

```dart
Widget _buildNewCategoryTab() {
  return ListView(
    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
    children: [
      _buildSection(
        title: 'Component Name',
        child: YourComponent(),
      ),
    ],
  );
}
```

## Best Practices

### Do

✅ Show all variants of a component  
✅ Include disabled/loading states  
✅ Show light and dark mode appearance  
✅ Add descriptive titles and descriptions  
✅ Keep examples interactive where possible  
✅ Group related components together  

### Don't

❌ Skip new components  
❌ Show only the "happy path" state  
❌ Use hardcoded colors instead of theme colors  
❌ Leave components without labels  
❌ Mix component categories in wrong tabs  

## Testing the Gallery

The Widget Gallery should be tested to ensure all components render correctly:

```dart
testWidgets('Widget Gallery renders all tabs', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* ... */],
      child: MaterialApp(
        home: WidgetGalleryScreen(),
      ),
    ),
  );
  
  // Verify tabs exist
  expect(find.text('Buttons'), findsOneWidget);
  expect(find.text('Cards'), findsOneWidget);
  // ...
  
  // Navigate through tabs
  await tester.tap(find.text('Colors'));
  await tester.pumpAndSettle();
  
  // Verify content renders
  expect(find.text('Primary'), findsWidgets);
});
```

## Syncing with Design System

When the design system changes:

1. **Update components** - Modify the actual widget implementations
2. **Verify in gallery** - Check that gallery still renders correctly
3. **Update screenshots** - If maintaining visual documentation
4. **Update this doc** - Reflect any structural changes

## File Location

```text
lib/screens/widget_gallery_screen.dart
```

## Related Documentation

- [Design Guidelines](design-guidelines.md) - Overall design principles and theming
- [Color Theming Guide](color-theming-guide.md) - Color system documentation
