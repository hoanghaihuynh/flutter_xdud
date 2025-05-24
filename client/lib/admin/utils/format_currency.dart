import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  return format.format(amount);
}
