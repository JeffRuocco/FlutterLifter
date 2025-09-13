/// Represents the result of a set operation
abstract class OperationResult {
  final String message;
  const OperationResult({required this.message});
}

/// Operation completed successfully
class OperationSuccess extends OperationResult {
  const OperationSuccess({
    required super.message,
  });
}

/// Operation failed with an error
class OperationError extends OperationResult {
  final Exception? exception;

  const OperationError({
    required super.message,
    this.exception,
  });
}

/// Operation requires user confirmation or warning
class OperationWarning extends OperationResult {
  const OperationWarning({
    required super.message,
  });
}

/// Operation requires user confirmation or warning
class OperationInfo extends OperationResult {
  const OperationInfo({
    required super.message,
  });
}
