import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/shift_model.dart';
import '../../data/repositories/shift_repository.dart';

part 'shift_provider.g.dart';

/// Active shift stream — drives shift status throughout the app
@riverpod
Stream<ShiftModel?> activeShift(ActiveShiftRef ref) {
  return ref.watch(shiftRepositoryProvider).watchActiveShift();
}

/// Cash transactions for the current active shift
@riverpod
Stream<List<CashTransactionModel>> shiftCashTransactions(
    ShiftCashTransactionsRef ref) {
  final shift = ref.watch(activeShiftProvider).valueOrNull;
  if (shift == null) return const Stream.empty();
  return ref.watch(shiftRepositoryProvider).watchCashTransactions(shift.id);
}

/// Shift actions notifier
@riverpod
class ShiftNotifier extends _$ShiftNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> openShift({
    required String cashierId,
    required String cashierName,
    required String shiftName,
    required double openingCash,
    required String notes,
  }) async {
    state = const AsyncLoading();
    final shift = ShiftModel(
      id:           '',  // Firestore will assign
      name:         shiftName,
      cashierId:    cashierId,
      cashierName:  cashierName,
      openingCash:  openingCash,
      status:       ShiftStatus.open,
      openedAt:     DateTime.now(),
      openingNotes: notes,
    );
    final result = await ref.read(shiftRepositoryProvider).openShift(shift);
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
    required String notes,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(shiftRepositoryProvider).closeShift(
      shiftId:      shiftId,
      closingCash:  closingCash,
      expectedCash: expectedCash,
      notes:        notes,
    );
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> recordCashAction({
    required String shiftId,
    required CashTransactionType type,
    required double amount,
    required String reason,
    required String notes,
    required String recordedBy,
  }) async {
    final tx = CashTransactionModel(
      id:         '',
      type:       type,
      amount:     amount,
      reason:     reason,
      notes:      notes,
      recordedBy: recordedBy,
      createdAt:  DateTime.now(),
    );
    await ref.read(shiftRepositoryProvider).recordCashTransaction(
      shiftId: shiftId,
      transaction: tx,
    );
  }
}
