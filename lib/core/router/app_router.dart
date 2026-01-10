import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/programs_screen.dart';
import '../../screens/create_program_screen.dart';
import '../../screens/program_library_screen.dart';
import '../../screens/program_detail_screen.dart';
import '../../screens/workout_screen.dart';
import '../../screens/progress_screen.dart';
import '../../screens/exercise_library_screen.dart';
import '../../screens/exercise_detail_screen.dart';
import '../../screens/exercise_history_screen.dart';
import '../../screens/create_exercise_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/debug_settings_screen.dart';
import '../../screens/widget_gallery_screen.dart';
import '../../screens/theme_editor_screen.dart';
import '../../widgets/app_shell.dart';
import '../theme/app_dimensions.dart';

/// Route paths used throughout the application
class AppRoutes {
  // Auth routes
  static const String login = '/login';

  // Main shell routes (with bottom navigation)
  static const String home = '/';
  static const String programs = '/programs';
  static const String exercises = '/exercises';
  static const String workout = '/workout';
  static const String progress = '/progress';

  // Nested routes (outside bottom nav)
  static const String createProgram = '/programs/create';
  static const String programLibrary = '/programs/library';
  static const String programDetail = '/programs/:id';
  static const String editProgram = '/programs/:id/edit';
  static const String exerciseDetail = '/exercises/:id';
  static const String exerciseHistory = '/exercises/:id/history';
  static const String createExercise = '/exercises/create';
  static const String editExercise = '/exercises/:id/edit';
  static const String settings = '/settings';
  static const String debugSettings = '/settings/debug';
  static const String widgetGallery = '/settings/widget-gallery';
  static const String themeEditor = '/settings/theme-editor';

  // Private constructor to prevent instantiation
  AppRoutes._();
}

/// Global navigator keys for nested navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      // Login route (outside shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppDurations.medium,
        ),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppDurations.fast,
            ),
          ),

          // Programs tab
          GoRoute(
            path: AppRoutes.programs,
            name: 'programs',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProgramsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppDurations.fast,
            ),
            routes: [
              // Create program (nested, but uses root navigator)
              GoRoute(
                path: 'create',
                name: 'createProgram',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const CreateProgramScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: AppCurves.standard,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: AppDurations.medium,
                ),
              ),
              // Program library (nested, but uses root navigator)
              GoRoute(
                path: 'library',
                name: 'programLibrary',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ProgramLibraryScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: AppCurves.standard,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: AppDurations.medium,
                ),
              ),
              // Program detail (nested, but uses root navigator)
              GoRoute(
                path: ':id',
                name: 'programDetail',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final programId = state.pathParameters['id']!;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: ProgramDetailScreen(programId: programId),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: AppCurves.standard,
                                  ),
                                ),
                            child: child,
                          );
                        },
                    transitionDuration: AppDurations.medium,
                  );
                },
                routes: [
                  // Edit program (nested, but uses root navigator)
                  GoRoute(
                    path: 'edit',
                    name: 'editProgram',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final programId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: CreateProgramScreen(programId: programId),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: AppCurves.standard,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                        transitionDuration: AppDurations.medium,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Exercises tab
          GoRoute(
            path: AppRoutes.exercises,
            name: 'exercises',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ExerciseLibraryScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppDurations.fast,
            ),
            routes: [
              // Create exercise (nested, but uses root navigator)
              GoRoute(
                path: 'create',
                name: 'createExercise',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const CreateExerciseScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: AppCurves.standard,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: AppDurations.medium,
                ),
              ),
              // Exercise detail (nested, but uses root navigator)
              GoRoute(
                path: ':id',
                name: 'exerciseDetail',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final exerciseId = state.pathParameters['id']!;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: ExerciseDetailScreen(exerciseId: exerciseId),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: AppCurves.standard,
                                  ),
                                ),
                            child: child,
                          );
                        },
                    transitionDuration: AppDurations.medium,
                  );
                },
                routes: [
                  // Edit exercise (nested, but uses root navigator)
                  GoRoute(
                    path: 'edit',
                    name: 'editExercise',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final exerciseId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: CreateExerciseScreen(exerciseId: exerciseId),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: AppCurves.standard,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                        transitionDuration: AppDurations.medium,
                      );
                    },
                  ),
                  // Exercise history (nested, but uses root navigator)
                  GoRoute(
                    path: 'history',
                    name: 'exerciseHistory',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final exerciseId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ExerciseHistoryScreen(exerciseId: exerciseId),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: AppCurves.standard,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                        transitionDuration: AppDurations.medium,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Workout tab
          GoRoute(
            path: AppRoutes.workout,
            name: 'workout',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WorkoutScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppDurations.fast,
            ),
          ),

          // Progress tab
          GoRoute(
            path: AppRoutes.progress,
            name: 'progress',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProgressScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppDurations.fast,
            ),
          ),
        ],
      ),

      // Settings routes (outside shell, full screen)
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppCurves.standard,
                    ),
                  ),
              child: child,
            );
          },
          transitionDuration: AppDurations.medium,
        ),
        routes: [
          GoRoute(
            path: 'debug',
            name: 'debugSettings',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DebugSettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: AppCurves.standard,
                            ),
                          ),
                      child: child,
                    );
                  },
              transitionDuration: AppDurations.medium,
            ),
          ),
          GoRoute(
            path: 'widget-gallery',
            name: 'widgetGallery',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WidgetGalleryScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: AppCurves.standard,
                            ),
                          ),
                      child: child,
                    );
                  },
              transitionDuration: AppDurations.medium,
            ),
          ),
          GoRoute(
            path: 'theme-editor',
            name: 'themeEditor',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) {
              final editThemeId = state.uri.queryParameters['editThemeId'];
              return CustomTransitionPage(
                key: state.pageKey,
                child: ThemeEditorScreen(editThemeId: editThemeId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: AppCurves.standard,
                              ),
                            ),
                        child: child,
                      );
                    },
                transitionDuration: AppDurations.medium,
              );
            },
          ),
        ],
      ),
    ],

    // Error page
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

/// Extension on BuildContext for convenient navigation
extension AppRouterExtension on BuildContext {
  /// Navigate to login screen
  void goToLogin() => go(AppRoutes.login);

  /// Navigate to home screen
  void goToHome() => go(AppRoutes.home);

  /// Navigate to programs screen
  void goToPrograms() => go(AppRoutes.programs);

  /// Navigate to exercises library screen
  void goToExercises() => go(AppRoutes.exercises);

  /// Navigate to workout screen
  void goToWorkout() => go(AppRoutes.workout);

  /// Navigate to progress screen
  void goToProgress() => go(AppRoutes.progress);

  /// Navigate to settings screen
  void goToSettings() => go(AppRoutes.settings);

  /// Navigate to debug settings screen
  void goToDebugSettings() => go(AppRoutes.debugSettings);

  /// Navigate to widget gallery screen
  void goToWidgetGallery() => go(AppRoutes.widgetGallery);

  /// Navigate to create program screen
  void goToCreateProgram() => go(AppRoutes.createProgram);

  /// Push settings screen (for back navigation)
  void pushSettings() => push(AppRoutes.settings);

  /// Push create program screen (for back navigation)
  void pushCreateProgram() => push(AppRoutes.createProgram);

  /// Push exercise detail screen (for back navigation)
  void pushExerciseDetail(String exerciseId) =>
      push('${AppRoutes.exercises}/$exerciseId');

  /// Push create exercise screen (for back navigation)
  Future<void> pushCreateExercise() async =>
      await push(AppRoutes.createExercise);

  /// Push edit exercise screen (for back navigation)
  Future<void> pushEditExercise(String exerciseId) async =>
      await push('${AppRoutes.exercises}/$exerciseId/edit');

  /// Push exercise history screen (for back navigation)
  Future<void> pushExerciseHistory(String exerciseId) async =>
      await push('${AppRoutes.exercises}/$exerciseId/history');

  /// Push program library screen (for back navigation)
  void pushProgramLibrary() => push(AppRoutes.programLibrary);

  /// Push program detail screen (for back navigation)
  void pushProgramDetail(String programId) =>
      push('${AppRoutes.programs}/$programId');

  /// Push edit program screen (for back navigation)
  Future<void> pushEditProgram(String programId) async =>
      await push('${AppRoutes.programs}/$programId/edit');

  /// Navigate to theme editor screen
  Future<void> goToThemeEditor({String? editThemeId}) async {
    if (editThemeId != null) {
      await push('${AppRoutes.themeEditor}?editThemeId=$editThemeId');
    } else {
      push(AppRoutes.themeEditor);
    }
  }
}
