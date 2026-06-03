import 'package:flutter_test/flutter_test.dart';
import 'package:kutral_ko/features/dashboard/presentation/dashboard_data.dart';

void main() {
  test('inicia sin datos mock y calcula saldo en cero', () {
    expect(DashboardData.usuarios, isEmpty);
    expect(DashboardData.productos, isEmpty);
    expect(DashboardData.consumos, isEmpty);
    expect(DashboardData.pagos, isEmpty);
    expect(DashboardData.saldoUsuario('usr_inexistente'), 0);
  });
}
