import 'package:intl/intl.dart';

String formatMoney(double amount, String currencyCode) {
  final code = currencyCode.toUpperCase().trim();
  final digits = NumberFormat('#,##0.00');

  // Avoid locale symbols like "Dh" for AED — always show ISO code.
  if (code == 'AED') {
    return 'AED ${digits.format(amount)}';
  }

  try {
    return NumberFormat.simpleCurrency(name: code).format(amount);
  } catch (_) {
    return '$code ${digits.format(amount)}';
  }
}
