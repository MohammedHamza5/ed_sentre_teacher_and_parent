import 'package:intl/intl.dart';

/// Formats an amount using Arabic number format
String formatCurrency(double amount) {
  if (amount == 0) return '0';
  final formatter = NumberFormat('#,##0.##', 'ar');
  return formatter.format(amount);
}
