import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// One ingredient usage in a recipe
class RecipeIngredient extends Equatable {
  const RecipeIngredient({
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  final String ingredientName; // matches IngredientModel.name
  final double quantity;       // per 1 serving
  final String unit;           // g | ml | unit

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) =>
      RecipeIngredient(
        ingredientName: m['ingredientName'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? 'g',
      );

  Map<String, dynamic> toMap() => {
    'ingredientName': ingredientName,
    'quantity':       quantity,
    'unit':           unit,
  };

  @override
  List<Object?> get props => [ingredientName, quantity, unit];
}

/// Recipe: maps a product name to its list of raw ingredients per 1 serving.
/// Firestore doc ID = productName (slug / exact match).
class RecipeModel extends Equatable {
  const RecipeModel({
    required this.productName,
    required this.ingredients,
  });

  final String productName;
  final List<RecipeIngredient> ingredients;

  factory RecipeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawList = (data['ingredients'] as List<dynamic>? ?? []);
    return RecipeModel(
      productName: data['productName'] as String? ?? doc.id,
      ingredients: rawList
          .map((e) => RecipeIngredient.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'productName': productName,
    'ingredients': ingredients.map((i) => i.toMap()).toList(),
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [productName];
}
