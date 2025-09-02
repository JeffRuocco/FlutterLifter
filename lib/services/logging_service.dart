import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_settings_service.dart';

/// Comprehensive logging service using Talker with Firebase Crashlytics integration
class LoggingService {
  static Talker? _talker;
  static late AppSettingsService _settingsService;

  /// Get the talker instance
  static Talker get talker {
    if (_talker == null) {
      throw Exception(
          'LoggingService not initialized. Call LoggingService.init() first.');
    }
    return _talker!;
  }

  /// Initialize the logging service
  static Future<void> init(AppSettingsService settingsService) async {
    _settingsService = settingsService;

    final debugLoggingEnabled = await _settingsService.isDebugLoggingEnabled();
    final verboseLoggingEnabled =
        await _settingsService.isVerboseLoggingEnabled();

    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: true,
        useConsoleLogs: debugLoggingEnabled || verboseLoggingEnabled,
        useHistory: true,
        maxHistoryItems: 1000,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          enableColors: true,
          // Set minimum log level based on debug and verbose settings
          level: _determineLogLevel(debugLoggingEnabled, verboseLoggingEnabled),
        ),
      ),
    );

    // Add Firebase Crashlytics observer for remote logging
    if (!kDebugMode) {
      _talker!.configure(
        observer: CrashlyticsTalkerObserver(),
      );
    }

    // Log initialization
    _talker!.info('🚀 LoggingService initialized successfully');
    _talker!
        .debug('Debug mode: ${await _settingsService.isDebugModeEnabled()}');
    _talker!.debug('Debug logging enabled: $debugLoggingEnabled');
    _talker!.debug('Verbose logging enabled: $verboseLoggingEnabled');
  }

  /// Determine the appropriate log level based on debug and verbose settings
  static LogLevel _determineLogLevel(bool debugEnabled, bool verboseEnabled) {
    if (verboseEnabled) {
      return LogLevel.verbose; // Show all logs including verbose
    } else if (debugEnabled) {
      return LogLevel.debug; // Show debug and above
    } else {
      return LogLevel.info; // Show info and above only
    }
  }

  /// Update logging settings when debug mode changes
  static Future<void> updateDebugLogging(bool enabled) async {
    if (_talker != null) {
      final verboseLoggingEnabled =
          await _settingsService.isVerboseLoggingEnabled();

      _talker!.configure(
        settings: _talker!.settings.copyWith(
          useConsoleLogs: enabled || verboseLoggingEnabled,
        ),
        logger: TalkerLogger(
          settings: TalkerLoggerSettings(
            enableColors: true,
            // Update log level based on both debug and verbose settings
            level: _determineLogLevel(enabled, verboseLoggingEnabled),
          ),
        ),
      );
      _talker!.info('Debug logging ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Update logging settings when verbose mode changes
  static Future<void> updateVerboseLogging(bool enabled) async {
    if (_talker != null) {
      final debugLoggingEnabled =
          await _settingsService.isDebugLoggingEnabled();

      _talker!.configure(
        settings: _talker!.settings.copyWith(
          useConsoleLogs: debugLoggingEnabled || enabled,
        ),
        logger: TalkerLogger(
          settings: TalkerLoggerSettings(
            enableColors: true,
            // Update log level based on both debug and verbose settings
            level: _determineLogLevel(debugLoggingEnabled, enabled),
          ),
        ),
      );
      _talker!.info('Verbose logging ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // Workout-specific logging methods
  static void logWorkoutStart(String programName) {
    talker.info('🏋️ Workout started: $programName');
  }

  static void logWorkoutComplete(String programName, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    talker.info('✅ Workout completed: $programName in ${minutes}m ${seconds}s');
  }

  static void logWorkoutCanceled(String programName, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    talker
        .info('❌ Workout canceled: $programName after ${minutes}m ${seconds}s');
  }

  static void logWorkoutPaused(String programName) {
    talker.info('⏸️ Workout paused: $programName');
  }

  static void logWorkoutResumed(String programName) {
    talker.info('▶️ Workout resumed: $programName');
  }

  /// Will log entire contents of [updatedWorkout].
  static void logWorkoutUpdated(String programName,
      {WorkoutSession? updatedWorkout}) {
    if (updatedWorkout != null) {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(updatedWorkout.toJson());
      talker.info('🔄 Workout updated: $programName\n$prettyJson');
    } else {
      talker.info('🔄 Workout updated: $programName');
    }
  }

  static void logExerciseStart(String exerciseName) {
    talker.debug('🎯 Exercise started: $exerciseName');
  }

  static void logExerciseComplete(String exerciseName, int sets) {
    talker.debug('✅ Exercise completed: $exerciseName ($sets sets)');
  }

  static void logSetComplete(
      String exerciseName, int setNumber, double? weight, int? reps) {
    talker.debug(
        'Set completed: $exerciseName Set $setNumber - ${weight ?? "BW"} x ${reps ?? "N/A"} reps');
  }

  // Authentication logging
  static void logAuthEvent(String event) {
    talker.info('🔐 Auth: $event');
  }

  static void logAuthError(String event, Object error,
      {StackTrace? stackTrace}) {
    talker.error('🔐❌ Auth Error: $event - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance
          .recordError(error, stackTrace, reason: '🔐❌ Auth Error: $event');
    }
  }

  // API and network logging
  static void logApiRequest(String method, String endpoint) {
    talker.debug('🌐 API Request: $method $endpoint');
  }

  static void logApiResponse(String method, String endpoint, int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      talker.debug('🌐✅ API Success: $method $endpoint ($statusCode)');
    } else {
      talker.warning('🌐⚠️ API Warning: $method $endpoint ($statusCode)');
    }
  }

  static void logApiError(String method, String endpoint, Object error,
      {StackTrace? stackTrace}) {
    talker.error('🌐❌ API Error: $method $endpoint - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace,
          reason: '🌐❌ API Error: $method $endpoint');
    }
  }

  // Data persistence logging
  static void logDataSave(String dataType) {
    talker.debug('💾 Data saved: $dataType');
  }

  static void logDataLoad(String dataType) {
    talker.debug('📂 Data loaded: $dataType');
  }

  static void logDataError(String operation, String dataType, Object error,
      {StackTrace? stackTrace}) {
    talker.error('💾❌ Data Error: $operation $dataType - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace,
          reason: '💾❌ Data Error: $operation $dataType');
    }
  }

  // Navigation logging
  static void logNavigation(String from, String to) {
    talker.debug('🧭 Navigation: $from → $to');
  }

  // Performance logging
  static void logPerformance(String operation, Duration duration) {
    talker.debug('⚡ Performance: $operation took ${duration.inMilliseconds}ms');
  }

  // General application events
  static void logAppEvent(String event) {
    talker.info('📱 App Event: $event');
  }

  // Custom logging methods for different levels
  static void verbose(String message) {
    talker.verbose(message);
  }

  static void debug(String message) {
    talker.debug(message);
  }

  static void info(String message) {
    talker.info(message);
  }

  static void warning(String message) {
    talker.warning(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    talker.error(message);
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance
          .recordError(error, stackTrace, reason: message);
    }
  }

  static void critical(String message,
      [Object? error, StackTrace? stackTrace]) {
    talker.critical(message);
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance
          .recordError(error, stackTrace, reason: message);
    }
  }

  // Utility methods
  static void logUserAction(String action) {
    talker.info('👤 User Action: $action');
  }

  static void logBusinessLogic(String operation) {
    talker.debug('🔧 Business Logic: $operation');
  }

  /// Clear all logs (useful for testing)
  static void clearLogs() {
    _talker?.cleanHistory();
    talker.info('🧹 Logs cleared');
  }

  /// Get log count for debugging
  static int get logCount => _talker?.history.length ?? 0;

  /// Export logs as string (for debugging or support)
  static String exportLogs() {
    if (_talker == null) return 'LoggingService not initialized';

    final logs = _talker!.history.map((log) {
      return log.generateTextMessage();
    }).join('\n');

    return logs;
  }
}

/// Custom Talker observer for Firebase Crashlytics integration
class CrashlyticsTalkerObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    super.onError(err);

    // Send errors to Firebase Crashlytics
    if (err.exception != null) {
      FirebaseCrashlytics.instance.recordError(
        err.exception,
        err.stackTrace,
        reason: err.message,
        information: [
          'Log Level: ${err.logLevel}',
          'Title: ${err.title}',
        ],
      );
    } else {
      // For non-exception errors, log as a custom message
      FirebaseCrashlytics.instance.log('ERROR: ${err.message}');
    }
  }

  @override
  void onException(TalkerException err) {
    super.onException(err);

    // Send exceptions to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      err.exception,
      err.stackTrace,
      reason: err.message,
      information: [
        'Log Level: ${err.logLevel}',
        'Title: ${err.title}',
      ],
    );
  }

  @override
  void onLog(TalkerData log) {
    super.onLog(log);

    // Send critical logs to Firebase Crashlytics
    if (log.logLevel?.name == 'critical') {
      FirebaseCrashlytics.instance.log('CRITICAL: ${log.message}');
    }
  }
}
