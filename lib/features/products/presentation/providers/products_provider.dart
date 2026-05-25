import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

part 'products_provider.g.dart';

/// Live stream of all non-hidden products (for POS product grid)
@riverpod
Stream<List<ProductModel>> activeProducts(ActiveProductsRef ref) {
  return ref.watch(productRepositoryProvider).watchActiveProducts();
}

/// All products including hidden (for management page)
@riverpod
Stream<List<ProductModel>> allProducts(AllProductsRef ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
}

/// Products filtered by category
@riverpod
List<ProductModel> filteredProducts(FilteredProductsRef ref, String category) {
  final products = ref.watch(activeProductsProvider).valueOrNull ?? [];
  if (category == 'All') {
    return products.where((p) => p.category != ProductCategory.addon).toList();
  }
  return products.where((p) => p.category.label == category).toList();
}
