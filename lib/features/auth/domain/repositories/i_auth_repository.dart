import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/app_user_model.dart';

abstract class IAuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, AppUserModel>> signIn(String email, String password);

  /// Verify a 4-digit PIN against the stored (hashed) PIN
  Future<Either<Failure, bool>> verifyPin(String userId, String pin);

  /// Switch active terminal employee without full re-auth
  Future<Either<Failure, AppUserModel>> switchEmployee(String employeeId, String pin);

  /// Sign out the current Firebase user
  Future<Either<Failure, Unit>> signOut();

  /// Stream of the currently authenticated user profile
  Stream<AppUserModel?> watchCurrentUser();

  /// Get a user profile by ID (for employee list)
  Future<Either<Failure, AppUserModel>> getUserById(String userId);

  /// List all active employees
  Future<Either<Failure, List<AppUserModel>>> getEmployees();
}
