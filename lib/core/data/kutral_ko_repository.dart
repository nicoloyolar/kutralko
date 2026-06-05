import '../../features/consumos/domain/consumo.dart';
import '../../features/pagos/domain/pago.dart';
import '../../features/productos/domain/producto.dart';
import '../../features/usuarios/domain/usuario.dart';

abstract class KutralKoRepository {
  Stream<List<Usuario>> watchUsuarios({String? idUsuario});
  Stream<List<Producto>> watchProductos();
  Stream<List<Consumo>> watchConsumos({String? idUsuario});
  Stream<List<Pago>> watchPagos({String? idUsuario});

  Future<void> guardarUsuario(Usuario usuario);
  Future<void> guardarProducto(Producto producto);
  Future<void> guardarConsumo(Consumo consumo);
  Future<void> guardarPago(Pago pago);
  Future<void> registrarAuditoria(Map<String, dynamic> auditoria);
}

class EmptyKutralKoRepository implements KutralKoRepository {
  const EmptyKutralKoRepository();

  @override
  Stream<List<Usuario>> watchUsuarios({String? idUsuario}) =>
      Stream.value(const []);

  @override
  Stream<List<Producto>> watchProductos() => Stream.value(const []);

  @override
  Stream<List<Consumo>> watchConsumos({String? idUsuario}) =>
      Stream.value(const []);

  @override
  Stream<List<Pago>> watchPagos({String? idUsuario}) => Stream.value(const []);

  @override
  Future<void> guardarUsuario(Usuario usuario) async {}

  @override
  Future<void> guardarProducto(Producto producto) async {}

  @override
  Future<void> guardarConsumo(Consumo consumo) async {}

  @override
  Future<void> guardarPago(Pago pago) async {}

  @override
  Future<void> registrarAuditoria(Map<String, dynamic> auditoria) async {}
}
