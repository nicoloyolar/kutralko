import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/kutral_ko_repository.dart';
import '../../features/consumos/domain/consumo.dart';
import '../../features/pagos/domain/pago.dart';
import '../../features/productos/domain/producto.dart';
import '../../features/usuarios/domain/usuario.dart';

class FirestoreKutralKoRepository implements KutralKoRepository {
  FirestoreKutralKoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection('usuarios');
  CollectionReference<Map<String, dynamic>> get _productos =>
      _firestore.collection('productos');
  CollectionReference<Map<String, dynamic>> get _consumos =>
      _firestore.collection('consumos');
  CollectionReference<Map<String, dynamic>> get _pagos =>
      _firestore.collection('pagos');

  @override
  Stream<List<Usuario>> watchUsuarios() {
    return _usuarios
        .orderBy('nombreUsuario')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_usuarioFromDoc).toList());
  }

  @override
  Stream<List<Producto>> watchProductos() {
    return _productos
        .orderBy('nombreProducto')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_productoFromDoc).toList());
  }

  @override
  Stream<List<Consumo>> watchConsumos() {
    return _consumos
        .orderBy('fechaConsumo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_consumoFromDoc).toList());
  }

  @override
  Stream<List<Pago>> watchPagos() {
    return _pagos
        .orderBy('fechaPago', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_pagoFromDoc).toList());
  }

  @override
  Future<void> guardarUsuario(Usuario usuario) {
    final doc = usuario.idUsuario.isEmpty
        ? _usuarios.doc()
        : _usuarios.doc(usuario.idUsuario);

    return doc.set(_usuarioToMap(usuario.copyWith(idUsuario: doc.id)));
  }

  @override
  Future<void> guardarProducto(Producto producto) {
    final doc = producto.idProducto.isEmpty
        ? _productos.doc()
        : _productos.doc(producto.idProducto);

    return doc.set(_productoToMap(producto.copyWith(idProducto: doc.id)));
  }

  @override
  Future<void> guardarConsumo(Consumo consumo) {
    final doc = consumo.idConsumo.isEmpty
        ? _consumos.doc()
        : _consumos.doc(consumo.idConsumo);

    return doc.set(_consumoToMap(consumo.copyWith(idConsumo: doc.id)));
  }

  @override
  Future<void> guardarPago(Pago pago) {
    final doc = pago.idPago.isEmpty ? _pagos.doc() : _pagos.doc(pago.idPago);
    return doc.set(_pagoToMap(pago.copyWith(idPago: doc.id)));
  }
}

Usuario _usuarioFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  return Usuario(
    idUsuario: data['idUsuario'] as String? ?? doc.id,
    nombreUsuario: data['nombreUsuario'] as String? ?? '',
    telefonoUsuario: data['telefonoUsuario'] as String? ?? '',
    notaUsuario: data['notaUsuario'] as String? ?? '',
    estaActivoUsuario: data['estaActivoUsuario'] as bool? ?? true,
  );
}

Map<String, dynamic> _usuarioToMap(Usuario usuario) {
  return {
    'idUsuario': usuario.idUsuario,
    'nombreUsuario': usuario.nombreUsuario,
    'telefonoUsuario': usuario.telefonoUsuario,
    'notaUsuario': usuario.notaUsuario,
    'estaActivoUsuario': usuario.estaActivoUsuario,
  };
}

Producto _productoFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  return Producto(
    idProducto: data['idProducto'] as String? ?? doc.id,
    nombreProducto: data['nombreProducto'] as String? ?? '',
    nombreCategoriaProducto:
        data['nombreCategoriaProducto'] as String? ?? 'Sin categoria',
    precioProducto: data['precioProducto'] as int? ?? 0,
    estaActivoProducto: data['estaActivoProducto'] as bool? ?? true,
    esProductoFrecuente: data['esProductoFrecuente'] as bool? ?? false,
  );
}

Map<String, dynamic> _productoToMap(Producto producto) {
  return {
    'idProducto': producto.idProducto,
    'nombreProducto': producto.nombreProducto,
    'nombreCategoriaProducto': producto.nombreCategoriaProducto,
    'precioProducto': producto.precioProducto,
    'estaActivoProducto': producto.estaActivoProducto,
    'esProductoFrecuente': producto.esProductoFrecuente,
  };
}

Consumo _consumoFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  return Consumo(
    idConsumo: data['idConsumo'] as String? ?? doc.id,
    idUsuario: data['idUsuario'] as String? ?? '',
    idProducto: data['idProducto'] as String? ?? '',
    nombreProductoSnapshot: data['nombreProductoSnapshot'] as String? ?? '',
    precioProductoSnapshot: data['precioProductoSnapshot'] as int? ?? 0,
    cantidadConsumo: data['cantidadConsumo'] as int? ?? 0,
    fechaConsumo:
        (data['fechaConsumo'] as Timestamp?)?.toDate() ?? DateTime.now(),
    notaConsumo: data['notaConsumo'] as String? ?? '',
    estaAnuladoConsumo: data['estaAnuladoConsumo'] as bool? ?? false,
  );
}

Map<String, dynamic> _consumoToMap(Consumo consumo) {
  return {
    'idConsumo': consumo.idConsumo,
    'idUsuario': consumo.idUsuario,
    'idProducto': consumo.idProducto,
    'nombreProductoSnapshot': consumo.nombreProductoSnapshot,
    'precioProductoSnapshot': consumo.precioProductoSnapshot,
    'cantidadConsumo': consumo.cantidadConsumo,
    'fechaConsumo': Timestamp.fromDate(consumo.fechaConsumo),
    'notaConsumo': consumo.notaConsumo,
    'estaAnuladoConsumo': consumo.estaAnuladoConsumo,
  };
}

Pago _pagoFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  return Pago(
    idPago: data['idPago'] as String? ?? doc.id,
    idUsuario: data['idUsuario'] as String? ?? '',
    montoPago: data['montoPago'] as int? ?? 0,
    metodoPago: data['metodoPago'] as String? ?? '',
    fechaPago: (data['fechaPago'] as Timestamp?)?.toDate() ?? DateTime.now(),
    notaPago: data['notaPago'] as String? ?? '',
    estaAnuladoPago: data['estaAnuladoPago'] as bool? ?? false,
  );
}

Map<String, dynamic> _pagoToMap(Pago pago) {
  return {
    'idPago': pago.idPago,
    'idUsuario': pago.idUsuario,
    'montoPago': pago.montoPago,
    'metodoPago': pago.metodoPago,
    'fechaPago': Timestamp.fromDate(pago.fechaPago),
    'notaPago': pago.notaPago,
    'estaAnuladoPago': pago.estaAnuladoPago,
  };
}

extension on Consumo {
  Consumo copyWith({String? idConsumo}) {
    return Consumo(
      idConsumo: idConsumo ?? this.idConsumo,
      idUsuario: idUsuario,
      idProducto: idProducto,
      nombreProductoSnapshot: nombreProductoSnapshot,
      precioProductoSnapshot: precioProductoSnapshot,
      cantidadConsumo: cantidadConsumo,
      fechaConsumo: fechaConsumo,
      notaConsumo: notaConsumo,
      estaAnuladoConsumo: estaAnuladoConsumo,
    );
  }
}

extension on Pago {
  Pago copyWith({String? idPago}) {
    return Pago(
      idPago: idPago ?? this.idPago,
      idUsuario: idUsuario,
      montoPago: montoPago,
      metodoPago: metodoPago,
      fechaPago: fechaPago,
      notaPago: notaPago,
      estaAnuladoPago: estaAnuladoPago,
    );
  }
}
