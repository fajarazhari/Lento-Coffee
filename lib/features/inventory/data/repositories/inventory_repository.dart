import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../data/models/ingredient_model.dart';
import '../../data/models/recipe_model.dart';

part 'inventory_repository.g.dart';

@riverpod
InventoryRepository inventoryRepository(InventoryRepositoryRef ref) {
  return InventoryRepository(firestore: FirebaseFirestore.instance);
}

class InventoryRepository {
  InventoryRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _ingredients =>
      firestore.collection(FirestorePaths.ingredients);
  CollectionReference get _logs =>
      firestore.collection(FirestorePaths.inventoryLogs);
  CollectionReference get _recipes =>
      firestore.collection(FirestorePaths.recipes);

  // ── Live ingredient stream (ordered by name) ─────────────────────────────
  Stream<List<IngredientModel>> watchIngredients() {
    return _ingredients
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(IngredientModel.fromFirestore).toList());
  }

  // ── Low stock alerts ───────────────────────────────────────────────────────
  Stream<List<IngredientModel>> watchLowStockIngredients() {
    return watchIngredients()
        .map((list) => list.where((i) => i.isLowStock).toList());
  }

  // ── Create new ingredient ─────────────────────────────────────────────────
  Future<Either<Failure, Unit>> createIngredient(
      IngredientModel ingredient) async {
    try {
      await _ingredients.add(ingredient.toFirestore());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Update ingredient details ─────────────────────────────────────────────
  Future<Either<Failure, Unit>> updateIngredient(
      IngredientModel ingredient) async {
    try {
      await _ingredients.doc(ingredient.id).update(ingredient.toFirestore());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Delete ingredient ─────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> deleteIngredient(String id) async {
    try {
      await _ingredients.doc(id).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Restock an ingredient ──────────────────────────────────────────────────
  Future<Either<Failure, Unit>> restock({
    required IngredientModel ingredient,
    required double quantity,
    required String notes,
    String recordedBy = 'cashier',
  }) async {
    try {
      final newStock = ingredient.currentStock + quantity;
      final batch = firestore.batch();

      batch.update(_ingredients.doc(ingredient.id), {
        'currentStock':    newStock,
        'lastRestockedAt': FieldValue.serverTimestamp(),
        'updatedAt':       FieldValue.serverTimestamp(),
      });

      final logRef = _logs.doc();
      batch.set(logRef, InventoryLogModel(
        id:             logRef.id,
        ingredientId:   ingredient.id,
        ingredientName: ingredient.name,
        action:         InventoryAction.restock,
        quantity:       quantity,
        balanceBefore:  ingredient.currentStock,
        balanceAfter:   newStock,
        reason:         notes.isEmpty ? 'Restock manual' : notes,
        recordedBy:     recordedBy,
        createdAt:      DateTime.now(),
      ).toFirestore());

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Manual stock adjustment ────────────────────────────────────────────────
  Future<Either<Failure, Unit>> adjust({
    required IngredientModel ingredient,
    required double newStockLevel,
    required String reason,
    String recordedBy = 'cashier',
  }) async {
    try {
      final delta = newStockLevel - ingredient.currentStock;
      final batch = firestore.batch();

      batch.update(_ingredients.doc(ingredient.id), {
        'currentStock': newStockLevel,
        'updatedAt':    FieldValue.serverTimestamp(),
      });

      final logRef = _logs.doc();
      batch.set(logRef, InventoryLogModel(
        id:             logRef.id,
        ingredientId:   ingredient.id,
        ingredientName: ingredient.name,
        action:         InventoryAction.adjustment,
        quantity:       delta,
        balanceBefore:  ingredient.currentStock,
        balanceAfter:   newStockLevel,
        reason:         reason,
        recordedBy:     recordedBy,
        createdAt:      DateTime.now(),
      ).toFirestore());

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Deduct stock when order is placed ─────────────────────────────────────
  /// Called after payment is confirmed.
  /// For each order item, reads recipe and deducts ingredient stock.
  Future<void> deductOrderStock({
    required String orderId,
    required List<OrderItemModel> items,
  }) async {
    try {
      // 1. Fetch all recipes matching ordered product names and addons
      final productNames = <String>{};
      for (final item in items) {
        productNames.add(item.productName);
        productNames.addAll(item.addons);
      }
      
      final recipeSnaps = await Future.wait(
        productNames.map((name) => _recipes.doc(_slugify(name)).get()),
      );

      // Build map: productName → RecipeModel
      final recipeMap = <String, RecipeModel>{};
      for (final snap in recipeSnaps) {
        if (snap.exists) {
          final recipe = RecipeModel.fromFirestore(snap);
          recipeMap[recipe.productName] = recipe;
        }
      }

      if (recipeMap.isEmpty) return; // No recipes configured yet

      // 2. Compute total deductions: ingredientName → totalQty
      final deductions = <String, double>{};
      for (final item in items) {
        // Main product recipe
        final mainRecipe = recipeMap[item.productName];
        if (mainRecipe != null) {
          for (final ri in mainRecipe.ingredients) {
            deductions[ri.ingredientName] =
                (deductions[ri.ingredientName] ?? 0) +
                    ri.quantity * item.quantity;
          }
        }
        
        // Addon recipes
        for (final addon in item.addons) {
          final addonRecipe = recipeMap[addon];
          if (addonRecipe != null) {
            for (final ri in addonRecipe.ingredients) {
              deductions[ri.ingredientName] =
                  (deductions[ri.ingredientName] ?? 0) +
                      ri.quantity * item.quantity;
            }
          }
        }
      }

      if (deductions.isEmpty) return;

      // 3. Fetch matching ingredients by name (query by name)
      final ingredientNames = deductions.keys.toList();
      // Firestore whereIn supports up to 30 values
      final ingSnap = await _ingredients
          .where('name', whereIn: ingredientNames.take(30).toList())
          .get();

      final ingredients = {
        for (final doc in ingSnap.docs)
          (doc.data() as Map<String, dynamic>)['name'] as String:
              IngredientModel.fromFirestore(doc),
      };

      // 4. Batch update stock
      final batch = firestore.batch();
      for (final entry in deductions.entries) {
        final ing = ingredients[entry.key];
        if (ing == null) continue;

        final deductQty  = entry.value;
        final newStock   = (ing.currentStock - deductQty).clamp(0.0, double.infinity);

        batch.update(_ingredients.doc(ing.id), {
          'currentStock': newStock,
          'updatedAt':    FieldValue.serverTimestamp(),
        });

        final logRef = _logs.doc(IdGenerator.offlineId('log'));
        batch.set(logRef, InventoryLogModel(
          id:             logRef.id,
          ingredientId:   ing.id,
          ingredientName: ing.name,
          action:         InventoryAction.deduction,
          quantity:       -deductQty,
          balanceBefore:  ing.currentStock,
          balanceAfter:   newStock,
          reason:         'Order #$orderId',
          orderId:        orderId,
          recordedBy:     'system',
          createdAt:      DateTime.now(),
        ).toFirestore());
      }

      await batch.commit();
    } catch (e) {
      // Non-fatal: log but don't interrupt order flow
      // ignore: avoid_print
      print('[InventoryRepository] deductOrderStock error: $e');
    }
  }

  // ── Inventory log history ──────────────────────────────────────────────────
  Future<Either<Failure, List<InventoryLogModel>>> getLogs({
    String? ingredientId,
    DateTime? since,
    int limit = 50,
  }) async {
    try {
      Query query = _logs.orderBy('createdAt', descending: true).limit(limit);
      if (ingredientId != null) {
        query = query.where('ingredientId', isEqualTo: ingredientId);
      }
      if (since != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }
      final snap = await query.get();
      return Right(snap.docs.map(InventoryLogModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Slugify product name for use as Firestore doc ID in recipes collection.
  static String _slugify(String name) =>
      name.toLowerCase().replaceAll(' ', '_');
}
