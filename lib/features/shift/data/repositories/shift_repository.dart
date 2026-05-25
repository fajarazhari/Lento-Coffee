import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../models/shift_model.dart';

part 'shift_repository.g.dart';

@riverpod
ShiftRepository shiftRepository(ShiftRepositoryRef ref) {
  return ShiftRepository(firestore: FirebaseFirestore.instance);
}

class ShiftRepository {
  const ShiftRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _shifts => firestore.collection(FirestorePaths.shifts);

  Future<Either<Failure, ShiftModel?>> getActiveShift(String cashierId) async {
    try {
      final snap = await _shifts
          .where('cashierId', isEqualTo: cashierId)
          .where('status', isEqualTo: ShiftStatus.open.name)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return const Right(null);
      return Right(ShiftModel.fromFirestore(snap.docs.first));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Stream<ShiftModel?> watchActiveShift(String cashierId) {
    return _shifts
        .where('cashierId', isEqualTo: cashierId)
        .where('status', isEqualTo: ShiftStatus.open.name)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ShiftModel.fromFirestore(snap.docs.first);
    });
  }

  Stream<List<ShiftModel>> watchAllActiveShifts() {
    return _shifts
        .where('status', isEqualTo: ShiftStatus.open.name)
        .orderBy('openedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ShiftModel.fromFirestore).toList());
  }

  Stream<List<ShiftModel>> watchShiftsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _shifts
        .where('openedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('openedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('openedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ShiftModel.fromFirestore).toList());
  }

  Future<Either<Failure, ShiftModel>> openShift({
    required String cashierId,
    required String cashierName,
    required double openingCash,
  }) async {
    try {
      final active = await getActiveShift(cashierId);
      if (active.isRight() && active.getOrElse(() => null) != null) {
        return Left(ServerFailure('Kasir ini masih memiliki shift yang belum ditutup.'));
      }

      final ref = _shifts.doc();
      final now = DateTime.now();
      
      final shift = ShiftModel(
        id: ref.id,
        name: 'Shift ${now.day}/${now.month}/${now.year}', // Can be customized
        cashierId: cashierId,
        cashierName: cashierName,
        openingCash: openingCash,
        status: ShiftStatus.open,
        openedAt: now,
      );

      await ref.set(shift.toFirestore());
      return Right(shift);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> closeShift({
    required String shiftId,
    required double closingCash, // Uang fisik aktual
    required double expectedCash, // Uang sistem
  }) async {
    try {
      final diff = closingCash - expectedCash;
      
      await _shifts.doc(shiftId).update({
        'status': ShiftStatus.closed.name,
        'closedAt': FieldValue.serverTimestamp(),
        'closingCash': closingCash,
        'difference': diff,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> addCashTransaction({
    required String shiftId,
    required double amount,
    required CashTransactionType type,
    required String reason,
    required String recordedBy,
  }) async {
    try {
      final txRef = _shifts.doc(shiftId).collection('cash_transactions').doc();
      final tx = CashTransactionModel(
        id: txRef.id,
        type: type,
        amount: amount,
        reason: reason,
        recordedBy: recordedBy,
        createdAt: DateTime.now(),
      );

      // Run in a batch to update shift totals too
      final batch = firestore.batch();
      batch.set(txRef, tx.toFirestore());
      
      final updateData = <String, dynamic>{};
      if (type == CashTransactionType.cashIn) {
        updateData['cashIn'] = FieldValue.increment(amount);
      } else if (type == CashTransactionType.cashOut) {
        updateData['cashOut'] = FieldValue.increment(amount);
      }
      
      if (updateData.isNotEmpty) {
        batch.update(_shifts.doc(shiftId), updateData);
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
