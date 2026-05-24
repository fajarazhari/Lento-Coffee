import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ProductStatus { active, soldOut, hidden }
enum ProductCategory { coffee, nonCoffee, tea, pastry, addon }

extension ProductCategoryX on ProductCategory {
  String get label => switch (this) {
    ProductCategory.coffee    => 'Coffee',
    ProductCategory.nonCoffee => 'Non Coffee',
    ProductCategory.tea       => 'Tea',
    ProductCategory.pastry    => 'Pastry',
    ProductCategory.addon     => 'Add On',
  };

  static ProductCategory fromString(String s) => switch (s) {
    'Coffee'     => ProductCategory.coffee,
    'Non Coffee' => ProductCategory.nonCoffee,
    'Tea'        => ProductCategory.tea,
    'Pastry'     => ProductCategory.pastry,
    'Add On'     => ProductCategory.addon,
    _            => ProductCategory.coffee,
  };
}

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    this.emoji = '☕',
    this.imageUrl,
    this.status = ProductStatus.active,
    this.sortOrder = 0,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final double basePrice;
  final String emoji;
  final String? imageUrl;
  final ProductStatus status;
  final int sortOrder;
  final DateTime? updatedAt;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id:          doc.id,
      name:        data['name']        as String? ?? '',
      description: data['description'] as String? ?? '',
      category:    ProductCategoryX.fromString(data['category'] as String? ?? 'Coffee'),
      // Seed stores 'price', model stores 'basePrice' — support both
      basePrice:   (data['price'] as num?)?.toDouble()
                ?? (data['basePrice'] as num?)?.toDouble() ?? 0,
      emoji:       data['emoji']       as String? ?? '☕',
      imageUrl:    data['imageUrl']    as String?,
      // Compare both sides lowercase to avoid camelCase mismatch (soldOut vs soldout)
      status:      ProductStatus.values.firstWhere(
        (s) => s.name.toLowerCase() ==
            (data['status'] as String? ?? 'active').toLowerCase(),
        orElse: () => ProductStatus.active,
      ),
      sortOrder:   data['sortOrder']   as int? ?? 0,
      updatedAt:   (data['updatedAt']  as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':        name,
    'description': description,
    'category':    category.label,
    'basePrice':   basePrice,
    'price':       basePrice,
    'emoji':       emoji,
    'imageUrl':    imageUrl,
    'status':      status.name,
    'sortOrder':   sortOrder,
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, name, basePrice, status, emoji];
}

class ProductVariantModel extends Equatable {
  const ProductVariantModel({
    required this.id,
    required this.type,
    required this.option,
    required this.priceModifier,
    this.isDefault = false,
  });

  final String id;
  final String type;    // "Size" | "Temperature"
  final String option;  // "Small" | "Large" | "Hot" | "Ice"
  final double priceModifier;
  final bool isDefault;

  factory ProductVariantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductVariantModel(
      id:            doc.id,
      type:          data['type']          as String? ?? '',
      option:        data['option']        as String? ?? '',
      priceModifier: (data['priceModifier'] as num?)?.toDouble() ?? 0,
      isDefault:     data['isDefault']     as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type':          type,
    'option':        option,
    'priceModifier': priceModifier,
    'isDefault':     isDefault,
  };

  @override
  List<Object?> get props => [id, type, option, priceModifier];
}

class AddonModel extends Equatable {
  const AddonModel({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final double price;
  final String? category;
  final bool isEnabled;

  factory AddonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AddonModel(
      id:        doc.id,
      name:      data['name']      as String? ?? '',
      price:     (data['price']    as num?)?.toDouble() ?? 0,
      category:  data['category']  as String?,
      isEnabled: data['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':      name,
    'price':     price,
    'category':  category,
    'isEnabled': isEnabled,
  };

  @override
  List<Object?> get props => [id, name, price, isEnabled];
}
