# Programs Feature Documentation

## Overview
The Programs feature allows users to select from predefined workout programs or create custom programs using a guided creation system.

## Features

### 🏋️ Predefined Programs
1. **Upper/Lower Split** (Intermediate, 4 days/week)
   - Alternates between upper body and lower body training days
   - Perfect for intermediate lifters who want focused muscle group training

2. **Full Body** (Beginner, 3 days/week)  
   - Complete full-body workouts targeting all major muscle groups
   - Ideal for beginners or those with limited time

3. **Push/Pull/Legs** (Advanced, 6 days/week)
   - Split by movement patterns: push, pull, and leg-focused workouts
   - Designed for advanced lifters seeking high training frequency

### 🎯 Custom Program Creation
Users can create personalized programs through a guided 5-step process:

1. **Program Name** - Give the program a memorable name
2. **Primary Goal** - Select fitness objective (Build Muscle, Lose Weight, etc.)
3. **Schedule** - Set training frequency and session duration
4. **Experience Level** - Choose appropriate difficulty level
5. **Summary** - Review and confirm program details

## Navigation Flow

```
Home Screen
    └── Programs Card
        └── Programs Screen
            ├── Predefined Program Cards (tap to select)
            └── Create Custom Program Card
                └── Create Program Screen (guided flow)
```

## Technical Implementation

### File Structure
- `screens/home_screen.dart` - Main dashboard with quick actions
- `screens/programs_screen.dart` - Program selection and overview
- `screens/create_program_screen.dart` - Guided program creation flow

### Key Components
- **AppCard** - Consistent card styling with tap interactions
- **_ProgramCard** - Displays program information with difficulty/duration chips
- **_ActionCard** - Home screen quick action cards
- **_CreateProgramCard** - Custom program creation entry point

### Theme Integration
- Uses comprehensive theme system for colors, typography, and spacing
- Proper contrast ratios for light/dark mode
- Consistent styling with app design language

## Future Enhancements
- Program templates and variations
- Exercise selection and customization
- Program scheduling and calendar integration
- Progress tracking per program
- Social sharing of custom programs
- AI-powered program recommendations

## Usage Examples

```dart
// Navigate to Programs screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ProgramsScreen(),
  ),
);

// Select a predefined program
void _selectProgram(String programName) {
  // TODO: Navigate to program details or start program
}

// Create custom program
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateProgramScreen(),
  ),
);
```

The Programs feature provides a solid foundation for workout program management in FlutterLifter, with room for extensive customization and enhancement as the app grows.
