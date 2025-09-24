import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/service_locator.dart';
import 'services/logging_service.dart';
// Conditional import for web-specific functionality
import 'utils/web_theme_helper.dart'
    if (dart.library.html) 'utils/web_theme_helper_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught errors from the framework to Crashlytics in release mode
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Initialize service locator
  await serviceLocator.init();

  // Log app startup
  LoggingService.logAppEvent('App started');

  // Set initial PWA theme color
  if (kIsWeb) {
    WebThemeHelper.setMetaThemeColor(
        AppTheme.lightTheme.appBarTheme.backgroundColor?.toHex() ?? '#FFFFFF');
  }

  runApp(const FlutterLifterApp());
}

extension ColorHex on Color {
  String toHex() {
    final int argbValue = ((a * 255).round() << 24) |
        ((r * 255).round() << 16) |
        ((g * 255).round() << 8) |
        (b * 255).round();
    // Convert to hex
    return '#${argbValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

class FlutterLifterApp extends StatelessWidget {
  const FlutterLifterApp({super.key});

  /// Sets the PWA theme color for supported platforms
  void setMetaThemeColor(Color color) {
    if (kIsWeb) {
      WebThemeHelper.setMetaThemeColor(color.toHex());
    }
  }

  // TODO: Implement route guard for home screen

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
