import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/config/auth_config.dart';
import 'package:flutter_lifter/core/providers/auth_providers.dart';
import 'package:flutter_lifter/core/theme/app_theme.dart';
import 'package:flutter_lifter/core/theme/theme_provider.dart';
import 'package:flutter_lifter/screens/login_screen.dart';

/// Test-only [AuthNotifier] that doesn't depend on Firebase.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated;
}

/// Helper to build the login screen inside a testable widget tree.
Future<void> pumpLoginScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createThemeModeProviderOverride(prefs),
        authNotifierProvider.overrideWith(_TestAuthNotifier.new),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    ),
  );

  // Let animations render
  await tester.pump(const Duration(milliseconds: 1500));
}

void main() {
  group('LoginScreen', () {
    testWidgets('shows key UI elements', (tester) async {
      await pumpLoginScreen(tester);

      expect(find.text('FlutterLifter'), findsOneWidget);
      expect(find.text('Your Personal Fitness Journey'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('empty email shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      // Tap Sign In without entering anything
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('invalid email format shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('short password shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Forgot Password? opens dialog', (tester) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.text('Forgot Password?'));
      // Use pump() instead of pumpAndSettle() because the login screen has
      // a continuous Lottie animation that prevents settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send Reset Email'), findsOneWidget);
    });

    testWidgets('does not show Facebook or Apple buttons', (tester) async {
      await pumpLoginScreen(tester);

      expect(find.text('Facebook'), findsNothing);
      expect(find.text('Apple'), findsNothing);
    });
  });
}
