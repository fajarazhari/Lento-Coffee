import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/ingredient_model.dart';
import '../../data/repositories/inventory_repository.dart';

part 'inventory_provider.g.dart';

@riverpod
Stream<List<IngredientModel>> ingredients(IngredientsRef ref) {
  return ref.watch(inventoryRepositoryProvider).watchIngredients();
}

@riverpod
Stream<List<IngredientModel>> lowStockIngredients(LowStockIngredientsRef ref) {
  return ref.watch(inventoryRepositoryProvider).watchLowStockIngredients();
}

@riverpod
class InventoryActionsNotifier extends _$InventoryActionsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> restock({
    required IngredientModel ingredient,
    required double quantity,
    required String notes,
    required String recordedBy,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(inventoryRepositoryProvider).restock(
      ingredient: ingredient,
      quantity: quantity,
      notes: notes,
      recordedBy: recordedBy,
    );
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> adjust({
    required IngredientModel ingredient,
    required double newStockLevel,
    required String reason,
    required String recordedBy,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(inventoryRepositoryProvider).adjust(
      ingredient: ingredient,
      newStockLevel: newStockLevel,
      reason: reason,
      recordedBy: recordedBy,
    );
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
