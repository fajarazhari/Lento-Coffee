import 'package:equatable/equatable.dart';

import 'app_exception.dart';

// Failure is the presentation-layer representation of an error.
// Services throw AppException; repositories catch and return Failure.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection.']) : super(message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Insufficient permissions.']) : super(message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class BusinessFailure extends Failure {
  const BusinessFailure(super.message);
}

// Extension to convert AppException → Failure
extension AppExceptionToFailure on AppException {
  Failure toFailure() => switch (this) {
    AuthException e          => AuthFailure(e.message),
    WrongPinException e      => AuthFailure(e.message),
    SessionExpiredException e => AuthFailure(e.message),
    NetworkException e       => NetworkFailure(e.message),
    FirestoreException e     => ServerFailure(e.message),
    UnauthorizedException e  => PermissionFailure(e.message),
    OrderNotFoundException e => NotFoundFailure(e.message),
    _ => BusinessFailure(message),
  };
}
