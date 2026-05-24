// Application-wide constants
abstract class AppConstants {
  // ── Business Rules ─────────────────────────────────────────────────────────
  static const double taxRate       = 0.10;         // 10% PPN
  static const String taxLabel      = 'PPN 10%';
  static const String currency      = 'IDR';
  static const String currencySymbol = 'Rp';

  // ── Loyalty ─────────────────────────────────────────────────────────────────
  static const int    loyaltyPointsPerRupiah = 1;   // 1 point / Rp 10.000
  static const int    loyaltyRupiaPerPoint   = 10000;

  // ── KDS SLA ─────────────────────────────────────────────────────────────────
  static const int kdsSlaNormalMinutes = 3;
  static const int kdsSlaDangerMinutes = 6;

  // ── Order Number ─────────────────────────────────────────────────────────────
  static const String orderPrefix = '#LC-';

  // ── Pagination ───────────────────────────────────────────────────────────────
  static const int defaultPageSize = 25;

  // ── Cache ────────────────────────────────────────────────────────────────────
  static const String hiveCartBox       = 'cart_box';
  static const String hiveDraftOrderBox = 'draft_order_box';
  static const String hiveSettingsBox   = 'settings_box';
  static const String hiveProductsBox   = 'products_box';

  // ── Session ─────────────────────────────────────────────────────────────────
  static const int autoLockMinutes = 5;

  // ── Storage Paths ────────────────────────────────────────────────────────────
  static const String storageProductImages = 'products/images';
  static const String storageAvatars       = 'users/avatars';
}
