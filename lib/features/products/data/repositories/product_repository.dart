import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../data/models/product_model.dart';

part 'product_repository.g.dart';

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository(firestore: FirebaseFirestore.instance);
}

class ProductRepository {
  ProductRepository({required this.firestore});
  final FirebaseFirestore firestore;

  CollectionReference get _products => firestore.collection(FirestorePaths.products);
  CollectionReference get _addons   => firestore.collection(FirestorePaths.addons);

  // ── Live stream of active products ─────────────────────────────────────────
  Stream<List<ProductModel>> watchActiveProducts() {
    return _products
        .where('status', whereIn: [
          ProductStatus.active.name,
          ProductStatus.soldOut.name,
        ])
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
  }

  // ── All products for management screen ────────────────────────────────────
  Stream<List<ProductModel>> watchAllProducts() {
    return _products
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
  }

  // ── Get variants for a product ─────────────────────────────────────────────
  Future<Either<Failure, List<ProductVariantModel>>> getVariants(String productId) async {
    try {
      final snap = await firestore
          .collection(FirestorePaths.productVariants(productId))
          .get();
      return Right(snap.docs.map(ProductVariantModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Get all addons ────────────────────────────────────────────────────────
  Future<Either<Failure, List<AddonModel>>> getAddons() async {
    try {
      final snap = await _addons.where('isEnabled', isEqualTo: true).get();
      return Right(snap.docs.map(AddonModel.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Create product ────────────────────────────────────────────────────────
  Future<Either<Failure, String>> createProduct(ProductModel product) async {
    try {
      final doc = await _products.add(product.toFirestore());
      return Right(doc.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Update product ────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> updateProduct(ProductModel product) async {
    try {
      await _products.doc(product.id).update(product.toFirestore());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Toggle status ─────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> setStatus(
      String productId, ProductStatus status) async {
    try {
      await _products.doc(productId).update({
        'status':    status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Delete product ────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> deleteProduct(String productId) async {
    try {
      await _products.doc(productId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
