import '../../features/consumos/domain/consumo.dart';
import '../../features/pagos/domain/pago.dart';
import '../../features/productos/domain/producto.dart';
import '../../features/usuarios/domain/usuario.dart';

abstract class KutralKoRepository {
  Stream<List<Usuario>> watchUsuarios();
  Stream<List<Producto>> watchProductos();
  Stream<List<Consumo>> watchConsumos();
  Stream<List<Pago>> watchPagos();

  Future<void> guardarUsuario(Usuario usuario);
  Future<void> guardarProducto(Producto producto);
  Future<void> guardarConsumo(Consumo consumo);
  Future<void> guardarPago(Pago pago);
}

class EmptyKutralKoRepository implements KutralKoRepository {
  const EmptyKutralKoRepository();

  @override
  Stream<List<Usuario>> watchUsuarios() => Stream.value(const []);

  @override
  Stream<List<Producto>> watchProductos() => Stream.value(const []);

  @override
  Stream<List<Consumo>> watchConsumos() => Stream.value(const []);

  @override
  Stream<List<Pago>> watchPagos() => Stream.value(const []);

  @override
  Future<void> guardarUsuario(Usuario usuario) async {}

  @override
  Future<void> guardarProducto(Producto producto) async {}

  @override
  Future<void> guardarConsumo(Consumo consumo) async {}

  @override
  Future<void> guardarPago(Pago pago) async {}
}
