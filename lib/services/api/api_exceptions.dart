/// Базовое исключение API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}

/// Ошибка сети (нет подключения)
class NetworkException extends ApiException {
  NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// 400 Bad Request
class BadRequestException extends ApiException {
  BadRequestException(super.message) : super(statusCode: 400);

  @override
  String toString() => 'BadRequestException: $message';
}

/// 401 Unauthorized
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// 403 Forbidden
class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);

  @override
  String toString() => 'ForbiddenException: $message';
}

/// 404 Not Found
class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);

  @override
  String toString() => 'NotFoundException: $message';
}

/// 409 Conflict
class ConflictException extends ApiException {
  ConflictException(super.message) : super(statusCode: 409);

  @override
  String toString() => 'ConflictException: $message';
}

/// 500 Server Error
class ServerException extends ApiException {
  ServerException(super.message) : super(statusCode: 500);

  @override
  String toString() => 'ServerException: $message';
}
