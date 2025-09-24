// Web-specific implementation using modern package:web
import 'package:flutter/foundation.dart';
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:web/web.dart' as web;

class WebThemeHelper {
  static void setMetaThemeColor(String hexColor) {
    try {
      if (!kIsWeb) {
        return; // Safety check to ensure this runs only on web
      }
      // Remove existing theme-color meta tags
      final existingTags =
          web.document.querySelectorAll('meta[name="theme-color"]');
      existingTags.toList().forEach((element) {
        (element as web.Element?)?.remove();
      });

      // Create and add new theme-color meta tag
      final metaTag = web.document.createElement('meta') as web.HTMLMetaElement;
      metaTag.name = 'theme-color';
      metaTag.content = hexColor;
      web.document.head?.appendChild(metaTag);
    } catch (e) {
      // Silently handle any errors to prevent app crashes
      LoggingService.logAppEvent('Error setting meta theme color: $e');
    }
  }
}
