import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/kutral_ko_repository.dart';
import '../../features/consumos/domain/consumo.dart';
import '../../features/pagos/domain/pago.dart';
import '../../features/personal/domain/asistencia.dart';
import '../../features/personal/domain/consumo_personal.dart';
import '../../features/personal/domain/trabajador.dart';
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
  CollectionReference<Map<String, dynamic>> get _trabajadores =>
      _firestore.collection('trabajadores');
  CollectionReference<Map<String, dynamic>> get _asistencias =>
      _firestore.collection('asistencias');
  CollectionReference<Map<String, dynamic>> get _consumosPersonal =>
      _firestore.collection('consumosPersonal');
  CollectionReference<Map<String, dynamic>> get _auditoria =>
      _firestore.collection('auditoria');

  @override
  Stream<List<Usuario>> watchUsuarios({String? idUsuario}) {
    if (idUsuario != null && idUsuario.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    if (idUsuario != null && idUsuario.isNotEmpty) {
      return _usuarios.doc(idUsuario).snapshots().map((doc) {
        if (!doc.exists) {
          return const <Usuario>[];
        }
        return [_usuarioFromDoc(doc)];
      });
    }

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
  Stream<List<Consumo>> watchConsumos({String? idUsuario}) {
    if (idUsuario != null && idUsuario.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    Query<Map<String, dynamic>> query = _consumos;
    if (idUsuario != null && idUsuario.isNotEmpty) {
      query = query.where('idUsuario', isEqualTo: idUsuario);
    }

    return query
        .orderBy('fechaConsumo', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_consumoFromDoc).toList());
  }

  @override
  Stream<List<Pago>> watchPagos({String? idUsuario}) {
    if (idUsuario != null && idUsuario.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    Query<Map<String, dynamic>> query = _pagos;
    if (idUsuario != null && idUsuario.isNotEmpty) {
      query = query.where('idUsuario', isEqualTo: idUsuario);
    }

    return query
        .orderBy('fechaPago', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_pagoFromDoc).toList());
  }

  @override
  Stream<List<Trabajador>> watchTrabajadores({String? idTrabajador}) {
    if (idTrabajador != null && idTrabajador.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    if (idTrabajador != null && idTrabajador.isNotEmpty) {
      return _trabajadores.doc(idTrabajador).snapshots().map((doc) {
        if (!doc.exists) {
          return const <Trabajador>[];
        }
        return [_trabajadorFromDoc(doc)];
      });
    }

    return _trabajadores
        .orderBy('nombreTrabajador')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_trabajadorFromDoc).toList());
  }

  @override
  Stream<List<Asistencia>> watchAsistencias({String? idTrabajador}) {
    if (idTrabajador != null && idTrabajador.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    Query<Map<String, dynamic>> query = _asistencias;
    if (idTrabajador != null && idTrabajador.isNotEmpty) {
      query = query.where('idTrabajador', isEqualTo: idTrabajador);
    }

    return query
        .orderBy('fechaAsistencia', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_asistenciaFromDoc).toList());
  }

  @override
  Stream<List<ConsumoPersonal>> watchConsumosPersonal({String? idTrabajador}) {
    if (idTrabajador != null && idTrabajador.startsWith('__sin_')) {
      return Stream.value(const []);
    }
    Query<Map<String, dynamic>> query = _consumosPersonal;
    if (idTrabajador != null && idTrabajador.isNotEmpty) {
      query = query.where('idTrabajador', isEqualTo: idTrabajador);
    }

    return query
        .orderBy('fechaConsumoPersonal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_consumoPersonalFromDoc).toList());
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

  @override
  Future<void> guardarTrabajador(Trabajador trabajador) {
    final doc = trabajador.idTrabajador.isEmpty
        ? _trabajadores.doc()
        : _trabajadores.doc(trabajador.idTrabajador);

    return doc.set(_trabajadorToMap(trabajador.copyWith(idTrabajador: doc.id)));
  }

  @override
  Future<void> guardarAsistencia(Asistencia asistencia) {
    final doc = asistencia.idAsistencia.isEmpty
        ? _asistencias.doc()
        : _asistencias.doc(asistencia.idAsistencia);

    return doc.set(_asistenciaToMap(asistencia.copyWith(idAsistencia: doc.id)));
  }

  @override
  Future<void> guardarConsumoPersonal(ConsumoPersonal consumoPersonal) {
    final doc = consumoPersonal.idConsumoPersonal.isEmpty
        ? _consumosPersonal.doc()
        : _consumosPersonal.doc(consumoPersonal.idConsumoPersonal);

    return doc.set(
      _consumoPersonalToMap(
        consumoPersonal.copyWith(idConsumoPersonal: doc.id),
      ),
    );
  }

  @override
  Future<void> registrarAuditoria(Map<String, dynamic> auditoria) {
    return _auditoria.add({
      ...auditoria,
      'fechaAuditoria': FieldValue.serverTimestamp(),
    });
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

Trabajador _trabajadorFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  return Trabajador(
    idTrabajador: data['idTrabajador'] as String? ?? doc.id,
    nombreTrabajador: data['nombreTrabajador'] as String? ?? '',
    emailTrabajador: data['emailTrabajador'] as String? ?? '',
    telefonoTrabajador: data['telefonoTrabajador'] as String? ?? '',
    cargoTrabajador: data['cargoTrabajador'] as String? ?? '',
    estaActivoTrabajador: data['estaActivoTrabajador'] as bool? ?? true,
    idPerfil: data['idPerfil'] as String? ?? '',
  );
}

Map<String, dynamic> _trabajadorToMap(Trabajador trabajador) {
  return {
    'idTrabajador': trabajador.idTrabajador,
    'nombreTrabajador': trabajador.nombreTrabajador,
    'emailTrabajador': trabajador.emailTrabajador,
    'telefonoTrabajador': trabajador.telefonoTrabajador,
    'cargoTrabajador': trabajador.cargoTrabajador,
    'estaActivoTrabajador': trabajador.estaActivoTrabajador,
    'idPerfil': trabajador.idPerfil,
  };
}

Asistencia _asistenciaFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? {};
  final horaEntrada =
      (data['horaEntrada'] as Timestamp?)?.toDate() ?? DateTime.now();
  return Asistencia(
    idAsistencia: data['idAsistencia'] as String? ?? doc.id,
    idTrabajador: data['idTrabajador'] as String? ?? '',
    fechaAsistencia:
        (data['fechaAsistencia'] as Timestamp?)?.toDate() ?? horaEntrada,
    horaEntrada: horaEntrada,
    horaSalida: (data['horaSalida'] as Timestamp?)?.toDate(),
    minutosTrabajados: data['minutosTrabajados'] as int? ?? 0,
    minutosExtra: data['minutosExtra'] as int? ?? 0,
    minutosAtraso: data['minutosAtraso'] as int? ?? 0,
    observacionAsistencia: data['observacionAsistencia'] as String? ?? '',
    estaCorregidaAsistencia: data['estaCorregidaAsistencia'] as bool? ?? false,
    estaAnuladaAsistencia: data['estaAnuladaAsistencia'] as bool? ?? false,
  );
}

Map<String, dynamic> _asistenciaToMap(Asistencia asistencia) {
  return {
    'idAsistencia': asistencia.idAsistencia,
    'idTrabajador': asistencia.idTrabajador,
    'fechaAsistencia': Timestamp.fromDate(asistencia.fechaAsistencia),
    'horaEntrada': Timestamp.fromDate(asistencia.horaEntrada),
    'horaSalida': asistencia.horaSalida == null
        ? null
        : Timestamp.fromDate(asistencia.horaSalida!),
    'minutosTrabajados': asistencia.minutosTrabajados,
    'minutosExtra': asistencia.minutosExtra,
    'minutosAtraso': asistencia.minutosAtraso,
    'observacionAsistencia': asistencia.observacionAsistencia,
    'estaCorregidaAsistencia': asistencia.estaCorregidaAsistencia,
    'estaAnuladaAsistencia': asistencia.estaAnuladaAsistencia,
  };
}

ConsumoPersonal _consumoPersonalFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? {};
  return ConsumoPersonal(
    idConsumoPersonal: data['idConsumoPersonal'] as String? ?? doc.id,
    idTrabajador: data['idTrabajador'] as String? ?? '',
    idProducto: data['idProducto'] as String? ?? '',
    nombreProductoSnapshot: data['nombreProductoSnapshot'] as String? ?? '',
    montoConsumoPersonal: data['montoConsumoPersonal'] as int? ?? 0,
    fechaConsumoPersonal:
        (data['fechaConsumoPersonal'] as Timestamp?)?.toDate() ??
        DateTime.now(),
    notaConsumoPersonal: data['notaConsumoPersonal'] as String? ?? '',
    estaAnuladoConsumoPersonal:
        data['estaAnuladoConsumoPersonal'] as bool? ?? false,
  );
}

Map<String, dynamic> _consumoPersonalToMap(ConsumoPersonal consumoPersonal) {
  return {
    'idConsumoPersonal': consumoPersonal.idConsumoPersonal,
    'idTrabajador': consumoPersonal.idTrabajador,
    'idProducto': consumoPersonal.idProducto,
    'nombreProductoSnapshot': consumoPersonal.nombreProductoSnapshot,
    'montoConsumoPersonal': consumoPersonal.montoConsumoPersonal,
    'fechaConsumoPersonal': Timestamp.fromDate(
      consumoPersonal.fechaConsumoPersonal,
    ),
    'notaConsumoPersonal': consumoPersonal.notaConsumoPersonal,
    'estaAnuladoConsumoPersonal': consumoPersonal.estaAnuladoConsumoPersonal,
  };
}
