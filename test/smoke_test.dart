import 'package:flutter_test/flutter_test.dart';
import 'package:kutral_ko/features/dashboard/presentation/dashboard_data.dart';

void main() {
  test('calcula saldo desde consumos menos pagos', () {
    final usuario = DashboardData.usuarios.first;

    expect(
      DashboardData.saldoUsuario(usuario.idUsuario),
      DashboardData.totalConsumidoUsuario(usuario.idUsuario) -
          DashboardData.totalPagadoUsuario(usuario.idUsuario),
    );
  });
}
