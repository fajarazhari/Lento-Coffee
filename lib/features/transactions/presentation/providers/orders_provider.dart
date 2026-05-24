import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/id_generator.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

part 'orders_provider.g.dart';

// ── Live KDS feed ─────────────────────────────────────────────────────────────
@riverpod
Stream<List<OrderModel>> activeOrders(ActiveOrdersRef ref) {
  return ref.watch(orderRepositoryProvider).watchActiveOrders();
}

// ── Full KDS feed including DONE column ────────────────────────────────────────
@riverpod
Stream<List<OrderModel>> kdsOrders(KdsOrdersRef ref) {
  return ref.watch(orderRepositoryProvider).watchKdsOrders();
}

// ── All orders for Transactions + Reports ──────────────────────────────────────
@riverpod
Stream<List<OrderModel>> allOrders(AllOrdersRef ref) {
  return ref.watch(orderRepositoryProvider).watchAllOrders();
}

// ── Derived: preparing orders (for KDS left column) ──────────────────────────
@riverpod
List<OrderModel> preparingOrders(PreparingOrdersRef ref) {
  return ref.watch(activeOrdersProvider).valueOrNull?.where((o) =>
    o.kdsStatus == KdsStatus.newOrder || o.kdsStatus == KdsStatus.brewing
  ).toList() ?? [];
}

// ── Derived: ready orders (for KDS right column + Customer Board) ─────────────
@riverpod
List<OrderModel> readyOrders(ReadyOrdersRef ref) {
  return ref.watch(activeOrdersProvider).valueOrNull?.where((o) =>
    o.kdsStatus == KdsStatus.ready
  ).toList() ?? [];
}

// ── Cart state ────────────────────────────────────────────────────────────────
class CartState {
  const CartState({
    this.items = const [],
    this.orderNumber = '',
    this.customerName = '',
    this.tableNumber = '',
    this.orderType = OrderType.dineIn,
    this.notes = '',
  });

  final List<OrderItemModel> items;
  final String orderNumber;
  final String customerName;
  final String tableNumber;
  final OrderType orderType;
  final String notes;

  double get subtotal => items.fold(0, (s, i) => s + i.totalPrice);
  double get taxAmount => subtotal * 0.1;
  double get total => subtotal + taxAmount;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  CartState copyWith({
    List<OrderItemModel>? items,
    String? orderNumber,
    String? customerName,
    String? tableNumber,
    OrderType? orderType,
    String? notes,
  }) =>
      CartState(
        items:        items        ?? this.items,
        orderNumber:  orderNumber  ?? this.orderNumber,
        customerName: customerName ?? this.customerName,
        tableNumber:  tableNumber  ?? this.tableNumber,
        orderType:    orderType    ?? this.orderType,
        notes:        notes        ?? this.notes,
      );
}

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() => CartState(orderNumber: IdGenerator.orderNumber());

  void addItem(OrderItemModel item) {
    final existing = state.items.indexWhere(
      (i) => i.productId == item.productId && i.size == item.size && i.temperature == item.temperature);
    if (existing != -1) {
      final updated = List<OrderItemModel>.from(state.items);
      final old = updated[existing];
      updated[existing] = OrderItemModel(
        id:          old.id,
        productId:   old.productId,
        productName: old.productName,
        category:    old.category,
        quantity:    old.quantity + item.quantity,
        unitPrice:   old.unitPrice,
        totalPrice:  old.unitPrice * (old.quantity + item.quantity),
        size:        old.size,
        temperature: old.temperature,
        addons:      old.addons,
        notes:       old.notes,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  void updateQuantity(String itemId, int qty) {
    if (qty <= 0) {
      removeItem(itemId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id != itemId) return i;
        return OrderItemModel(
          id: i.id, productId: i.productId, productName: i.productName,
          category: i.category, quantity: qty, unitPrice: i.unitPrice,
          totalPrice: i.unitPrice * qty, size: i.size, temperature: i.temperature,
          addons: i.addons, notes: i.notes,
        );
      }).toList(),
    );
  }

  void updateOrderMeta({
    String? customerName,
    String? tableNumber,
    OrderType? orderType,
    String? notes,
  }) {
    state = state.copyWith(
      customerName: customerName,
      tableNumber:  tableNumber,
      orderType:    orderType,
      notes:        notes,
    );
  }

  void clear() {
    state = CartState(orderNumber: IdGenerator.orderNumber());
  }
}

// ── KDS actions notifier ──────────────────────────────────────────────────────
@riverpod
class KdsActionsNotifier extends _$KdsActionsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> advance(String orderId, KdsStatus next) async {
    state = const AsyncLoading();
    final result = await ref.read(orderRepositoryProvider).advanceKdsStatus(orderId, next);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> togglePriority(String orderId, bool isPriority) async {
    await ref.read(orderRepositoryProvider).setPriority(orderId, isPriority);
  }
}
