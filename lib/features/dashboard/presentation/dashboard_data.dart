import '../../consumos/domain/consumo.dart';
import '../../pagos/domain/pago.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';

class DashboardData {
  const DashboardData._();

  static final List<Usuario> usuarios = [];
  static final List<Producto> productos = [];
  static final List<Consumo> consumos = [];
  static final List<Pago> pagos = [];

  static int totalConsumidoUsuario(String idUsuario) {
    return consumos
        .where(
          (consumo) =>
              consumo.idUsuario == idUsuario && !consumo.estaAnuladoConsumo,
        )
        .fold(0, (total, consumo) => total + consumo.totalConsumo);
  }

  static int totalPagadoUsuario(String idUsuario) {
    return pagos
        .where((pago) => pago.idUsuario == idUsuario && !pago.estaAnuladoPago)
        .fold(0, (total, pago) => total + pago.montoPago);
  }

  static int saldoUsuario(String idUsuario) {
    return totalConsumidoUsuario(idUsuario) - totalPagadoUsuario(idUsuario);
  }
}
