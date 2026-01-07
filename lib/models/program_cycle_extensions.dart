import 'package:flutter/widgets.dart';
import 'package:flutter_lifter/models/program_models.dart';
import 'package:flutter_lifter/models/shared_enums.dart';
import 'package:flutter_lifter/utils/icon_utils.dart';

/// Extension methods for easier access to program details from cycles
extension ProgramCycleExtensions on ProgramCycle {
  /// Gets the program name if the program is loaded
  String? get programName => program?.name;

  /// Gets the program type if the program is loaded
  ProgramType? get programType => program?.type;

  /// Gets the program difficulty if the program is loaded
  ProgramDifficulty? get programDifficulty => program?.difficulty;

  /// Checks if the cycle has access to the full program details
  bool get hasProgramDetails => program != null;

  /// Gets the effective periodicity (cycle's periodicity or program's default)
  WorkoutPeriodicity? get effectivePeriodicity =>
      periodicity ?? program?.defaultPeriodicity;

  /// Gets the program description if the program is loaded
  String? get programDescription => program?.description;

  /// Gets the program tags if the program is loaded
  List<String> get programTags => program?.tags ?? [];

  /// Gets the program image URL if the program is loaded
  String? get programImageUrl => program?.imageUrl;

  /// Checks if this cycle belongs to a public program
  bool get isFromPublicProgram => program?.isPublic ?? false;

  /// Gets the program creator if the program is loaded
  String? get programCreator => program?.createdBy;

  /// Gets the program creation date if the program is loaded
  DateTime? get programCreatedAt => program?.createdAt;

  /// Gets the program color if the program is loaded
  Color? programColor(BuildContext context) => program?.getColor(context);

  /// Gets the program icon
  HugeIconData? get programIcon => program?.icon;
}
