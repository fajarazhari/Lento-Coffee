import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ShiftStatus { open, closed }
enum CashTransactionType { cashIn, cashOut, adjustment }

extension CashTransactionTypeX on CashTransactionType {
  String get label => switch (this) {
    CashTransactionType.cashIn     => 'Cash In',
    CashTransactionType.cashOut    => 'Cash Out',
    CashTransactionType.adjustment => 'Adjustment',
  };
  static CashTransactionType fromString(String s) => CashTransactionType.values.firstWhere(
    (e) => e.label.toLowerCase() == s.toLowerCase(), orElse: () => CashTransactionType.cashIn);
}

class ShiftModel extends Equatable {
  const ShiftModel({
    required this.id,
    required this.name,
    required this.cashierId,
    required this.cashierName,
    required this.openingCash,
    required this.status,
    required this.openedAt,
    this.closingCash,
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.totalRefunds = 0,
    this.cashIn = 0,
    this.cashOut = 0,
    this.difference,
    this.openingNotes = '',
    this.closingNotes,
    this.closedAt,
  });

  final String id;
  final String name;
  final String cashierId;
  final String cashierName;
  final double openingCash;
  final double? closingCash;
  final double totalRevenue;
  final int totalOrders;
  final double totalRefunds;
  final double cashIn;
  final double cashOut;
  final double? difference;
  final ShiftStatus status;
  final String openingNotes;
  final String? closingNotes;
  final DateTime openedAt;
  final DateTime? closedAt;

  double get expectedCash =>
      openingCash + cashIn - cashOut + totalRevenue;

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftModel(
      id:           doc.id,
      name:         data['name']          as String? ?? '',
      cashierId:    data['cashierId']     as String? ?? '',
      cashierName:  data['cashierName']   as String? ?? '',
      openingCash:  (data['openingCash']  as num?)?.toDouble() ?? 0,
      closingCash:  (data['closingCash']  as num?)?.toDouble(),
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalOrders:  data['totalOrders']   as int? ?? 0,
      totalRefunds: (data['totalRefunds'] as num?)?.toDouble() ?? 0,
      cashIn:       (data['cashIn']       as num?)?.toDouble() ?? 0,
      cashOut:      (data['cashOut']      as num?)?.toDouble() ?? 0,
      difference:   (data['difference']   as num?)?.toDouble(),
      status:       ShiftStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'open').toLowerCase(),
        orElse: () => ShiftStatus.open,
      ),
      openingNotes: data['openingNotes']  as String? ?? '',
      closingNotes: data['closingNotes']  as String?,
      openedAt:     (data['openedAt']     as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt:     (data['closedAt']     as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':         name,
    'cashierId':    cashierId,
    'cashierName':  cashierName,
    'openingCash':  openingCash,
    'closingCash':  closingCash,
    'totalRevenue': totalRevenue,
    'totalOrders':  totalOrders,
    'totalRefunds': totalRefunds,
    'cashIn':       cashIn,
    'cashOut':      cashOut,
    'difference':   difference,
    'status':       status.name,
    'openingNotes': openingNotes,
    'closingNotes': closingNotes,
    'openedAt':     FieldValue.serverTimestamp(),
    'closedAt':     closedAt != null ? Timestamp.fromDate(closedAt!) : null,
  };

  @override
  List<Object?> get props => [id, cashierId, status, totalRevenue];
}

class CashTransactionModel extends Equatable {
  const CashTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.notes = '',
    this.recordedBy,
  });

  final String id;
  final CashTransactionType type;
  final double amount;
  final String reason;
  final String notes;
  final String? recordedBy;
  final DateTime createdAt;

  factory CashTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CashTransactionModel(
      id:         doc.id,
      type:       CashTransactionTypeX.fromString(data['type'] as String? ?? 'Cash In'),
      amount:     (data['amount']     as num?)?.toDouble() ?? 0,
      reason:     data['reason']      as String? ?? '',
      notes:      data['notes']       as String? ?? '',
      recordedBy: data['recordedBy']  as String?,
      createdAt:  (data['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type':       type.label,
    'amount':     amount,
    'reason':     reason,
    'notes':      notes,
    'recordedBy': recordedBy,
    'createdAt':  FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, type, amount, reason];
}
