import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/screens/auth_screen.dart';
import '../../data/models/shift_model.dart';
import '../../data/repositories/shift_repository.dart';

part 'shift_provider.g.dart';

@riverpod
Stream<ShiftModel?> activeShift(ActiveShiftRef ref) {
  // Use demoUserNotifier to get the logged-in user id.
  // In a real app, this would use authStateChangesProvider.
  final demoUser = demoUserNotifier.value;
  if (demoUser == null) return Stream.value(null);

  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchActiveShift(demoUser.id);
}

@riverpod
Stream<List<ShiftModel>> allActiveShifts(AllActiveShiftsRef ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchAllActiveShifts();
}

@riverpod
Stream<List<ShiftModel>> shiftsByDate(ShiftsByDateRef ref, DateTime date) {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchShiftsByDate(date);
}

@riverpod
class ShiftNotifier extends _$ShiftNotifier {
  @override
  void build() {}

  Future<void> openShift(double openingCash) async {
    final demoUser = demoUserNotifier.value;
    if (demoUser == null) throw Exception('No user logged in');

    final result = await ref.read(shiftRepositoryProvider).openShift(
      cashierId: demoUser.id,
      cashierName: demoUser.name,
      openingCash: openingCash,
    );

    if (result.isLeft()) {
      throw Exception(result.fold((l) => l.message, (r) => ''));
    }
  }

  Future<void> closeShift(String shiftId, double closingCash, double expectedCash) async {
    final result = await ref.read(shiftRepositoryProvider).closeShift(
      shiftId: shiftId,
      closingCash: closingCash,
      expectedCash: expectedCash,
    );

    if (result.isLeft()) {
      throw Exception(result.fold((l) => l.message, (r) => ''));
    }
  }

  Future<void> addPettyCash(String shiftId, double amount, CashTransactionType type, String reason) async {
    final demoUser = demoUserNotifier.value;
    if (demoUser == null) throw Exception('No user logged in');

    final result = await ref.read(shiftRepositoryProvider).addCashTransaction(
      shiftId: shiftId,
      amount: amount,
      type: type,
      reason: reason,
      recordedBy: demoUser.name,
    );

    if (result.isLeft()) {
      throw Exception(result.fold((l) => l.message, (r) => ''));
    }
  }
}
