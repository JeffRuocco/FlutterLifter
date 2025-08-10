import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const FlutterLifterApp());
}

class FlutterLifterApp extends StatelessWidget {
  const FlutterLifterApp({super.key});

  // TODO: route to login page if user is not authenticated

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterLifter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}
