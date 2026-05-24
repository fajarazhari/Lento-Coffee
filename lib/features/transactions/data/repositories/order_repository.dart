import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/id_generator.dart';
import '../../data/models/order_model.dart';

part 'order_repository.g.dart';

@riverpod
OrderRepository orderRepository(OrderRepositoryRef ref) {
  return OrderRepository(firestore: FirebaseFirestore.instance);
}

class OrderRepository {
  OrderRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _orders => firestore.collection(FirestorePaths.orders);

  // ── Create draft order ─────────────────────────────────────────────────────
  Future<Either<Failure, String>> createDraftOrder(OrderModel order) async {
    try {
      final docRef = _orders.doc();
      final withId = order.copyWith();
      await docRef.set(withId.toFirestore());

      // Write items subcollection
      final batch = firestore.batch();
      for (final item in order.items) {
        final itemRef = firestore
            .collection(FirestorePaths.orderItems(docRef.id))
            .doc();
        batch.set(itemRef, item.toFirestore());
      }
      await batch.commit();

      return Right(docRef.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Process payment: Draft → Paid ──────────────────────────────────────────
  Future<Either<Failure, Unit>> processPayment({
    required String orderId,
    required PaymentMethod method,
    required double paidAmount,
    required double total,
  }) async {
    try {
      final changeDue = paidAmount - total;
      await _orders.doc(orderId).update({
        'status':        OrderStatus.paid.label,
        'kdsStatus':     KdsStatus.newOrder.label,
        'paymentMethod': method.label,
        'paidAmount':    paidAmount,
        'changeDue':     changeDue,
        'updatedAt':     FieldValue.serverTimestamp(),
      });

      // Write payment document
      await firestore.collection(FirestorePaths.payments).add({
        'orderId':     orderId,
        'method':      method.label,
        'amount':      total,
        'paidAmount':  paidAmount,
        'change':      changeDue,
        'status':      'Success',
        'createdAt':   FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Advance KDS status ─────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> advanceKdsStatus(
      String orderId, KdsStatus next) async {
    try {
      final Map<String, dynamic> updates = {
        'kdsStatus': next.label,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (next == KdsStatus.brewing) {
        updates['brewStartedAt'] = FieldValue.serverTimestamp();
      } else if (next == KdsStatus.ready) {
        updates['readyAt'] = FieldValue.serverTimestamp();
      } else if (next == KdsStatus.done) {
        updates['completedAt'] = FieldValue.serverTimestamp();
        updates['status'] = OrderStatus.completed.label;
      }
      await _orders.doc(orderId).update(updates);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Cancel / Refund ────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> cancelOrder(
      String orderId, String reason) async {
    try {
      await _orders.doc(orderId).update({
        'status':    OrderStatus.cancelled.label,
        'notes':     reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Live KDS feed (new + brewing + ready orders) ─────────────────────────
  Stream<List<OrderModel>> watchActiveOrders() {
    return _orders
        .where('kdsStatus', whereIn: [
          KdsStatus.newOrder.label,
          KdsStatus.brewing.label,
          KdsStatus.ready.label,
        ])
        .orderBy('isPriority', descending: true)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Full KDS feed: includes DONE column ──────────────────────────────────
  Stream<List<OrderModel>> watchKdsOrders() {
    return _orders
        .where('kdsStatus', whereIn: [
          KdsStatus.newOrder.label,
          KdsStatus.brewing.label,
          KdsStatus.ready.label,
          KdsStatus.done.label,
        ])
        .orderBy('isPriority', descending: true)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── All orders (for Transactions + Reports) ───────────────────────────────
  Stream<List<OrderModel>> watchAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  // ── Paginated transaction history ──────────────────────────────────────────
  Future<Either<Failure, List<OrderModel>>> getOrders({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _orders.orderBy('createdAt', descending: true);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (status != null && status != 'All') {
        query = query.where('status', isEqualTo: status);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.limit(AppConstants.defaultPageSize).get();
      return Right(snap.docs.map(OrderModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Toggle priority ────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> setPriority(
      String orderId, bool isPriority) async {
    try {
      await _orders.doc(orderId).update({
        'isPriority': isPriority,
        'updatedAt':  FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
