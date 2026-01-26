/// Base exception class for application
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'ServerException: $message (statusCode: $statusCode)';
}

/// Exception thrown when network connection fails
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when cache operations fail
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when resource not found
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.data,
  });

  @override
  String toString() => 'NotFoundException: $message';
}
