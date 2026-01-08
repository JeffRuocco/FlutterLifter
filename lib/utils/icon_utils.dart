/// Utility types and functions for HugeIcons 1.x integration
///
/// HugeIcons 1.x uses a JSON-based icon format instead of IconData.
/// This file provides type aliases and utilities for cleaner code.
library;

/// Type alias for HugeIcons 1.x icon data format.
///
/// HugeIcons 1.x represents icons as JSON structures (`List<List<dynamic>>`)
/// instead of Flutter's `IconData`. Use this type for HugeIcon parameters.
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget {
///   final HugeIconData icon;
///
///   const MyWidget({required this.icon});
///
///   @override
///   Widget build(BuildContext context) {
///     return HugeIcon(icon: icon, color: Colors.blue);
///   }
/// }
/// ```
typedef HugeIconData = List<List<dynamic>>;
