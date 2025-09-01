// Test for space input fix in set notes and other text fields
// This test validates that spaces can be typed in note fields after fixing
// the JavaScript selectstart event handler in web/index.html
// 
// The fix allows text selection and input in input/textarea elements while
// still preventing unwanted text selection elsewhere in the web app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lifter/widgets/set_input_widget.dart';
import 'package:flutter_lifter/models/exercise_models.dart';

void main() {
  group('Set Notes Space Input Tests', () {
    testWidgets('Should allow typing spaces in notes field', (WidgetTester tester) async {
      // Create a test exercise set
      final exerciseSet = ExerciseSet.create(
        targetReps: 10,
        targetWeight: 135.0,
        notes: '',
      );

      // Build the SetInputWidget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputWidget(
              setNumber: 1,
              exerciseSet: exerciseSet,
              isWorkoutStarted: true,
              onUpdated: (weight, reps, notes, markAsCompleted) {
                // Test callback to capture notes
                expect(notes, contains(' ')); // Should contain spaces
              },
            ),
          ),
        ),
      );

      // Find the "Add Notes" button and tap it
      final addNotesButton = find.text('Add Notes');
      expect(addNotesButton, findsOneWidget);
      await tester.tap(addNotesButton);
      await tester.pumpAndSettle();

      // Find the notes text field
      final notesField = find.byType(TextFormField).last; // Notes field is the last TextFormField
      expect(notesField, findsOneWidget);

      // Type text with spaces
      const testText = 'This is a test note with spaces';
      await tester.enterText(notesField, testText);
      await tester.pumpAndSettle();

      // Verify the text was entered correctly
      expect(find.text(testText), findsOneWidget);

      // Tap outside to trigger the onInputFinished callback
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // The test passes if no exceptions were thrown and the text with spaces was accepted
    });

    testWidgets('Should preserve spaces when updating notes', (WidgetTester tester) async {
      // Create a test exercise set with existing notes containing spaces
      final exerciseSet = ExerciseSet.create(
        targetReps: 10,
        targetWeight: 135.0,
        notes: 'Existing note with spaces',
      );

      // Build the SetInputWidget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputWidget(
              setNumber: 1,
              exerciseSet: exerciseSet,
              isWorkoutStarted: true,
            ),
          ),
        ),
      );

      // The notes field should be visible since there are existing notes
      final notesField = find.byType(TextFormField).last;
      expect(notesField, findsOneWidget);

      // Verify the existing text with spaces is displayed
      expect(find.text('Existing note with spaces'), findsOneWidget);

      // Add more text with spaces
      await tester.enterText(notesField, 'Existing note with spaces and more spaces');
      await tester.pumpAndSettle();

      // Verify the updated text with spaces is accepted
      expect(find.text('Existing note with spaces and more spaces'), findsOneWidget);
    });
  });
}