// Web-specific implementation using modern package:web
import 'package:flutter_lifter/services/logging_service.dart';
import 'package:web/web.dart' as web;

class WebThemeHelper {
  static void setMetaThemeColor(String hexColor) {
    try {
      // Remove existing theme-color meta tags
      final existingTags =
          web.document.querySelectorAll('meta[name="theme-color"]');
      for (int i = 0; i < existingTags.length; i++) {
        final element = existingTags.item(i) as web.Element?;
        element?.remove();
      }

      // Create and add new theme-color meta tag
      final metaTag = web.document.createElement('meta') as web.HTMLMetaElement;
      metaTag.name = 'theme-color';
      metaTag.content = hexColor;
      web.document.head?.appendChild(metaTag);

      // Also update Apple status bar style for iOS PWAs
      final appleTags = web.document.querySelectorAll(
          'meta[name="apple-mobile-web-app-status-bar-style"]');
      for (int i = 0; i < appleTags.length; i++) {
        final element = appleTags.item(i) as web.Element?;
        element?.remove();
      }

      // Create and add new Apple meta tag
      final appleMetaTag =
          web.document.createElement('meta') as web.HTMLMetaElement;
      appleMetaTag.name = 'apple-mobile-web-app-status-bar-style';
      appleMetaTag.content = 'default';
      web.document.head?.appendChild(appleMetaTag);
    } catch (e) {
      // Silently handle any errors to prevent app crashes
      LoggingService.logAppEvent('Error setting meta theme color: $e');
    }
  }
}
