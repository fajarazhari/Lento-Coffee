import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

abstract class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  static final _formatterCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  /// Formats 45000.0 → "Rp 45.000"
  static String format(double amount) => _formatter.format(amount);

  /// Formats 1500000.0 → "Rp 1,5 Jt"
  static String compact(double amount) => _formatterCompact.format(amount);

  /// Parses "Rp 45.000" → 45000.0
  static double parse(String text) {
    final cleaned = text
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(' ', '')
        .replaceAll('.', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Formats as a plain number with dots: 1500000 → "1.500.000"
  static String plain(double amount) {
    return NumberFormat('#,###', 'id_ID').format(amount);
  }
}
