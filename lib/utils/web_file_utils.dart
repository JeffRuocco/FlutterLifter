// Conditional export: uses `web_file_utils_web.dart` when compiled to web,
// otherwise falls back to a no-op stub.
export 'web_file_utils_stub.dart'
    if (dart.library.html) 'web_file_utils_web.dart';
