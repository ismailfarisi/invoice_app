import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String symbol = '\$',
    String? currency,
  }) {
    final effectiveSymbol = currency ?? symbol;
    final formatter = NumberFormat.currency(symbol: effectiveSymbol, decimalDigits: 2);
    return formatter.format(amount);
  }
}
