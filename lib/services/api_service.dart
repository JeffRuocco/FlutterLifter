/// Base API service for HTTP client configuration
abstract class ApiService {
  String get baseUrl;
  Map<String, String> get defaultHeaders;
  Duration get timeout;

  Future<Map<String, dynamic>> get(String endpoint);
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data);
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data);
  Future<void> delete(String endpoint);
}

/// HTTP implementation of ApiService
class HttpApiService implements ApiService {
  @override
  String get baseUrl =>
      'https://api.flutterlifter.com'; // Replace with actual API URL

  @override
  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Duration get timeout => const Duration(seconds: 30);

  @override
  Future<Map<String, dynamic>> get(String endpoint) async {
    // TODO: Implement HTTP GET using dio or http package
    // final response = await dio.get('$baseUrl$endpoint');
    // return response.data;

    throw UnimplementedError('HTTP implementation pending');
  }

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    // TODO: Implement HTTP POST
    throw UnimplementedError('HTTP implementation pending');
  }

  @override
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    // TODO: Implement HTTP PUT
    throw UnimplementedError('HTTP implementation pending');
  }

  @override
  Future<void> delete(String endpoint) async {
    // TODO: Implement HTTP DELETE
    throw UnimplementedError('HTTP implementation pending');
  }
}

/// Mock implementation for development
class MockApiService implements ApiService {
  @override
  String get baseUrl => 'http://localhost:3000';

  @override
  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
      };

  @override
  Duration get timeout => const Duration(seconds: 5);

  @override
  Future<Map<String, dynamic>> get(String endpoint) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return {'message': 'Mock GET response', 'endpoint': endpoint};
  }

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'message': 'Mock POST response',
      'endpoint': endpoint,
      'data': data
    };
  }

  @override
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {'message': 'Mock PUT response', 'endpoint': endpoint, 'data': data};
  }

  @override
  Future<void> delete(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // No return for delete
  }
}
