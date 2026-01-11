/// Utility functions for date formatting across the app.
///
/// This file centralizes date formatting logic to ensure consistent behavior
/// and maintain DRY principles throughout the application.
class DateFormatUtils {
  DateFormatUtils._();

  /// Formats a date as a relative time string (e.g., "Today", "Yesterday", "3 days ago").
  ///
  /// Used for displaying when a program was last used or when an activity occurred.
  ///
  /// Returns relative descriptions for recent dates:
  /// - Same day: "Today"
  /// - Previous day: "Yesterday"
  /// - Less than 7 days: "X days ago"
  /// - Less than 30 days: "X week(s) ago"
  /// - Less than 365 days: "X month(s) ago"
  /// - More than 365 days: "X year(s) ago"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Formats a date as a relative time string with "Used" prefix.
  ///
  /// Convenience method for displaying program usage times.
  /// Example: "Used today", "Used yesterday", "Used 3 days ago"
  static String formatLastUsed(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Used today';
    } else if (difference.inDays == 1) {
      return 'Used yesterday';
    } else if (difference.inDays < 7) {
      return 'Used ${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Used ${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Used ${months}mo ago';
    }
  }

  /// Formats a date as "Mon DD, YYYY" (e.g., "Jan 15, 2024").
  ///
  /// Used for displaying absolute dates like cycle start/end dates.
  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
