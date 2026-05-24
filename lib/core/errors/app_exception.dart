import 'package:equatable/equatable.dart';

// Base exception for all application errors
sealed class AppException extends Equatable implements Exception {
  const AppException(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

// Authentication errors
final class AuthException extends AppException {
  const AuthException(super.message);
}

final class WrongPinException extends AppException {
  const WrongPinException() : super('Incorrect PIN. Please try again.');
}

final class SessionExpiredException extends AppException {
  const SessionExpiredException() : super('Your session has expired. Please log in again.');
}

// Network/Firestore errors
final class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection. Operating in offline mode.'])
      : super(message);
}

final class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

// Business logic errors
final class OrderNotFoundException extends AppException {
  const OrderNotFoundException(String orderId)
      : super('Order $orderId not found.');
}

final class DuplicateOrderException extends AppException {
  const DuplicateOrderException(String orderNumber)
      : super('Order $orderNumber already exists in this shift.');
}

final class PaymentFailedException extends AppException {
  const PaymentFailedException(super.message);
}

final class InsufficientStockException extends AppException {
  const InsufficientStockException(String ingredientName)
      : super('Insufficient stock for: $ingredientName');
}

final class ShiftNotOpenException extends AppException {
  const ShiftNotOpenException()
      : super('No active shift. Please open a shift before creating orders.');
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'You do not have permission to perform this action.'])
      : super(message);
}
