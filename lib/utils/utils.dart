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

/// Extension to convert Color to hex string
extension ColorHex on Color {
  String toHex() {
    final int argbValue = ((a * 255).round() << 24) |
        ((r * 255).round() << 16) |
        ((g * 255).round() << 8) |
        (b * 255).round();
    // Convert to hex
    return '#${argbValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
