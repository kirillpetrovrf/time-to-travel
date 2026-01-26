import 'package:equatable/equatable.dart';

/// Base failure class for error handling using Either monad
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => 'Failure: $message';
}

/// Failure when server returns an error
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'ServerFailure: $message (statusCode: $statusCode)';
}

/// Failure when network connection is unavailable
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'NetworkFailure: $message';
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'CacheFailure: $message';
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'AuthFailure: $message';
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'ValidationFailure: $message';
}

/// Failure when resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.statusCode = 404,
  });

  @override
  String toString() => 'NotFoundFailure: $message';
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.statusCode,
  });

  @override
  String toString() => 'UnknownFailure: $message';
}
