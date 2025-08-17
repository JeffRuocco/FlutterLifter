import 'package:flutter/material.dart';
import 'package:flutter_lifter/data/repositories/program_repository.dart';
import 'package:flutter_lifter/models/models.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';
import 'programs_screen.dart';
import 'workout_screen.dart';

// TODO: get current program and in-progress or next workout
// when user clicks "Workouts" action card, continue in progress workout or start next workout

class HomeScreen extends StatefulWidget {
  final ProgramRepository programRepository;

  const HomeScreen({super.key})
      : programRepository = const _DefaultProgramRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _DefaultProgramRepository implements ProgramRepository {
  const _DefaultProgramRepository();

  // TODO: initialize program repository from API (add production impl)
  static final ProgramRepository _instance =
      ProgramRepositoryImpl.development();

  @override
  Future<List<Program>> getPrograms() => _instance.getPrograms();

  @override
  Future<Program?> getProgramById(String id) => _instance.getProgramById(id);

  @override
  Future<void> createProgram(Program program) =>
      _instance.createProgram(program);

  @override
  Future<void> updateProgram(Program program) =>
      _instance.updateProgram(program);

  @override
  Future<void> deleteProgram(String id) => _instance.deleteProgram(id);

  @override
  Future<List<Program>> searchPrograms(String query) =>
      _instance.searchPrograms(query);

  @override
  Future<List<Program>> getProgramsByDifficulty(ProgramDifficulty difficulty) =>
      _instance.getProgramsByDifficulty(difficulty);

  @override
  Future<List<Program>> getProgramsByType(ProgramType type) =>
      _instance.getProgramsByType(type);

  @override
  Future<void> refreshCache() => _instance.refreshCache();

  @override
  Future<List<Exercise>> getExercises() => _instance.getExercises();

  @override
  Future<Exercise?> getExerciseByName(String name) =>
      _instance.getExerciseByName(name);

  @override
  Future<ProgramCycle?> getProgramCycleWithProgram(String cycleId) =>
      _instance.getProgramCycleWithProgram(cycleId);

  @override
  Future<List<ProgramCycle>> getProgramCyclesWithProgram(String programId) =>
      _instance.getProgramCyclesWithProgram(programId);
}

class _HomeScreenState extends State<HomeScreen> {
  ProgramCycle? _activeProgramCycle;

  @override
  void initState() {
    super.initState();
    _findActiveProgramCycle();
  }

  Future<void> _findActiveProgramCycle() async {
    // TODO: Implement logic to find the active program + cycle
    // For now, we'll just set a dummy value
    setState(() {
      _activeProgramCycle = ProgramCycle(
        id: '1',
        programId: '1',
        cycleNumber: 1,
        createdAt: DateTime.now(),
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now().add(Duration(days: 30)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'FlutterLifter',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: context.onSurface,
            ),
            onPressed: () {
              showInfoMessage(context, 'Profile coming soon!');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adjust layout based on screen size
              final isSmallScreen = constraints.maxHeight < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome back!',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(
                      height: isSmallScreen ? AppSpacing.xs : AppSpacing.xs),
                  Text(
                    'Ready to crush your fitness goals?',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: context.textSecondary,
                    ),
                  ),

                  SizedBox(
                      height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(
                      height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),

                  // Action Cards Grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        // Calculate if we have enough space for the current layout
                        final cardWidth =
                            (gridConstraints.maxWidth - AppSpacing.md) / 2;
                        final shouldUseCompactLayout = cardWidth < 120;

                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: shouldUseCompactLayout
                              ? 0.85
                              : (isSmallScreen ? 0.9 : 1.0),
                          children: [
                            _ActionCard(
                              title: 'Programs',
                              subtitle: 'Browse programs',
                              icon: HugeIcons.strokeRoundedDumbbell01,
                              color: context.primaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProgramsScreen(
                                        programRepository:
                                            widget.programRepository),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Workouts',
                              subtitle: 'Start workout',
                              icon: HugeIcons.strokeRoundedPlay,
                              color: context.successColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutScreen(
                                      programRepository:
                                          widget.programRepository,
                                      programId: _activeProgramCycle?.programId,
                                      programName: 'Upper/Lower',
                                      workoutDate: DateTime.now(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Progress',
                              subtitle: 'Track gains',
                              icon: HugeIcons.strokeRoundedAnalytics01,
                              color: context.infoColor,
                              onTap: () {
                                showInfoMessage(
                                    context, 'Progress tracking coming soon!');
                              },
                            ),
                            _ActionCard(
                              title: 'Exercises',
                              subtitle: 'Exercise library',
                              icon: HugeIcons.strokeRoundedMenu01,
                              color: context.warningColor,
                              onTap: () {
                                showInfoMessage(
                                    context, 'Exercise library coming soon!');
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            // Adjust icon size and spacing based on available space
            final isVerySmallCard = cardConstraints.maxWidth < 150;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isVerySmallCard ? AppSpacing.xs : AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: icon,
                    color: color,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                SizedBox(
                    height: isVerySmallCard ? AppSpacing.xs : AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Flexible(
                  flex: 2, // Give more space to subtitle
                  child: Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondary,
                      height: 1.2, // Tighter line height for better fit
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
