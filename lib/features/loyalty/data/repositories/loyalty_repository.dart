import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';

part 'loyalty_repository.g.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class LoyaltyAccountModel extends Equatable {
  const LoyaltyAccountModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.points = 0,
    this.tier = 'Bronze',
    this.totalSpend = 0,
    this.visitCount = 0,
    this.activeVouchers = const [],
    this.joinedAt,
    this.lastVisitAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final int points;
  final String tier;      // "Bronze" | "Silver" | "Gold" | "Platinum"
  final double totalSpend;
  final int visitCount;
  final List<String> activeVouchers;
  final DateTime? joinedAt;
  final DateTime? lastVisitAt;

  factory LoyaltyAccountModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LoyaltyAccountModel(
      id:             doc.id,
      name:           d['name']            as String? ?? '',
      phone:          d['phone']           as String? ?? '',
      email:          d['email']           as String?,
      points:         d['points']          as int? ?? 0,
      tier:           d['tier']            as String? ?? 'Bronze',
      totalSpend:     (d['totalSpend']     as num?)?.toDouble() ?? 0,
      visitCount:     d['visitCount']      as int? ?? 0,
      activeVouchers: List<String>.from(d['activeVouchers'] as List? ?? []),
      joinedAt:       (d['joinedAt']       as Timestamp?)?.toDate(),
      lastVisitAt:    (d['lastVisitAt']    as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':           name,
    'phone':          phone,
    'email':          email,
    'points':         points,
    'tier':           tier,
    'totalSpend':     totalSpend,
    'visitCount':     visitCount,
    'activeVouchers': activeVouchers,
    'joinedAt':       joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    'lastVisitAt':    FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, phone, points, tier];
}

// ─── Repository ───────────────────────────────────────────────────────────────
@riverpod
LoyaltyRepository loyaltyRepository(LoyaltyRepositoryRef ref) {
  return LoyaltyRepository(firestore: FirebaseFirestore.instance);
}

class LoyaltyRepository {
  LoyaltyRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _accounts =>
      firestore.collection(FirestorePaths.loyaltyAccounts);

  Future<Either<Failure, LoyaltyAccountModel?>> findByPhone(String phone) async {
    try {
      final snap = await _accounts.where('phone', isEqualTo: phone).limit(1).get();
      if (snap.docs.isEmpty) return const Right(null);
      return Right(LoyaltyAccountModel.fromFirestore(snap.docs.first));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> createAccount(LoyaltyAccountModel account) async {
    try {
      final doc = await _accounts.add(account.toFirestore());
      return Right(doc.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> addPoints(
      String accountId, int points, double spend) async {
    try {
      await _accounts.doc(accountId).update({
        'points':      FieldValue.increment(points),
        'totalSpend':  FieldValue.increment(spend),
        'visitCount':  FieldValue.increment(1),
        'lastVisitAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> redeemPoints(
      String accountId, int points) async {
    try {
      await _accounts.doc(accountId).update({
        'points': FieldValue.increment(-points),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
@riverpod
Future<LoyaltyAccountModel?> loyaltyByPhone(
    LoyaltyByPhoneRef ref, String phone) async {
  final result =
      await ref.watch(loyaltyRepositoryProvider).findByPhone(phone);
  return result.fold((_) => null, (a) => a);
}
