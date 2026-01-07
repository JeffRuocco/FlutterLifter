// TODO: Implement Firebase instead of traditional APIs?

import 'package:flutter_lifter/models/program_models.dart';

/// Remote API data source for program-related operations
abstract class ProgramApiDataSource {
  Future<List<Program>> getPrograms();
  Future<Program> getProgramById(String id);
  Future<Program> createProgram(Program program);
  Future<Program> updateProgram(Program program);
  Future<void> deleteProgram(String id);
  Future<List<Program>> searchPrograms(String query);
  Future<List<Program>> getProgramsByUserId(String userId);
  Future<List<Program>> getPublicPrograms();
  Future<List<Program>> getFeaturedPrograms();
}

/// HTTP implementation of ProgramApiDataSource
class HttpProgramApiDataSource implements ProgramApiDataSource {
  // final HttpClient httpClient;
  // final String baseUrl;

  // HttpProgramApiDataSource({
  //   required this.httpClient,
  //   required this.baseUrl,
  // });

  @override
  Future<List<Program>> getPrograms() async {
    // TODO: Implement HTTP GET /api/programs
    // final response = await httpClient.get('$baseUrl/programs');
    // if (response.statusCode == 200) {
    //   final List<dynamic> data = jsonDecode(response.body);
    //   return data.map((json) => Program.fromJson(json)).toList();
    // }
    // throw ApiException('Failed to fetch programs');

    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<Program> getProgramById(String id) async {
    // TODO: Implement HTTP GET /api/programs/{id}
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<Program> createProgram(Program program) async {
    // TODO: Implement HTTP POST /api/programs
    // final response = await httpClient.post(
    //   '$baseUrl/programs',
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(program.toJson()),
    // );
    // if (response.statusCode == 201) {
    //   return Program.fromJson(jsonDecode(response.body));
    // }
    // throw ApiException('Failed to create program');

    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<Program> updateProgram(Program program) async {
    // TODO: Implement HTTP PUT /api/programs/{id}
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<void> deleteProgram(String id) async {
    // TODO: Implement HTTP DELETE /api/programs/{id}
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<List<Program>> searchPrograms(String query) async {
    // TODO: Implement HTTP GET /api/programs/search?q={query}
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<List<Program>> getProgramsByUserId(String userId) async {
    // TODO: Implement HTTP GET /api/users/{userId}/programs
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<List<Program>> getPublicPrograms() async {
    // TODO: Implement HTTP GET /api/programs/public
    throw UnimplementedError('HTTP API implementation pending');
  }

  @override
  Future<List<Program>> getFeaturedPrograms() async {
    // TODO: Implement HTTP GET /api/programs/featured
    throw UnimplementedError('HTTP API implementation pending');
  }
}

/// API Exception class for handling API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}
