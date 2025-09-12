/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const AppException(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => message;
}

/// Thrown when a required permission is not granted
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([String message = 'Permission denied'])
      : super(message);
}

/// Thrown when a file operation fails
class FileOperationException extends AppException {
  const FileOperationException(String message, [dynamic error, StackTrace? stackTrace])
      : super(message, error, stackTrace);
}

/// Thrown when a file already exists
class FileExistsException extends FileOperationException {
  const FileExistsException([String message = 'File already exists'])
      : super(message);
}

/// Thrown when a file is not found
class FileNotFoundException extends FileOperationException {
  const FileNotFoundException([String message = 'File not found'])
      : super(message);
}

/// Thrown when there's a network related error
class NetworkException extends AppException {
  const NetworkException([String message = 'Network error occurred'])
      : super(message);
}

/// Thrown when there's a problem with the API response
class ApiException extends AppException {
  final int? statusCode;
  final dynamic responseData;

  const ApiException(
    String message, {
    this.statusCode,
    this.responseData,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(
          message,
          error,
          stackTrace,
        );
}
