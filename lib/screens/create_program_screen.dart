import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/theme_utils.dart';

/// The main screen for creating a new workout program.
class CreateProgramScreen extends StatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Program creation data
  String _programName = '';
  String _programGoal = '';
  int _daysPerWeek = 3;
  int _sessionDuration = 60;
  String _experienceLevel = 'Beginner';

  final List<String> _goals = [
    'Build Muscle',
    'Lose Weight',
    'Gain Strength',
    'Improve Endurance',
    'General Fitness',
  ];

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Program',
          style: AppTextStyles.headlineMedium.copyWith(
            color: context.onSurface,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.onSurface),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNameStep(),
                _buildGoalStep(),
                _buildScheduleStep(),
                _buildExperienceStep(),
                _buildSummaryStep(),
              ],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: List.generate(5, (index) {
          bool isActive = index <= _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < 4 ? AppSpacing.xs : 0,
              ),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? context.primaryColor
                    : context.outlineColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Name',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Give your program a memorable name',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextFormField(
            labelText: 'Program Name',
            hintText: 'e.g., "My Custom Routine"',
            onChanged: (value) {
              setState(() {
                _programName = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Goal',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What\'s your main fitness objective?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...(_goals.map((goal) => _buildGoalOption(goal))),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String goal) {
    bool isSelected = _programGoal == goal;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: isSelected ? context.primaryColor.withValues(alpha: 0.1) : null,
        onTap: () {
          setState(() {
            _programGoal = goal;
          });
        },
        child: Row(
          children: [
            HugeIcon(
              icon: isSelected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              color: isSelected ? context.primaryColor : context.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              goal,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? context.primaryColor : context.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How often do you want to train?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Days per week
          Text(
            'Days per week: $_daysPerWeek',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _daysPerWeek.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            onChanged: (value) {
              setState(() {
                _daysPerWeek = value.round();
              });
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // Session duration
          Text(
            'Session duration: $_sessionDuration minutes',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _sessionDuration.toDouble(),
            min: 30,
            max: 120,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _sessionDuration = value.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience Level',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What\'s your training experience?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...(_experienceLevels.map((level) => _buildExperienceOption(level))),
        ],
      ),
    );
  }

  Widget _buildExperienceOption(String level) {
    bool isSelected = _experienceLevel == level;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: isSelected ? context.primaryColor.withValues(alpha: 0.1) : null,
        onTap: () {
          setState(() {
            _experienceLevel = level;
          });
        },
        child: Row(
          children: [
            HugeIcon(
              icon: isSelected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              color: isSelected ? context.primaryColor : context.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              level,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? context.primaryColor : context.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Summary',
            style: AppTextStyles.headlineMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review your program details',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Program Name',
                    _programName.isEmpty ? 'Not set' : _programName),
                _buildSummaryRow(
                    'Goal', _programGoal.isEmpty ? 'Not set' : _programGoal),
                _buildSummaryRow('Frequency', '$_daysPerWeek days per week'),
                _buildSummaryRow(
                    'Duration', '$_sessionDuration minutes per session'),
                _buildSummaryRow('Experience', _experienceLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                text: 'Back',
                type: AppButtonType.outlined,
                onPressed: _goBack,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: _currentStep == 4 ? 'Create Program' : 'Next',
              onPressed: _canProceed() ? _goNext : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _programName.isNotEmpty;
      case 1:
        return _programGoal.isNotEmpty;
      case 2:
      case 3:
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goNext() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Create the program
      _createProgram();
    }
  }

  void _createProgram() {
    showSuccessMessage(
        context, 'Program "$_programName" created successfully!');
    context.pop();
  }
}
