import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';

/// Provider for ApiService
///
/// Currently uses MockApiService for development.
/// In production, this would be replaced with HttpApiService.
final apiServiceProvider = Provider<ApiService>((ref) {
  return MockApiService();
});

/// Provider for production ApiService
///
/// Use this when connecting to a real backend.
final productionApiServiceProvider = Provider<ApiService>((ref) {
  return HttpApiService();
});
