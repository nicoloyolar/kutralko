import '../../consumos/domain/consumo.dart';
import '../../pagos/domain/pago.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';

class DashboardData {
  const DashboardData._();

  static final List<Usuario> usuarios = [
    const Usuario(
      idUsuario: 'usr_001',
      nombreUsuario: 'Felipe',
      telefonoUsuario: '+56 9 1234 5678',
      notaUsuario: 'Convenio mensual almuerzos y barra.',
      estaActivoUsuario: true,
    ),
    const Usuario(
      idUsuario: 'usr_002',
      nombreUsuario: 'Invitado staff',
      telefonoUsuario: '',
      notaUsuario: 'Cuenta interna de prueba.',
      estaActivoUsuario: true,
    ),
  ];

  static final List<Producto> productos = [
    const Producto(
      idProducto: 'prd_001',
      nombreProducto: 'Menu ejecutivo',
      nombreCategoriaProducto: 'Almuerzos',
      precioProducto: 8500,
      estaActivoProducto: true,
      esProductoFrecuente: true,
    ),
    const Producto(
      idProducto: 'prd_002',
      nombreProducto: 'Cafe cortado',
      nombreCategoriaProducto: 'Cafe',
      precioProducto: 2200,
      estaActivoProducto: true,
      esProductoFrecuente: true,
    ),
    const Producto(
      idProducto: 'prd_003',
      nombreProducto: 'Mocktail de autor',
      nombreCategoriaProducto: 'Barra',
      precioProducto: 6900,
      estaActivoProducto: true,
      esProductoFrecuente: false,
    ),
  ];

  static final List<Consumo> consumos = [
    Consumo(
      idConsumo: 'cns_001',
      idUsuario: 'usr_001',
      idProducto: 'prd_001',
      nombreProductoSnapshot: 'Menu ejecutivo',
      precioProductoSnapshot: 8500,
      cantidadConsumo: 4,
      fechaConsumo: DateTime(2026, 6, 1),
      notaConsumo: 'Semana 1',
      estaAnuladoConsumo: false,
    ),
    Consumo(
      idConsumo: 'cns_002',
      idUsuario: 'usr_001',
      idProducto: 'prd_002',
      nombreProductoSnapshot: 'Cafe cortado',
      precioProductoSnapshot: 2200,
      cantidadConsumo: 3,
      fechaConsumo: DateTime(2026, 6, 2),
      notaConsumo: '',
      estaAnuladoConsumo: false,
    ),
    Consumo(
      idConsumo: 'cns_003',
      idUsuario: 'usr_002',
      idProducto: 'prd_003',
      nombreProductoSnapshot: 'Mocktail de autor',
      precioProductoSnapshot: 6900,
      cantidadConsumo: 2,
      fechaConsumo: DateTime(2026, 6, 2),
      notaConsumo: '',
      estaAnuladoConsumo: false,
    ),
  ];

  static final List<Pago> pagos = [
    Pago(
      idPago: 'pag_001',
      idUsuario: 'usr_001',
      montoPago: 18000,
      metodoPago: 'Transferencia',
      fechaPago: DateTime(2026, 6, 2),
      notaPago: 'Abono mensual',
      estaAnuladoPago: false,
    ),
  ];

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
