import 'package:flutter/material.dart';

class Utils {
  /// Generate a unique identifier string.
  static String generateId() {
    // Using timestamp + random for better uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (UniqueKey().hashCode & 0xFFFFFF).toRadixString(16);
    return '${timestamp}_$random';
  }
}
