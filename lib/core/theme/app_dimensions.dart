import 'package:flutter/material.dart';

/// App Spacing - Consistent spacing values throughout the app
class AppSpacing {
  // Base spacing unit (8dp grid system)
  static const double base = 8.0;

  // Spacing Scale
  static const double xs = base * 0.5; // 4
  static const double sm = base * 1; // 8
  static const double md = base * 2; // 16
  static const double lg = base * 3; // 24
  static const double xl = base * 4; // 32
  static const double xxl = base * 6; // 48
  static const double xxxl = base * 8; // 64

  // Semantic spacing
  static const double none = 0;
  static const double tiny = xs; // 4
  static const double small = sm; // 8
  static const double medium = md; // 16
  static const double large = lg; // 24
  static const double extraLarge = xl; // 32
  static const double huge = xxl; // 48
  static const double massive = xxxl; // 64

  // Component-specific spacing
  static const double cardPadding = md; // 16
  static const double screenPadding = lg; // 24
  static const double sectionSpacing = xl; // 32
  static const double listItemSpacing = sm; // 8
  static const double buttonSpacing = md; // 16
  static const double formSpacing = md; // 16
  static const double iconSpacing = sm; // 8
}

/// App Dimensions - Common sizes for UI elements
class AppDimensions {
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusRound = 24.0;

  // Button Heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 56.0;

  // Input Field Heights
  static const double inputHeightSmall = 40.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightLarge = 56.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Avatar Sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXLarge = 96.0;

  // Card Dimensions
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = borderRadiusLarge;

  // Button Dimensions
  static const double buttonRadius = borderRadiusMedium;

  // App Bar Height
  static const double appBarHeight = 56.0;

  // Bottom Navigation Height
  static const double bottomNavHeight = 64.0;

  // Fitness-specific dimensions
  static const double exerciseCardHeight = 120.0;
  static const double workoutCardHeight = 200.0;
  static const double progressBarHeight = 8.0;
  static const double timerSize = 200.0;
}

/// App Shadows - Consistent elevation and shadow styles
class AppShadows {
  static const BoxShadow light = BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: 0,
  );

  static const BoxShadow heavy = BoxShadow(
    color: Color(0x26000000),
    offset: Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  // Shadow Lists
  static const List<BoxShadow> cardShadow = [light];
  static const List<BoxShadow> modalShadow = [medium];
  static const List<BoxShadow> popupShadow = [heavy];
}

/// App Durations - Consistent animation timings
class AppDurations {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 750);

  // Specific animations
  static const Duration buttonPress = fast;
  static const Duration pageTransition = medium;
  static const Duration loadingAnimation = slow;
  static const Duration slideAnimation = medium;
  static const Duration fadeAnimation = fast;
}

/// App Curves - Consistent animation curves
class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve decelerated = Curves.easeOut;
  static const Curve accelerated = Curves.easeIn;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
}
