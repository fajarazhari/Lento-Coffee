// Firestore collection path constants — single source of truth
abstract class FirestorePaths {
  // Top-level collections
  static const String users           = 'users';
  static const String products        = 'products';
  static const String addons          = 'addons';
  static const String ingredients     = 'ingredients';
  static const String recipes         = 'recipes';
  static const String orders          = 'orders';
  static const String payments        = 'payments';
  static const String shifts          = 'shifts';
  static const String inventoryLogs   = 'inventory_logs';
  static const String loyaltyAccounts = 'loyalty_accounts';
  static const String auditLogs       = 'audit_logs';
  static const String settings        = 'settings';

  // Subcollections
  static String productVariants(String productId) =>
      '$products/$productId/variants';

  static String orderItems(String orderId) =>
      '$orders/$orderId/items';

  static String cashTransactions(String shiftId) =>
      '$shifts/$shiftId/cash_transactions';

  // Settings document ID
  static const String globalSettingsDoc = 'global';
}
