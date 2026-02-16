// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_lifter/config/auth_config.dart';
import 'package:flutter_lifter/core/providers/auth_providers.dart';
import 'package:flutter_lifter/core/theme/app_theme.dart';
import 'package:flutter_lifter/core/theme/theme_provider.dart';
import 'package:flutter_lifter/screens/login_screen.dart';

/// A test AuthNotifier that starts in unauthenticated state
/// without needing Firebase.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated;
}

void main() {
  testWidgets('Login page loads correctly', (WidgetTester tester) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createThemeModeProviderOverride(prefs),
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Pump enough frames for the initial animations to render
    // (Using pump with duration instead of pumpAndSettle because
    // the login screen has continuous animations that never settle)
    await tester.pump(const Duration(milliseconds: 1500));

    // Verify that our login page loads with key elements.
    expect(find.text('FlutterLifter'), findsOneWidget);
    expect(find.text('Your Personal Fitness Journey'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Google sign-in button is present
    expect(find.text('Google'), findsOneWidget);

    // Verify guest mode and sign-up options
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
