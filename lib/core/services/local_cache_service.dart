import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';

part 'local_cache_service.g.dart';

@riverpod
LocalCacheService localCacheService(LocalCacheServiceRef ref) {
  return LocalCacheService();
}

/// Thin wrapper around Hive for offline-first storage.
/// Used to cache: cart state, draft orders, products, and settings.
class LocalCacheService {
  // ── Cart (active session) ─────────────────────────────────────────────────
  Future<void> saveCart(Map<String, dynamic> cartJson) async {
    final box = await Hive.openBox(AppConstants.hiveCartBox);
    await box.put('current_cart', cartJson);
  }

  Future<Map<String, dynamic>?> loadCart() async {
    final box = await Hive.openBox(AppConstants.hiveCartBox);
    final raw = box.get('current_cart');
    return raw != null ? Map<String, dynamic>.from(raw as Map) : null;
  }

  Future<void> clearCart() async {
    final box = await Hive.openBox(AppConstants.hiveCartBox);
    await box.delete('current_cart');
  }

  // ── Draft orders (offline queue) ──────────────────────────────────────────
  Future<void> saveDraftOrder(String id, Map<String, dynamic> orderJson) async {
    final box = await Hive.openBox(AppConstants.hiveDraftOrderBox);
    await box.put(id, orderJson);
  }

  Future<List<Map<String, dynamic>>> loadAllDraftOrders() async {
    final box = await Hive.openBox(AppConstants.hiveDraftOrderBox);
    return box.values
        .whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  Future<void> removeDraftOrder(String id) async {
    final box = await Hive.openBox(AppConstants.hiveDraftOrderBox);
    await box.delete(id);
  }

  // ── Products (TTL cache) ──────────────────────────────────────────────────
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final box = await Hive.openBox(AppConstants.hiveProductsBox);
    await box.put('products', products);
    await box.put('products_cached_at', DateTime.now().toIso8601String());
  }

  Future<(List<Map<String, dynamic>>?, DateTime?)> loadCachedProducts() async {
    final box = await Hive.openBox(AppConstants.hiveProductsBox);
    final raw = box.get('products');
    final cachedAt = box.get('products_cached_at') as String?;
    if (raw == null) return (null, null);
    final products = (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final dt = cachedAt != null ? DateTime.tryParse(cachedAt) : null;
    return (products, dt);
  }

  // ── Generic settings ──────────────────────────────────────────────────────
  Future<void> putSetting(String key, dynamic value) async {
    final box = await Hive.openBox(AppConstants.hiveSettingsBox);
    await box.put(key, value);
  }

  Future<T?> getSetting<T>(String key) async {
    final box = await Hive.openBox(AppConstants.hiveSettingsBox);
    return box.get(key) as T?;
  }
}
