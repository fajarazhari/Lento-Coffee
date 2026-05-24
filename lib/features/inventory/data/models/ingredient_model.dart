import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum InventoryAction { deduction, restock, adjustment, waste }

class IngredientModel extends Equatable {
  const IngredientModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    this.emoji = '📦',
    this.costPerUnit = 0,
    this.supplier,
    this.lastRestockedAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String unit;      // "g" | "ml" | "unit" | "serving"
  final double currentStock;
  final double minimumStock;
  final String emoji;
  final double costPerUnit;
  final String? supplier;
  final DateTime? lastRestockedAt;
  final DateTime? updatedAt;

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;

  factory IngredientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IngredientModel(
      id:              doc.id,
      name:            data['name']            as String? ?? '',
      category:        data['category']        as String? ?? '',
      unit:            data['unit']            as String? ?? 'g',
      currentStock:    (data['currentStock']   as num?)?.toDouble() ?? 0,
      minimumStock:    (data['minimumStock']   as num?)?.toDouble() ?? 0,
      emoji:           data['emoji']           as String? ?? '📦',
      costPerUnit:     (data['costPerUnit']    as num?)?.toDouble() ?? 0,
      supplier:        data['supplier']        as String?,
      lastRestockedAt: (data['lastRestockedAt'] as Timestamp?)?.toDate(),
      updatedAt:       (data['updatedAt']       as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':            name,
    'category':        category,
    'unit':            unit,
    'currentStock':    currentStock,
    'minimumStock':    minimumStock,
    'emoji':           emoji,
    'costPerUnit':     costPerUnit,
    'supplier':        supplier,
    'lastRestockedAt': lastRestockedAt != null ? Timestamp.fromDate(lastRestockedAt!) : null,
    'updatedAt':       FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, name, currentStock, minimumStock, emoji];
}

class InventoryLogModel extends Equatable {
  const InventoryLogModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.action,
    required this.quantity,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reason,
    required this.createdAt,
    this.orderId,
    this.recordedBy = 'system',
  });

  final String id;
  final String ingredientId;
  final String ingredientName;
  final InventoryAction action;
  final double quantity;          // Negative = deduction
  final double balanceBefore;
  final double balanceAfter;
  final String reason;
  final String? orderId;
  final String recordedBy;
  final DateTime createdAt;

  factory InventoryLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryLogModel(
      id:              doc.id,
      ingredientId:    data['ingredientId']    as String? ?? '',
      ingredientName:  data['ingredientName']  as String? ?? '',
      action:          InventoryAction.values.firstWhere(
        (a) => a.name == (data['action'] as String? ?? 'deduction').toLowerCase(),
        orElse: () => InventoryAction.deduction,
      ),
      quantity:        (data['quantity']       as num?)?.toDouble() ?? 0,
      balanceBefore:   (data['balanceBefore']  as num?)?.toDouble() ?? 0,
      balanceAfter:    (data['balanceAfter']   as num?)?.toDouble() ?? 0,
      reason:          data['reason']          as String? ?? '',
      orderId:         data['orderId']         as String?,
      recordedBy:      data['recordedBy']      as String? ?? 'system',
      createdAt:       (data['createdAt']       as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ingredientId':   ingredientId,
    'ingredientName': ingredientName,
    'action':         action.name,
    'quantity':       quantity,
    'balanceBefore':  balanceBefore,
    'balanceAfter':   balanceAfter,
    'reason':         reason,
    'orderId':        orderId,
    'recordedBy':     recordedBy,
    'createdAt':      FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, ingredientId, action, quantity, createdAt];
}
