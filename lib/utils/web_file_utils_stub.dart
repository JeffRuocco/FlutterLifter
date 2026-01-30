import 'dart:typed_data';

/// Stub implementation for non-web platforms.
/// Calling this will throw an [UnsupportedError].
Future<void> downloadFileInBrowser(Uint8List bytes, String filename) async {
  throw UnsupportedError('downloadFileInBrowser is only supported on web');
}
