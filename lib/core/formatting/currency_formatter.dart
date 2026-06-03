import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');

  static String clp(num value) => r'$' + _formatter.format(value);
}
