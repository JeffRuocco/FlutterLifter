import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lifter/core/theme/theme_utils.dart';
import 'package:flutter_lifter/models/operation_result.dart';

/// Handles UI responses for operations
class OperationUIHandler {
  /// Shows appropriate UI feedback based on the operation result
  static void handleResult(BuildContext context, OperationResult result) {
    switch (result.runtimeType) {
      case OperationSuccess:
        final success = result as OperationSuccess;
        HapticFeedback.mediumImpact();
        showSuccessMessage(context, success.message, duration: 2);
        break;

      case OperationInfo:
        final info = result as OperationInfo;
        HapticFeedback.lightImpact();
        showInfoMessage(context, info.message, duration: 2);
        break;

      case OperationWarning:
        final warning = result as OperationWarning;
        HapticFeedback.mediumImpact();
        showWarningMessage(context, warning.message, duration: 5);
        break;

      case OperationError:
        final error = result as OperationError;
        HapticFeedback.heavyImpact();
        showErrorMessage(context, error.message, duration: 5);
        break;
    }
  }

  /// Convenience method for handling set toggle operations
  static void handleSetToggle(BuildContext context, OperationResult result) {
    handleResult(context, result);

    // If it's a warning, you might want to prevent the action
    if (result is OperationWarning) {
      // Optionally throw an exception or return early in the calling code
      // This depends on your specific use case
    }
  }
}
