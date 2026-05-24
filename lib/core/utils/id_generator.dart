import 'dart:math';

import '../constants/app_constants.dart';

abstract class IdGenerator {
  static final _random = Random();

  /// Generates a Lento Coffee order number, e.g. "#LC-8219"
  static String orderNumber() {
    final suffix = _random.nextInt(9000) + 1000; // 1000–9999
    return '${AppConstants.orderPrefix}$suffix';
  }

  /// Generates a short display ticket code from a Firestore doc ID
  /// e.g. last 3 chars of order ID → "A219"
  static String ticketCode(String orderId) {
    final suffix = orderId.length >= 3
        ? orderId.substring(orderId.length - 3)
        : orderId.padLeft(3, '0');
    return 'A$suffix';
  }

  /// Generates a timestamped document ID for offline-created records
  static String offlineId([String prefix = 'offline']) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
