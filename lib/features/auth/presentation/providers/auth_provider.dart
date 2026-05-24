import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/app_user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Firebase auth state stream ────────────────────────────────────────────────
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// ── Current user profile (from Firestore) ────────────────────────────────────
@riverpod
Stream<AppUserModel?> currentUser(CurrentUserRef ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
}

// ── Auth actions notifier ─────────────────────────────────────────────────────
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<AppUserModel?> build() => const AsyncData(null);

  Future<Either<Failure, AppUserModel>> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signIn(email, password);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (user) => state = AsyncData(user),
    );
    return result;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<Either<Failure, AppUserModel>> switchEmployee(
      String employeeId, String pin) async {
    return ref.read(authRepositoryProvider).switchEmployee(employeeId, pin);
  }

  Future<Either<Failure, bool>> verifyPin(String userId, String pin) async {
    return ref.read(authRepositoryProvider).verifyPin(userId, pin);
  }
}

// ── Employee list ─────────────────────────────────────────────────────────────
@riverpod
Future<List<AppUserModel>> employees(EmployeesRef ref) async {
  final result = await ref.watch(authRepositoryProvider).getEmployees();
  return result.fold((_) => [], (list) => list);
}
