import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';

part 'settings_repository.g.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class AppSettingsModel extends Equatable {
  const AppSettingsModel({
    this.storeName = 'Lento Coffee',
    this.storeAddress = '',
    this.storePhone = '',
    this.currency = 'IDR',
    this.taxRate = 0.10,
    this.taxLabel = 'PPN 10%',
    this.receiptFooter = 'Thank you for visiting Lento Coffee!',
    this.loyaltyPointsPerRupiah = 1,
    this.autoLockMinutes = 5,
    this.kdsSlaNormalMinutes = 3,
    this.kdsSlaDangerMinutes = 6,
    this.updatedAt,
  });

  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String currency;
  final double taxRate;
  final String taxLabel;
  final String receiptFooter;
  final int loyaltyPointsPerRupiah;
  final int autoLockMinutes;
  final int kdsSlaNormalMinutes;
  final int kdsSlaDangerMinutes;
  final DateTime? updatedAt;

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AppSettingsModel(
      storeName:              d['storeName']              as String? ?? 'Lento Coffee',
      storeAddress:           d['storeAddress']           as String? ?? '',
      storePhone:             d['storePhone']             as String? ?? '',
      currency:               d['currency']               as String? ?? 'IDR',
      taxRate:                (d['taxRate']               as num?)?.toDouble() ?? 0.1,
      taxLabel:               d['taxLabel']               as String? ?? 'PPN 10%',
      receiptFooter:          d['receiptFooter']          as String? ?? '',
      loyaltyPointsPerRupiah: d['loyaltyPointsPerRupiah'] as int? ?? 1,
      autoLockMinutes:        d['autoLockMinutes']        as int? ?? 5,
      kdsSlaNormalMinutes:    d['kdsSlaNormalMinutes']    as int? ?? 3,
      kdsSlaDangerMinutes:    d['kdsSlaDangerMinutes']    as int? ?? 6,
      updatedAt:              (d['updatedAt']             as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'storeName':              storeName,
    'storeAddress':           storeAddress,
    'storePhone':             storePhone,
    'currency':               currency,
    'taxRate':                taxRate,
    'taxLabel':               taxLabel,
    'receiptFooter':          receiptFooter,
    'loyaltyPointsPerRupiah': loyaltyPointsPerRupiah,
    'autoLockMinutes':        autoLockMinutes,
    'kdsSlaNormalMinutes':    kdsSlaNormalMinutes,
    'kdsSlaDangerMinutes':    kdsSlaDangerMinutes,
    'updatedAt':              FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [storeName, taxRate, kdsSlaNormalMinutes];
}

// ─── Repository ───────────────────────────────────────────────────────────────
@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository(firestore: FirebaseFirestore.instance);
}

class SettingsRepository {
  SettingsRepository({required this.firestore});
  final FirebaseFirestore firestore;

  DocumentReference get _doc => firestore
      .collection(FirestorePaths.settings)
      .doc(FirestorePaths.globalSettingsDoc);

  Stream<AppSettingsModel> watchSettings() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return const AppSettingsModel();
      return AppSettingsModel.fromFirestore(snap);
    });
  }

  Future<Either<Failure, Unit>> updateSettings(AppSettingsModel settings) async {
    try {
      await _doc.set(settings.toFirestore(), SetOptions(merge: true));
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
@riverpod
Stream<AppSettingsModel> appSettings(AppSettingsRef ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
}
