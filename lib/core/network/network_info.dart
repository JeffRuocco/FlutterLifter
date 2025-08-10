/// Service for checking network connectivity
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
}

/// Implementation using connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  // final Connectivity connectivity;

  // NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    // TODO: Implement using connectivity_plus package
    // final result = await connectivity.checkConnectivity();
    // return result != ConnectivityResult.none;

    // For now, assume we're always connected (development)
    return true;
  }

  @override
  Stream<bool> get connectivityStream {
    // TODO: Implement connectivity stream
    // return connectivity.onConnectivityChanged.map(
    //   (result) => result != ConnectivityResult.none,
    // );

    // For now, return a stream that always emits true
    return Stream.value(true);
  }
}

/// Mock implementation for testing
class MockNetworkInfo implements NetworkInfo {
  final bool _isConnected;

  const MockNetworkInfo({bool isConnected = true}) : _isConnected = isConnected;

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Stream<bool> get connectivityStream => Stream.value(_isConnected);
}
