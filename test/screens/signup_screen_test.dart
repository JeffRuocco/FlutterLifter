import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/config/auth_config.dart';
import 'package:flutter_lifter/core/providers/auth_providers.dart';
import 'package:flutter_lifter/core/theme/app_theme.dart';
import 'package:flutter_lifter/core/theme/theme_provider.dart';
import 'package:flutter_lifter/screens/signup_screen.dart';

/// Test-only [AuthNotifier] that doesn't depend on Firebase.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated;
}

/// Helper to build the signup screen inside a testable widget tree.
Future<void> pumpSignupScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createThemeModeProviderOverride(prefs),
        authNotifierProvider.overrideWith(_TestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SignupScreen(),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 1500));
}

void main() {
  group('SignupScreen', () {
    testWidgets('shows key UI elements', (tester) async {
      await pumpSignupScreen(tester);

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Start your fitness journey today'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('empty name shows validation error', (tester) async {
      await pumpSignupScreen(tester);

      // Fill email and password but leave name empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      // Scroll to show the Create Account button and tap
      await tester.ensureVisible(find.text('Create Account').last);
      await tester.tap(find.text('Create Account').last);
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('password mismatch shows validation error', (tester) async {
      await pumpSignupScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'different',
      );

      await tester.ensureVisible(find.text('Create Account').last);
      await tester.tap(find.text('Create Account').last);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      await pumpSignupScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Display Name'),
        'Alice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );

      await tester.ensureVisible(find.text('Create Account').last);
      await tester.tap(find.text('Create Account').last);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });
}
