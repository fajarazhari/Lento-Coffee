import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/id_generator.dart';

enum OrderStatus  { draft, paid, brewing, ready, completed, cancelled }
enum KdsStatus    { newOrder, brewing, ready, done }
enum PaymentMethod { cash, qris, debitCard, transfer }
enum OrderType    { dineIn, takeAway }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.draft     => 'Draft',
    OrderStatus.paid      => 'Paid',
    OrderStatus.brewing   => 'Brewing',
    OrderStatus.ready     => 'Ready',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
  };
  static OrderStatus fromString(String s) => OrderStatus.values.firstWhere(
    (e) => e.label.toLowerCase() == s.toLowerCase(), orElse: () => OrderStatus.draft);
}

extension KdsStatusX on KdsStatus {
  String get label => switch (this) {
    KdsStatus.newOrder => 'NEW',
    KdsStatus.brewing  => 'BREWING',
    KdsStatus.ready    => 'READY',
    KdsStatus.done     => 'DONE',
  };
  static KdsStatus fromString(String s) => KdsStatus.values.firstWhere(
    (e) => e.label == s.toUpperCase(), orElse: () => KdsStatus.newOrder);
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash      => 'Cash',
    PaymentMethod.qris      => 'QRIS',
    PaymentMethod.debitCard => 'Debit Card',
    PaymentMethod.transfer  => 'Transfer',
  };
  static PaymentMethod fromString(String s) => PaymentMethod.values.firstWhere(
    (e) => e.label.toLowerCase() == s.toLowerCase(), orElse: () => PaymentMethod.cash);
}

// ─── Order Item ────────────────────────────────────────────────────────────────
class OrderItemModel extends Equatable {
  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.size = 'Medium',
    this.temperature = 'Hot',
    this.sugarLevel = 'Normal',
    this.iceLevel = 'Normal Ice',
    this.variant = 'Regular',
    this.addons = const [],
    this.notes = '',
  });

  final String id;
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String size;
  final String temperature;
  final String sugarLevel;
  final String iceLevel;
  final String variant;
  final List<String> addons;
  final String notes;

  factory OrderItemModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return OrderItemModel(
      id:          id ?? data['id'] as String? ?? IdGenerator.offlineId('item'),
      productId:   data['productId']   as String? ?? '',
      productName: data['productName'] as String? ?? '',
      category:    data['category']    as String? ?? '',
      quantity:    data['quantity']    as int? ?? 1,
      unitPrice:   (data['unitPrice']  as num?)?.toDouble() ?? 0,
      totalPrice:  (data['totalPrice'] as num?)?.toDouble() ?? 0,
      size:        data['size']        as String? ?? 'Medium',
      temperature: data['temperature'] as String? ?? 'Hot',
      sugarLevel:  data['sugarLevel']  as String? ?? 'Normal',
      iceLevel:    data['iceLevel']    as String? ?? 'Normal Ice',
      variant:     data['variant']     as String? ?? 'Regular',
      addons:      List<String>.from(data['addons'] as List? ?? []),
      notes:       data['notes']       as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'productId':   productId,
    'productName': productName,
    'category':    category,
    'quantity':    quantity,
    'unitPrice':   unitPrice,
    'totalPrice':  totalPrice,
    'size':        size,
    'temperature': temperature,
    'sugarLevel':  sugarLevel,
    'iceLevel':    iceLevel,
    'variant':     variant,
    'addons':      addons,
    'notes':       notes,
  };

  @override
  List<Object?> get props => [id, productId, quantity, unitPrice];
}

// ─── Order ─────────────────────────────────────────────────────────────────────
class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.cashierId,
    required this.cashierName,
    required this.customerName,
    required this.tableNumber,
    required this.orderType,
    required this.status,
    required this.kdsStatus,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.customerId,
    this.discountType = 'none',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.paidAmount = 0,
    this.changeDue = 0,
    this.shiftId,
    this.notes = '',
    this.isPriority = false,
    this.brewStartedAt,
    this.readyAt,
    this.completedAt,
    this.updatedAt,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String cashierId;
  final String cashierName;
  final String? customerId;
  final String customerName;
  final String tableNumber;
  final OrderType orderType;
  final OrderStatus status;
  final KdsStatus kdsStatus;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double total;
  final PaymentMethod paymentMethod;
  final double paidAmount;
  final double changeDue;
  final String? shiftId;
  final String notes;
  final bool isPriority;
  final DateTime? brewStartedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> items;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id:             doc.id,
      orderNumber:    data['orderNumber']   as String? ?? '',
      cashierId:      data['cashierId']     as String? ?? '',
      cashierName:    data['cashierName']   as String? ?? '',
      customerId:     data['customerId']    as String?,
      customerName:   data['customerName']  as String? ?? '',
      tableNumber:    data['tableNumber']   as String? ?? '',
      orderType:      (data['orderType'] as String? ?? 'Dine In').contains('Dine')
          ? OrderType.dineIn : OrderType.takeAway,
      status:         OrderStatusX.fromString(data['status'] as String? ?? 'draft'),
      kdsStatus:      KdsStatusX.fromString(data['kdsStatus'] as String? ?? 'NEW'),
      subtotal:       (data['subtotal']     as num?)?.toDouble() ?? 0,
      taxRate:        (data['taxRate']      as num?)?.toDouble() ?? 0.1,
      taxAmount:      (data['taxAmount']    as num?)?.toDouble() ?? 0,
      discountType:   data['discountType']  as String? ?? 'none',
      discountValue:  (data['discountValue'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      total:          (data['total']        as num?)?.toDouble() ?? 0,
      paymentMethod:  PaymentMethodX.fromString(data['paymentMethod'] as String? ?? 'Cash'),
      paidAmount:     (data['paidAmount']   as num?)?.toDouble() ?? 0,
      changeDue:      (data['changeDue']    as num?)?.toDouble() ?? 0,
      shiftId:        data['shiftId']       as String?,
      notes:          data['notes']         as String? ?? '',
      isPriority:     data['isPriority']    as bool? ?? false,
      brewStartedAt:  (data['brewStartedAt'] as Timestamp?)?.toDate(),
      readyAt:        (data['readyAt']       as Timestamp?)?.toDate(),
      completedAt:    (data['completedAt']   as Timestamp?)?.toDate(),
      createdAt:      (data['createdAt']     as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:      (data['updatedAt']     as Timestamp?)?.toDate(),
      items:          (data['items'] as List? ?? []).map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'orderNumber':    orderNumber,
    'cashierId':      cashierId,
    'cashierName':    cashierName,
    'customerId':     customerId,
    'customerName':   customerName,
    'tableNumber':    tableNumber,
    'orderType':      orderType == OrderType.dineIn ? 'Dine In' : 'Take Away',
    'status':         status.label,
    'kdsStatus':      kdsStatus.label,
    'subtotal':       subtotal,
    'taxRate':        taxRate,
    'taxAmount':      taxAmount,
    'discountType':   discountType,
    'discountValue':  discountValue,
    'discountAmount': discountAmount,
    'total':          total,
    'paymentMethod':  paymentMethod.label,
    'paidAmount':     paidAmount,
    'changeDue':      changeDue,
    'shiftId':        shiftId,
    'notes':          notes,
    'isPriority':     isPriority,
    'brewStartedAt':  brewStartedAt != null ? Timestamp.fromDate(brewStartedAt!) : null,
    'readyAt':        readyAt       != null ? Timestamp.fromDate(readyAt!)       : null,
    'completedAt':    completedAt   != null ? Timestamp.fromDate(completedAt!)   : null,
    'createdAt':      FieldValue.serverTimestamp(),
    'updatedAt':      FieldValue.serverTimestamp(),
    'items':          items.map((i) => i.toMap()).toList(),
  };

  OrderModel copyWith({
    OrderStatus? status,
    KdsStatus? kdsStatus,
    double? paidAmount,
    double? changeDue,
    PaymentMethod? paymentMethod,
    bool? isPriority,
    DateTime? brewStartedAt,
    DateTime? readyAt,
    DateTime? completedAt,
    List<OrderItemModel>? items,
  }) =>
      OrderModel(
        id:             id,
        orderNumber:    orderNumber,
        cashierId:      cashierId,
        cashierName:    cashierName,
        customerId:     customerId,
        customerName:   customerName,
        tableNumber:    tableNumber,
        orderType:      orderType,
        status:         status         ?? this.status,
        kdsStatus:      kdsStatus      ?? this.kdsStatus,
        subtotal:       subtotal,
        taxRate:        taxRate,
        taxAmount:      taxAmount,
        discountType:   discountType,
        discountValue:  discountValue,
        discountAmount: discountAmount,
        total:          total,
        paymentMethod:  paymentMethod  ?? this.paymentMethod,
        paidAmount:     paidAmount     ?? this.paidAmount,
        changeDue:      changeDue      ?? this.changeDue,
        shiftId:        shiftId,
        notes:          notes,
        isPriority:     isPriority     ?? this.isPriority,
        brewStartedAt:  brewStartedAt  ?? this.brewStartedAt,
        readyAt:        readyAt        ?? this.readyAt,
        completedAt:    completedAt    ?? this.completedAt,
        createdAt:      createdAt,
        updatedAt:      updatedAt,
        items:          items          ?? this.items,
      );

  @override
  List<Object?> get props => [id, orderNumber, status, kdsStatus, total];
}
