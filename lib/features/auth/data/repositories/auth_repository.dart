import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../data/models/app_user_model.dart';
import '../../domain/repositories/i_auth_repository.dart';

part 'auth_repository.g.dart';

@riverpod
IAuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
}

class AuthRepository implements IAuthRepository {
  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  CollectionReference get _users => firestore.collection(FirestorePaths.users);

  @override
  Future<Either<Failure, AppUserModel>> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _users.doc(uid).get();
      if (!doc.exists) throw const AuthException('User profile not found.');
      final user = AppUserModel.fromFirestore(doc);
      // Update lastLogin
      await _users.doc(uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return Right(user);
    } on AuthException catch (e) {
      return Left(e.toFailure());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Authentication failed.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String userId, String pin) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) throw const AuthException('User not found.');
      final data = doc.data() as Map<String, dynamic>;
      final storedPin = data['pin'] as String?;
      // TODO: Replace with bcrypt comparison in production
      return Right(storedPin == pin);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUserModel>> switchEmployee(
      String employeeId, String pin) async {
    final pinResult = await verifyPin(employeeId, pin);
    return pinResult.fold(
      Left.new,
      (valid) async {
        if (!valid) return const Left(AuthFailure('Incorrect PIN.'));
        return getUserById(employeeId);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Stream<AppUserModel?> watchCurrentUser() {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _users.doc(user.uid).get();
      if (!doc.exists) return null;
      return AppUserModel.fromFirestore(doc);
    });
  }

  @override
  Future<Either<Failure, AppUserModel>> getUserById(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return const Left(NotFoundFailure('User not found.'));
      return Right(AppUserModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppUserModel>>> getEmployees() async {
    try {
      final snap = await _users
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      return Right(snap.docs.map(AppUserModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
