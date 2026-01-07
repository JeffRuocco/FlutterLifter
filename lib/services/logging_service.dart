import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_lifter/models/workout_session_models.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_settings_service.dart';

/// Comprehensive logging service using Talker with Firebase Crashlytics integration
///
/// LOGGING LEVEL GUIDE:
/// ==================
///
/// VERBOSE (Most Detailed):
/// - Deep debugging and step-by-step tracing
/// - Variable states and execution flow
/// - Temporary debug code (remove before production)
/// - Only visible when verbose logging is enabled
///
/// DEBUG (Development Info):
/// - Function entry/exit points
/// - Business logic checkpoints
/// - API operations and database queries
/// - Only visible when debug or verbose logging is enabled
///
/// INFO (Important Events):
/// - User actions and application events
/// - Feature usage and system status
/// - Always visible (recommended minimum level)
///
/// WARNING (Recoverable Issues):
/// - Unexpected but handled situations
/// - Performance issues and fallback behavior
/// - Always visible, alerts developers to potential problems
///
/// ERROR (Operation Failures):
/// - Failed operations that affect user experience
/// - Reported to Firebase Crashlytics in production
/// - Always visible, requires attention
///
/// CRITICAL (Severe Problems):
/// - App instability or data loss risks
/// - High-priority Firebase Crashlytics reports
/// - Always visible, requires immediate attention
///
/// USAGE RECOMMENDATIONS:
/// - Development: Enable verbose logging for detailed debugging
/// - Testing: Use debug logging for feature verification
/// - Production: Info level minimum, warnings/errors for monitoring
/// - Support: Enable debug logging to troubleshoot user issues
class LoggingService {
  static Talker? _talker;
  static late AppSettingsService _settingsService;

  /// Get the talker instance
  static Talker get talker {
    if (_talker == null) {
      throw Exception(
        'LoggingService not initialized. Call LoggingService.init() first.',
      );
    }
    return _talker!;
  }

  /// Initialize the logging service
  static Future<void> init(AppSettingsService settingsService) async {
    _settingsService = settingsService;

    final debugModeEnabled = await _settingsService.isDebugModeEnabled();
    final debugLoggingEnabled = await _settingsService.isDebugLoggingEnabled();
    final verboseLoggingEnabled = await _settingsService
        .isVerboseLoggingEnabled();

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
      _talker!.configure(observer: CrashlyticsTalkerObserver());
    }

    // Log initialization
    _talker!.info('🚀 LoggingService initialized successfully');
    _talker!.debug('Debug mode: $debugModeEnabled');
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
      final verboseLoggingEnabled = await _settingsService
          .isVerboseLoggingEnabled();

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
      final debugLoggingEnabled = await _settingsService
          .isDebugLoggingEnabled();

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

  // Workout-specific logging methods (INFO level for major events, DEBUG for details)

  /// Log workout start (INFO level) - Major user action
  static void logWorkoutStart(String programName) {
    talker.info('🏋️ Workout started: $programName');
  }

  /// Log workout completion (INFO level) - Major milestone
  static void logWorkoutComplete(String programName, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    talker.info('✅ Workout completed: $programName in ${minutes}m ${seconds}s');
  }

  static void logWorkoutCanceled(String programName, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    talker.info(
      '❌ Workout canceled: $programName after ${minutes}m ${seconds}s',
    );
  }

  static void logWorkoutPaused(String programName) {
    talker.info('⏸️ Workout paused: $programName');
  }

  static void logWorkoutResumed(String programName) {
    talker.info('▶️ Workout resumed: $programName');
  }

  /// Will log entire contents of [updatedWorkout].
  static void logWorkoutUpdated(
    String programName, {
    WorkoutSession? updatedWorkout,
  }) {
    if (updatedWorkout != null) {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(updatedWorkout.toJson());
      talker.info('🔄 Workout updated: $programName\n$prettyJson');
    } else {
      talker.info('🔄 Workout updated: $programName');
    }
  }

  /// Log exercise start (DEBUG level) - Development tracking
  static void logExerciseStart(String exerciseName) {
    talker.debug('🎯 Exercise started: $exerciseName');
  }

  /// Log exercise completion (DEBUG level) - Development tracking
  static void logExerciseComplete(String exerciseName, int sets) {
    talker.debug('✅ Exercise completed: $exerciseName ($sets sets)');
  }

  /// Log individual set completion (DEBUG level) - Detailed tracking
  static void logSetComplete(
    String exerciseName,
    int setNumber,
    double? weight,
    int? reps,
  ) {
    talker.debug(
      'Set completed: $exerciseName Set $setNumber - ${weight ?? "BW"} x ${reps ?? "N/A"} reps',
    );
  }

  // Authentication logging (INFO for events, ERROR for failures)

  /// Log authentication events (INFO level) - Important user actions
  static void logAuthEvent(String event) {
    talker.info('🔐 Auth: $event');
  }

  /// Log authentication errors (ERROR level) - Critical failures
  static void logAuthError(
    String event,
    Object error, {
    StackTrace? stackTrace,
  }) {
    talker.error('🔐❌ Auth Error: $event - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '🔐❌ Auth Error: $event',
      );
    }
  }

  // API and network logging (DEBUG for requests, WARNING/ERROR for issues)

  /// Log API requests (DEBUG level) - Development tracking
  static void logApiRequest(String method, String endpoint) {
    talker.debug('🌐 API Request: $method $endpoint');
  }

  /// Log API responses (DEBUG/WARNING level) - Response tracking
  static void logApiResponse(String method, String endpoint, int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      talker.debug('🌐✅ API Success: $method $endpoint ($statusCode)');
    } else {
      talker.warning('🌐⚠️ API Warning: $method $endpoint ($statusCode)');
    }
  }

  static void logApiError(
    String method,
    String endpoint,
    Object error, {
    StackTrace? stackTrace,
  }) {
    talker.error('🌐❌ API Error: $method $endpoint - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '🌐❌ API Error: $method $endpoint',
      );
    }
  }

  // Data persistence logging
  static void logDataSave(String dataType) {
    talker.debug('💾 Data saved: $dataType');
  }

  static void logDataLoad(String dataType) {
    talker.debug('📂 Data loaded: $dataType');
  }

  static void logDataError(
    String operation,
    String dataType,
    Object error, {
    StackTrace? stackTrace,
  }) {
    talker.error('💾❌ Data Error: $operation $dataType - $error');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: '💾❌ Data Error: $operation $dataType',
      );
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

  /// VERBOSE: Most detailed logging for deep debugging and tracing
  ///
  /// Use for:
  /// - Detailed execution flow tracing
  /// - Variable state changes during complex operations
  /// - Step-by-step algorithm execution
  /// - Fine-grained performance measurements
  /// - Temporary debugging that should be removed before production
  ///
  /// Example: "Processing workout set 3/5, current weight: 135kg, target reps: 8"
  static void verbose(String message) {
    talker.verbose(message);
  }

  /// DEBUG: Development and troubleshooting information
  ///
  /// Use for:
  /// - Function entry/exit points
  /// - Key business logic checkpoints
  /// - API request/response summaries
  /// - Database operations
  /// - Navigation events
  /// - Configuration values
  ///
  /// Example: "Exercise started: Bench Press", "API Request: GET /workouts"
  static void debug(String message) {
    talker.debug(message);
  }

  /// INFO: Important application events and user actions
  ///
  /// Use for:
  /// - User-initiated actions (workout started, exercise completed)
  /// - Application lifecycle events (app started, paused, resumed)
  /// - Major feature usage (authentication success, data sync)
  /// - Business logic milestones (workout completed, goal achieved)
  /// - System status changes (network connectivity, permissions)
  ///
  /// Example: "Workout started: Push Day", "User logged in successfully"
  static void info(String message) {
    talker.info(message);
  }

  /// WARNING: Unexpected but recoverable situations
  ///
  /// Use for:
  /// - Deprecated feature usage
  /// - Fallback behavior activation
  /// - Performance degradation
  /// - Non-critical API failures (retries available)
  /// - Data validation issues that can be corrected
  /// - Resource constraints (low memory, slow network)
  ///
  /// Example: "API timeout, retrying in 3 seconds", "Using cached data due to network issue"
  static void warning(String message) {
    talker.warning(message);
  }

  /// ERROR: Failures that prevent normal operation but app can continue
  ///
  /// Use for:
  /// - API failures that affect user experience
  /// - Database operation failures
  /// - File I/O errors
  /// - Authentication failures
  /// - Data corruption or validation failures
  /// - Network errors that break functionality
  ///
  /// Note: Automatically reported to Firebase Crashlytics in production
  /// Example: "Failed to save workout data", "Authentication token expired"
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    talker.error(message);
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }
  }

  /// CRITICAL: Severe errors that may cause app instability or data loss
  ///
  /// Use for:
  /// - Unhandled exceptions that crash features
  /// - Data corruption that affects core functionality
  /// - Security breaches or unauthorized access
  /// - Memory leaks or resource exhaustion
  /// - Database corruption
  /// - Critical API failures (payment processing, user data)
  ///
  /// Note: Automatically reported to Firebase Crashlytics in production with high priority
  /// Example: "Unable to initialize core services", "Critical user data corruption detected"
  static void critical(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    talker.critical(message);
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }
  }

  // Utility methods with specific use cases

  /// Log user-initiated actions (INFO level)
  ///
  /// Use for tracking user behavior and feature usage:
  /// - Button clicks, menu selections
  /// - Settings changes, preference updates
  /// - Feature activations, mode switches
  ///
  /// Example: "User enabled dark mode", "Debug logging disabled"
  static void logUserAction(String action) {
    talker.info('👤 User Action: $action');
  }

  /// Log business logic operations (DEBUG level)
  ///
  /// Use for tracking internal application logic:
  /// - Algorithm executions, calculations
  /// - State machine transitions
  /// - Business rule validations
  ///
  /// Example: "Calculating workout progress", "Validating exercise form"
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

    final logs = _talker!.history
        .map((log) {
          return log.generateTextMessage();
        })
        .join('\n');

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
        information: ['Log Level: ${err.logLevel}', 'Title: ${err.title}'],
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
      information: ['Log Level: ${err.logLevel}', 'Title: ${err.title}'],
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
