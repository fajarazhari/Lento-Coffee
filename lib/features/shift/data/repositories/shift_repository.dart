import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../data/models/shift_model.dart';

part 'shift_repository.g.dart';

@riverpod
ShiftRepository shiftRepository(ShiftRepositoryRef ref) {
  return ShiftRepository(firestore: FirebaseFirestore.instance);
}

class ShiftRepository {
  ShiftRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _shifts => firestore.collection(FirestorePaths.shifts);

  // ── Watch active shift ─────────────────────────────────────────────────────
  Stream<ShiftModel?> watchActiveShift() {
    return _shifts
        .where('status', isEqualTo: ShiftStatus.open.name)
        .orderBy('openedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : ShiftModel.fromFirestore(snap.docs.first));
  }

  // ── Open shift ─────────────────────────────────────────────────────────────
  Future<Either<Failure, String>> openShift(ShiftModel shift) async {
    try {
      final doc = await _shifts.add(shift.toFirestore());
      return Right(doc.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Close shift ────────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
    required String notes,
  }) async {
    try {
      await _shifts.doc(shiftId).update({
        'status':       ShiftStatus.closed.name,
        'closingCash':  closingCash,
        'difference':   closingCash - expectedCash,
        'closingNotes': notes,
        'closedAt':     FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Record cash transaction ────────────────────────────────────────────────
  Future<Either<Failure, Unit>> recordCashTransaction({
    required String shiftId,
    required CashTransactionModel transaction,
  }) async {
    try {
      final batch = firestore.batch();

      // Add cash transaction sub-document
      final txRef = firestore
          .collection(FirestorePaths.cashTransactions(shiftId))
          .doc();
      batch.set(txRef, transaction.toFirestore());

      // Update shift running totals
      final Map<String, dynamic> shiftUpdate = {'updatedAt': FieldValue.serverTimestamp()};
      switch (transaction.type) {
        case CashTransactionType.cashIn:
          shiftUpdate['cashIn'] = FieldValue.increment(transaction.amount);
        case CashTransactionType.cashOut:
          shiftUpdate['cashOut'] = FieldValue.increment(transaction.amount);
        case CashTransactionType.adjustment:
          break; // Adjustment doesn't change totals, just recorded for audit
      }
      batch.update(_shifts.doc(shiftId), shiftUpdate);

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Get cash transactions for a shift ─────────────────────────────────────
  Stream<List<CashTransactionModel>> watchCashTransactions(String shiftId) {
    return firestore
        .collection(FirestorePaths.cashTransactions(shiftId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CashTransactionModel.fromFirestore).toList());
  }

  // ── Get past shifts ────────────────────────────────────────────────────────
  Future<Either<Failure, List<ShiftModel>>> getShiftHistory({int limit = 30}) async {
    try {
      final snap = await _shifts
          .orderBy('openedAt', descending: true)
          .limit(limit)
          .get();
      return Right(snap.docs.map(ShiftModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
