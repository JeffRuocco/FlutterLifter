import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_info.dart';

/// Provider for NetworkInfo
///
/// Currently uses MockNetworkInfo for development.
/// In production, this would use NetworkInfoImpl with connectivity_plus.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return const MockNetworkInfo(isConnected: true);
});

/// StreamProvider for connectivity status
///
/// Emits true when connected, false when disconnected.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.connectivityStream;
});

/// FutureProvider for current connectivity status
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.isConnected;
});
