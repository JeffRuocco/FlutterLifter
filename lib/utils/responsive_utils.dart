import 'package:flutter/material.dart';

/// Utility class for responsive design helpers
class ResponsiveUtils {
  /// Check if the screen is considered small (mobile)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if the screen is considered medium (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if the screen is considered large (desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Get the number of grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isLargeScreen(context)) return 4;
    if (isMediumScreen(context)) return 3;
    return 2; // Small screen
  }

  /// Get appropriate card aspect ratio based on screen size
  static double getCardAspectRatio(BuildContext context) {
    if (isSmallScreen(context)) return 0.9;
    if (isMediumScreen(context)) return 1.1;
    return 1.2; // Large screen
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isSmallScreen(context)) return const EdgeInsets.all(16);
    if (isMediumScreen(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32); // Large screen
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {bool isLarge = false}) {
    if (isSmallScreen(context)) {
      return isLarge ? 24 : 20;
    }
    return isLarge ? 32 : 24;
  }

  /// Check if the current platform is web
  static bool isWeb() {
    try {
      // This will throw on non-web platforms
      // ignore: avoid_web_libraries_in_flutter
      return identical(0, 0.0);
    } catch (e) {
      return false;
    }
  }

  /// Get safe area padding for mobile devices
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if the device has a notch or similar screen cutout
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 24; // Standard status bar height
  }
}
