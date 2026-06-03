import 'package:flutter_test/flutter_test.dart';
import 'package:kutral_ko/core/formatting/currency_formatter.dart';

void main() {
  test('formatea CLP con simbolo a la izquierda y miles chilenos', () {
    expect(CurrencyFormatter.clp(8500), r'$8.500');
  });
}
