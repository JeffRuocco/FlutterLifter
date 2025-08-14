import 'package:flutter_lifter/models/program_models.dart';

import 'api_response.dart';

/// Response model for program-related API calls
class ProgramResponse {
  final List<Program> programs;
  final String? message;

  const ProgramResponse({
    required this.programs,
    this.message,
  });

  factory ProgramResponse.fromJson(Map<String, dynamic> json) {
    return ProgramResponse(
      programs: (json['programs'] as List)
          .map((programJson) => Program.fromJson(programJson))
          .toList(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programs': programs.map((program) => program.toJson()).toList(),
      'message': message,
    };
  }
}

/// Response wrapper for single program
typedef SingleProgramResponse = ApiResponse<Program>;

/// Response wrapper for multiple programs
typedef ProgramListResponse = ApiResponse<List<Program>>;

/// Response wrapper for program operations (create, update, delete)
typedef ProgramOperationResponse = ApiResponse<bool>;
