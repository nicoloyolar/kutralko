import '../../features/consumos/domain/consumo.dart';
import '../../features/pagos/domain/pago.dart';
import '../../features/personal/domain/asistencia.dart';
import '../../features/personal/domain/consumo_personal.dart';
import '../../features/personal/domain/trabajador.dart';
import '../../features/productos/domain/producto.dart';
import '../../features/usuarios/domain/usuario.dart';

abstract class KutralKoRepository {
  Stream<List<Usuario>> watchUsuarios({String? idUsuario});
  Stream<List<Producto>> watchProductos();
  Stream<List<Consumo>> watchConsumos({String? idUsuario});
  Stream<List<Pago>> watchPagos({String? idUsuario});
  Stream<List<Trabajador>> watchTrabajadores({String? idTrabajador});
  Stream<List<Asistencia>> watchAsistencias({String? idTrabajador});
  Stream<List<ConsumoPersonal>> watchConsumosPersonal({String? idTrabajador});

  Future<void> guardarUsuario(Usuario usuario);
  Future<void> guardarProducto(Producto producto);
  Future<void> guardarConsumo(Consumo consumo);
  Future<void> guardarPago(Pago pago);
  Future<void> guardarTrabajador(Trabajador trabajador);
  Future<void> guardarAsistencia(Asistencia asistencia);
  Future<void> guardarConsumoPersonal(ConsumoPersonal consumoPersonal);
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
  Stream<List<Trabajador>> watchTrabajadores({String? idTrabajador}) =>
      Stream.value(const []);

  @override
  Stream<List<Asistencia>> watchAsistencias({String? idTrabajador}) =>
      Stream.value(const []);

  @override
  Stream<List<ConsumoPersonal>> watchConsumosPersonal({String? idTrabajador}) =>
      Stream.value(const []);

  @override
  Future<void> guardarUsuario(Usuario usuario) async {}

  @override
  Future<void> guardarProducto(Producto producto) async {}

  @override
  Future<void> guardarConsumo(Consumo consumo) async {}

  @override
  Future<void> guardarPago(Pago pago) async {}

  @override
  Future<void> guardarTrabajador(Trabajador trabajador) async {}

  @override
  Future<void> guardarAsistencia(Asistencia asistencia) async {}

  @override
  Future<void> guardarConsumoPersonal(ConsumoPersonal consumoPersonal) async {}

  @override
  Future<void> registrarAuditoria(Map<String, dynamic> auditoria) async {}
}
