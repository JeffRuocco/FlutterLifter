import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/providers/custom_theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'services/logging_service.dart';
import 'services/app_settings_service.dart';
import 'utils/utils.dart';
// Conditional import for web-specific functionality
import 'utils/web_theme_helper.dart'
    if (dart.library.js) 'utils/web_theme_helper_web.dart';

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

  // Initialize SharedPreferences for theme persistence
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize app settings service for logging
  final settingsService = AppSettingsService();
  await settingsService.init();
  await LoggingService.init(settingsService);

  // Log app startup
  LoggingService.logAppEvent('App started');

  // Set initial PWA theme color
  WebThemeHelper.setMetaThemeColor(
      AppTheme.lightTheme.appBarTheme.backgroundColor?.toHex() ?? '#FFFFFF');

  runApp(
    ProviderScope(
      overrides: [
        // Override theme mode notifier with initialized SharedPreferences
        themeModeNotifierProvider.overrideWith(
          (ref) => ThemeModeNotifier(sharedPreferences),
        ),
        // Override custom theme providers
        ...createThemeProviderOverrides(sharedPreferences),
      ],
      child: const FlutterLifterApp(),
    ),
  );
}

class FlutterLifterApp extends ConsumerWidget {
  const FlutterLifterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    // Watch for custom theme changes and get dynamic themes
    final lightTheme = ref.watch(dynamicLightThemeProvider);
    final darkTheme = ref.watch(dynamicDarkThemeProvider);

    return MaterialApp.router(
      title: 'FlutterLifter',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
