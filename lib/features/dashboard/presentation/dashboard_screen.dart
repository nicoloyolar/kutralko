import 'dart:async';

import 'package:excel/excel.dart' as xlsx;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/theme.dart';
import '../../../core/data/kutral_ko_repository.dart';
import '../../../core/export/file_downloader.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../consumos/domain/consumo.dart';
import '../../pagos/domain/pago.dart';
import '../../personal/domain/asistencia.dart';
import '../../personal/domain/consumo_personal.dart';
import '../../personal/domain/trabajador.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    this.watchRemoteProfile = true,
  });

  final KutralKoRepository repository;
  final bool watchRemoteProfile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Usuario> _usuarios = [];
  final List<Producto> _productos = [];
  final List<Consumo> _consumos = [];
  final List<Pago> _pagos = [];
  final List<Trabajador> _trabajadores = [];
  final List<Asistencia> _asistencias = [];
  final List<ConsumoPersonal> _consumosPersonal = [];
  final List<StreamSubscription<dynamic>> _dataSubscriptions = [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _perfilSubscription;

  int _selectedIndex = 0;
  bool _isPerfilLoading = true;
  String _rolPerfil = 'cliente';
  String _emailPerfil = '';
  String? _idUsuarioPerfil;
  String? _idTrabajadorPerfil;
  late DateTime _mesSeleccionado;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSeleccionado = DateTime(now.year, now.month);
    if (widget.watchRemoteProfile) {
      _watchPerfil();
    } else {
      _isPerfilLoading = false;
      _rolPerfil = 'administrador';
      _restartDataStreams(idUsuario: null, idTrabajador: null);
    }
  }

  void _watchPerfil() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isPerfilLoading = false;
      return;
    }

    _perfilSubscription = FirebaseFirestore.instance
        .collection('perfiles')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data() ?? {};
            final rolPerfil = data['rolPerfil'] as String? ?? 'cliente';
            final idUsuarioPerfil = data['idUsuarioPerfil'] as String?;
            final idTrabajadorPerfil = data['idTrabajadorPerfil'] as String?;
            setState(() {
              _rolPerfil = rolPerfil;
              _emailPerfil = data['emailPerfil'] as String? ?? user.email ?? '';
              _idUsuarioPerfil = idUsuarioPerfil;
              _idTrabajadorPerfil = idTrabajadorPerfil;
              _isPerfilLoading = false;
            });
            _restartDataStreams(
              idUsuario: rolPerfil == 'administrador'
                  ? null
                  : rolPerfil == 'cliente'
                  ? idUsuarioPerfil
                  : '__sin_cliente__',
              idTrabajador: rolPerfil == 'administrador'
                  ? null
                  : rolPerfil == 'trabajador'
                  ? idTrabajadorPerfil
                  : '__sin_trabajador__',
            );
          },
          onError: (error) {
            setState(() => _isPerfilLoading = false);
            _handleStreamError(error);
          },
        );
  }

  @override
  void dispose() {
    _perfilSubscription?.cancel();
    for (final subscription in _dataSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _restartDataStreams({required String? idUsuario, String? idTrabajador}) {
    for (final subscription in _dataSubscriptions) {
      subscription.cancel();
    }
    _dataSubscriptions.clear();

    setState(() {
      _usuarios.clear();
      _productos.clear();
      _consumos.clear();
      _pagos.clear();
      _trabajadores.clear();
      _asistencias.clear();
      _consumosPersonal.clear();
    });

    if (_rolPerfil == 'cliente' && (idUsuario == null || idUsuario.isEmpty)) {
      _dataSubscriptions.add(
        widget.repository.watchProductos().listen((productos) {
          setState(() {
            _productos
              ..clear()
              ..addAll(productos);
          });
        }, onError: _handleStreamError),
      );
      return;
    }

    _dataSubscriptions
      ..add(
        widget.repository.watchUsuarios(idUsuario: idUsuario).listen((
          usuarios,
        ) {
          setState(() {
            _usuarios
              ..clear()
              ..addAll(usuarios);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchProductos().listen((productos) {
          setState(() {
            _productos
              ..clear()
              ..addAll(productos);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchConsumos(idUsuario: idUsuario).listen((
          consumos,
        ) {
          setState(() {
            _consumos
              ..clear()
              ..addAll(consumos);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchPagos(idUsuario: idUsuario).listen((pagos) {
          setState(() {
            _pagos
              ..clear()
              ..addAll(pagos);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchTrabajadores(idTrabajador: idTrabajador).listen((
          trabajadores,
        ) {
          setState(() {
            _trabajadores
              ..clear()
              ..addAll(trabajadores);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchAsistencias(idTrabajador: idTrabajador).listen((
          asistencias,
        ) {
          setState(() {
            _asistencias
              ..clear()
              ..addAll(asistencias);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository
            .watchConsumosPersonal(idTrabajador: idTrabajador)
            .listen((consumosPersonal) {
              setState(() {
                _consumosPersonal
                  ..clear()
                  ..addAll(consumosPersonal);
              });
            }, onError: _handleStreamError),
      );
  }

  int get _totalConsumido {
    return _usuariosPermitidos.fold(0, (total, usuario) {
      return total + _totalConsumidoUsuario(usuario.idUsuario);
    });
  }

  int get _totalPagado {
    return _usuariosPermitidos.fold(0, (total, usuario) {
      return total + _totalPagadoUsuario(usuario.idUsuario);
    });
  }

  int get _saldoPendiente => _totalConsumido - _totalPagado;

  List<Consumo> get _consumosMes {
    return _consumos
        .where((consumo) => _isInSelectedMonth(consumo.fechaConsumo))
        .toList();
  }

  List<Pago> get _pagosMes {
    return _pagos.where((pago) => _isInSelectedMonth(pago.fechaPago)).toList();
  }

  List<Usuario> get _usuariosPermitidos {
    if (_puedeAdministrar) {
      return _usuarios;
    }

    final idUsuario = _idUsuarioPerfil;
    if (idUsuario == null || idUsuario.isEmpty) {
      return const [];
    }

    return _usuarios
        .where((usuario) => usuario.idUsuario == idUsuario)
        .toList();
  }

  List<Consumo> get _consumosMesPermitidos {
    if (_puedeAdministrar) {
      return _consumosMes;
    }

    final idUsuario = _idUsuarioPerfil;
    if (idUsuario == null || idUsuario.isEmpty) {
      return const [];
    }

    return _consumosMes
        .where((consumo) => consumo.idUsuario == idUsuario)
        .toList();
  }

  List<Pago> get _pagosMesPermitidos {
    if (_puedeAdministrar) {
      return _pagosMes;
    }

    final idUsuario = _idUsuarioPerfil;
    if (idUsuario == null || idUsuario.isEmpty) {
      return const [];
    }

    return _pagosMes.where((pago) => pago.idUsuario == idUsuario).toList();
  }

  List<Asistencia> get _asistenciasMes {
    return _asistencias
        .where((asistencia) => _isInSelectedMonth(asistencia.fechaAsistencia))
        .toList();
  }

  List<ConsumoPersonal> get _consumosPersonalMes {
    return _consumosPersonal
        .where((consumo) => _isInSelectedMonth(consumo.fechaConsumoPersonal))
        .toList();
  }

  List<Trabajador> get _trabajadoresActivos {
    return _trabajadores
        .where((trabajador) => trabajador.estaActivoTrabajador)
        .toList();
  }

  Trabajador? get _trabajadorPerfil {
    final idTrabajador = _idTrabajadorPerfil;
    if (idTrabajador == null || idTrabajador.isEmpty) {
      return null;
    }

    for (final trabajador in _trabajadores) {
      if (trabajador.idTrabajador == idTrabajador) {
        return trabajador;
      }
    }
    return null;
  }

  bool get _esTrabajador {
    return _rolPerfil == 'trabajador';
  }

  List<Usuario> get _usuariosActivos {
    return _usuarios.where((usuario) => usuario.estaActivoUsuario).toList();
  }

  List<Producto> get _productosActivos {
    return _productos.where((producto) => producto.estaActivoProducto).toList();
  }

  int _totalConsumidoUsuario(String idUsuario) {
    return _consumosMes
        .where(
          (consumo) =>
              consumo.idUsuario == idUsuario && !consumo.estaAnuladoConsumo,
        )
        .fold(0, (total, consumo) => total + consumo.totalConsumo);
  }

  int _totalPagadoUsuario(String idUsuario) {
    return _pagosMes
        .where((pago) => pago.idUsuario == idUsuario && !pago.estaAnuladoPago)
        .fold(0, (total, pago) => total + pago.montoPago);
  }

  int _saldoUsuario(String idUsuario) {
    return _totalConsumidoUsuario(idUsuario) - _totalPagadoUsuario(idUsuario);
  }

  bool get _puedeAdministrar {
    return _rolPerfil == 'administrador';
  }

  bool _isInSelectedMonth(DateTime date) {
    return date.year == _mesSeleccionado.year &&
        date.month == _mesSeleccionado.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month + delta,
      );
    });
  }

  Future<void> _openUsuarioForm([Usuario? usuario]) async {
    final result = await showModalBottomSheet<Usuario>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _UsuarioFormSheet(usuario: usuario),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarUsuario(result));
  }

  Future<void> _openProductoForm([Producto? producto]) async {
    final result = await showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ProductoFormSheet(producto: producto),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarProducto(result));
  }

  Future<void> _openConsumoForm([Usuario? usuarioInicial]) async {
    if (_usuariosActivos.isEmpty || _productosActivos.isEmpty) {
      _showSnack('Necesitas al menos un cliente y un producto activos.');
      return;
    }

    final result = await showModalBottomSheet<List<Consumo>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConsumoFormSheet(
        usuarios: _usuariosActivos,
        productos: _productosActivos,
        usuarioInicial: usuarioInicial,
      ),
    );

    if (result == null) {
      return;
    }

    await _save(() async {
      for (final consumo in result) {
        await widget.repository.guardarConsumo(consumo);
      }
    });
  }

  Future<void> _openPagoForm([Usuario? usuarioInicial]) async {
    if (_usuariosActivos.isEmpty) {
      _showSnack('Necesitas al menos un cliente activo.');
      return;
    }

    final result = await showModalBottomSheet<Pago>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PagoFormSheet(
        usuarios: _usuariosActivos,
        usuarioInicial: usuarioInicial,
      ),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarPago(result));
  }

  Future<void> _openTrabajadorForm([Trabajador? trabajador]) async {
    final result = await showModalBottomSheet<Trabajador>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TrabajadorFormSheet(trabajador: trabajador),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarTrabajador(result));
  }

  Future<void> _openConsumoPersonalForm() async {
    if (_trabajadoresActivos.isEmpty || _productosActivos.isEmpty) {
      _showSnack('Necesitas trabajadores y productos activos.');
      return;
    }

    final result = await showModalBottomSheet<ConsumoPersonal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConsumoPersonalFormSheet(
        trabajadores: _trabajadoresActivos,
        productos: _productosActivos,
      ),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarConsumoPersonal(result));
  }

  Future<void> _editarAsistencia(Asistencia asistencia) async {
    final result = await showModalBottomSheet<Asistencia>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AsistenciaEditFormSheet(asistencia: asistencia),
    );

    if (result == null) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarAsistencia(result);
      await _registrarAuditoriaPersonal(
        accion: 'corregir',
        tipoMovimiento: 'asistencia',
        idMovimiento: result.idAsistencia,
        idTrabajadorMovimiento: result.idTrabajador,
      );
    });
  }

  Future<void> _anularConsumoPersonal(ConsumoPersonal consumo) async {
    final confirmed = await _confirmAnulacion(
      title: 'Anular consumo personal',
      message:
          'Este consumo seguira visible en el historial, pero dejara de afectar el descuento estimado.',
    );

    if (!confirmed) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarConsumoPersonal(
        consumo.copyWith(estaAnuladoConsumoPersonal: true),
      );
      await _registrarAuditoriaPersonal(
        accion: 'anular',
        tipoMovimiento: 'consumoPersonal',
        idMovimiento: consumo.idConsumoPersonal,
        idTrabajadorMovimiento: consumo.idTrabajador,
      );
    });
  }

  Future<void> _iniciarTurno() async {
    final trabajador = _trabajadorPerfil;
    if (trabajador == null) {
      _showSnack('Tu perfil aun no esta vinculado a un trabajador.');
      return;
    }

    if (_asistenciaAbierta(trabajador.idTrabajador) != null) {
      _showSnack('Ya tienes un turno en curso.');
      return;
    }

    final now = DateTime.now();
    await _save(
      () => widget.repository.guardarAsistencia(
        Asistencia(
          idAsistencia: '',
          idTrabajador: trabajador.idTrabajador,
          fechaAsistencia: DateTime(now.year, now.month, now.day),
          horaEntrada: now,
          horaSalida: null,
          minutosTrabajados: 0,
          minutosExtra: 0,
          minutosAtraso: 0,
          observacionAsistencia: '',
          estaCorregidaAsistencia: false,
          estaAnuladaAsistencia: false,
        ),
      ),
    );
  }

  Future<void> _finalizarTurno() async {
    final trabajador = _trabajadorPerfil;
    if (trabajador == null) {
      _showSnack('Tu perfil aun no esta vinculado a un trabajador.');
      return;
    }

    final asistencia = _asistenciaAbierta(trabajador.idTrabajador);
    if (asistencia == null) {
      _showSnack('No tienes un turno en curso.');
      return;
    }

    final now = DateTime.now();
    final minutos = now.difference(asistencia.horaEntrada).inMinutes;
    await _save(
      () => widget.repository.guardarAsistencia(
        asistencia.copyWith(
          horaSalida: now,
          minutosTrabajados: minutos < 0 ? 0 : minutos,
        ),
      ),
    );
  }

  Asistencia? _asistenciaAbierta(String idTrabajador) {
    for (final asistencia in _asistencias) {
      if (asistencia.idTrabajador == idTrabajador && asistencia.estaAbierta) {
        return asistencia;
      }
    }
    return null;
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _showSnack('No se pudo guardar en Firebase: $error');
    }
  }

  void _handleStreamError(Object error) {
    if (!mounted) {
      return;
    }
    _showSnack('No se pudo leer Firebase: $error');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleUsuario(Usuario usuario) async {
    await _save(
      () => widget.repository.guardarUsuario(
        usuario.copyWith(estaActivoUsuario: !usuario.estaActivoUsuario),
      ),
    );
  }

  Future<void> _toggleProducto(Producto producto) async {
    await _save(
      () => widget.repository.guardarProducto(
        producto.copyWith(estaActivoProducto: !producto.estaActivoProducto),
      ),
    );
  }

  Future<void> _anularConsumo(Consumo consumo) async {
    final confirmed = await _confirmAnulacion(
      title: 'Anular consumo',
      message:
          'Este consumo seguira visible en el historial, pero dejara de afectar el saldo.',
    );

    if (!confirmed) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarConsumo(
        consumo.copyWith(estaAnuladoConsumo: true),
      );
      await _registrarAuditoria(
        accion: 'anular',
        tipoMovimiento: 'consumo',
        idMovimiento: consumo.idConsumo,
        idUsuarioMovimiento: consumo.idUsuario,
      );
    });
  }

  Future<void> _editarConsumo(Consumo consumo) async {
    final result = await showModalBottomSheet<Consumo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConsumoEditFormSheet(
        consumo: consumo,
        usuarios: _usuarios,
        productos: _productos,
      ),
    );

    if (result == null) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarConsumo(result);
      await _registrarAuditoria(
        accion: 'editar',
        tipoMovimiento: 'consumo',
        idMovimiento: result.idConsumo,
        idUsuarioMovimiento: result.idUsuario,
      );
    });
  }

  Future<void> _editarPago(Pago pago) async {
    final result = await showModalBottomSheet<Pago>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PagoEditFormSheet(pago: pago, usuarios: _usuarios),
    );

    if (result == null) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarPago(result);
      await _registrarAuditoria(
        accion: 'editar',
        tipoMovimiento: 'pago',
        idMovimiento: result.idPago,
        idUsuarioMovimiento: result.idUsuario,
      );
    });
  }

  Future<void> _anularPago(Pago pago) async {
    final confirmed = await _confirmAnulacion(
      title: 'Anular pago',
      message:
          'Este pago seguira visible en el historial, pero dejara de descontar saldo.',
    );

    if (!confirmed) {
      return;
    }

    await _save(() async {
      await widget.repository.guardarPago(pago.copyWith(estaAnuladoPago: true));
      await _registrarAuditoria(
        accion: 'anular',
        tipoMovimiento: 'pago',
        idMovimiento: pago.idPago,
        idUsuarioMovimiento: pago.idUsuario,
      );
    });
  }

  Future<void> _registrarAuditoria({
    required String accion,
    required String tipoMovimiento,
    required String idMovimiento,
    required String idUsuarioMovimiento,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    return widget.repository.registrarAuditoria({
      'accionAuditoria': accion,
      'tipoMovimientoAuditoria': tipoMovimiento,
      'idMovimientoAuditoria': idMovimiento,
      'idUsuarioMovimientoAuditoria': idUsuarioMovimiento,
      'idPerfilAuditoria': user?.uid ?? '',
      'emailPerfilAuditoria': user?.email ?? _emailPerfil,
    });
  }

  Future<void> _registrarAuditoriaPersonal({
    required String accion,
    required String tipoMovimiento,
    required String idMovimiento,
    required String idTrabajadorMovimiento,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    return widget.repository.registrarAuditoria({
      'accionAuditoria': accion,
      'tipoMovimientoAuditoria': tipoMovimiento,
      'idMovimientoAuditoria': idMovimiento,
      'idTrabajadorMovimientoAuditoria': idTrabajadorMovimiento,
      'idPerfilAuditoria': user?.uid ?? '',
      'emailPerfilAuditoria': user?.email ?? _emailPerfil,
    });
  }

  Future<void> _openConfiguracion() async {
    if (!_puedeAdministrar) {
      _showSnack('Solo administradores pueden abrir configuracion.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _PerfilLinkSheet(usuarios: _usuarios, trabajadores: _trabajadores),
    );
  }

  Future<bool> _confirmAnulacion({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _openUsuarioDetail(Usuario usuario) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _UsuarioDetailSheet(
        usuario: usuario,
        consumos: _consumosMesPermitidos,
        pagos: _pagosMesPermitidos,
        totalConsumido: _totalConsumidoUsuario(usuario.idUsuario),
        totalPagado: _totalPagadoUsuario(usuario.idUsuario),
        saldo: _saldoUsuario(usuario.idUsuario),
        puedeAdministrar: _puedeAdministrar,
        onNuevoConsumo: _puedeAdministrar
            ? () {
                Navigator.of(sheetContext).pop();
                _openConsumoForm(usuario);
              }
            : null,
        onNuevoPago: _puedeAdministrar
            ? () {
                Navigator.of(sheetContext).pop();
                _openPagoForm(usuario);
              }
            : null,
        onAnularConsumo: _puedeAdministrar
            ? (consumo) {
                _anularConsumo(consumo);
              }
            : null,
        onAnularPago: _puedeAdministrar
            ? (pago) {
                _anularPago(pago);
              }
            : null,
        onEditarConsumo: _puedeAdministrar
            ? (consumo) {
                _editarConsumo(consumo);
              }
            : null,
        onEditarPago: _puedeAdministrar
            ? (pago) {
                _editarPago(pago);
              }
            : null,
      ),
    );
  }

  Future<void> _openTrabajadorDetail(Trabajador trabajador) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _TrabajadorDetailSheet(
        trabajador: trabajador,
        asistencias: _asistenciasMes
            .where(
              (asistencia) =>
                  asistencia.idTrabajador == trabajador.idTrabajador,
            )
            .toList(),
        consumosPersonal: _consumosPersonalMes
            .where((consumo) => consumo.idTrabajador == trabajador.idTrabajador)
            .toList(),
        asistenciaAbierta: _asistenciaAbierta(trabajador.idTrabajador),
        onEditarTrabajador: () {
          Navigator.of(sheetContext).pop();
          _openTrabajadorForm(trabajador);
        },
        onEditarAsistencia: _editarAsistencia,
        onAnularConsumoPersonal: _anularConsumoPersonal,
      ),
    );
  }

  List<_PersonalReportRow> _buildPersonalReportRows() {
    return _trabajadoresActivos.map((trabajador) {
      final asistencias = _asistenciasMes
          .where(
            (asistencia) =>
                asistencia.idTrabajador == trabajador.idTrabajador &&
                !asistencia.estaAnuladaAsistencia,
          )
          .toList();
      final consumos = _consumosPersonalMes
          .where(
            (consumo) =>
                consumo.idTrabajador == trabajador.idTrabajador &&
                !consumo.estaAnuladoConsumoPersonal,
          )
          .toList();
      final minutosTrabajados = asistencias.fold(
        0,
        (total, asistencia) => total + asistencia.minutosTrabajados,
      );
      final minutosExtra = asistencias.fold(
        0,
        (total, asistencia) => total + asistencia.minutosExtra,
      );
      final atrasos = asistencias
          .where((asistencia) => asistencia.minutosAtraso > 0)
          .length;
      final consumoTotal = consumos.fold(
        0,
        (total, consumo) => total + consumo.montoConsumoPersonal,
      );
      final enTurno = _asistenciaAbierta(trabajador.idTrabajador) != null;

      return _PersonalReportRow(
        trabajador: trabajador,
        minutosTrabajados: minutosTrabajados,
        minutosExtra: minutosExtra,
        atrasos: atrasos,
        consumoTotal: consumoTotal,
        enTurno: enTurno,
      );
    }).toList();
  }

  Future<void> _exportPersonalPdf() async {
    final rows = _buildPersonalReportRows();
    final mesLabel = _monthLabel(_mesSeleccionado);
    final totalMinutos = rows.fold(
      0,
      (total, row) => total + row.minutosTrabajados,
    );
    final totalConsumos = rows.fold(
      0,
      (total, row) => total + row.consumoTotal,
    );
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Kutral Ko - Reporte mensual de personal',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Periodo: $mesLabel'),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Horas totales: ${_formatMinutes(totalMinutos)}'),
              pw.Text('Descuentos: ${CurrencyFormatter.clp(totalConsumos)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Trabajador',
              'Cargo',
              'Horas',
              'Extras',
              'Atrasos',
              'Consumo',
              'Estado',
            ],
            data: [
              for (final row in rows)
                [
                  row.trabajador.nombreTrabajador,
                  row.trabajador.cargoTrabajador,
                  _formatMinutes(row.minutosTrabajados),
                  _formatMinutes(row.minutosExtra),
                  row.atrasos.toString(),
                  CurrencyFormatter.clp(row.consumoTotal),
                  row.enTurno ? 'En turno' : 'Fuera',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE9DDC7),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await _downloadReport(
      bytes: await document.save(),
      fileName: 'reporte_personal_${_reportMonthSlug()}.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<void> _exportPersonalExcel() async {
    final rows = _buildPersonalReportRows();
    final excel = xlsx.Excel.createExcel();
    const sheetName = 'Reporte personal';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    void writeText(int row, int column, String value) {
      sheet
          .cell(
            xlsx.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
          )
          .value = xlsx.TextCellValue(
        value,
      );
    }

    void writeInt(int row, int column, int value) {
      sheet
          .cell(
            xlsx.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
          )
          .value = xlsx.IntCellValue(
        value,
      );
    }

    writeText(0, 0, 'Kutral Ko - Reporte mensual de personal');
    writeText(1, 0, 'Periodo');
    writeText(1, 1, _monthLabel(_mesSeleccionado));

    const headers = [
      'Trabajador',
      'Correo',
      'Cargo',
      'Horas trabajadas',
      'Minutos trabajados',
      'Horas extra',
      'Minutos extra',
      'Atrasos',
      'Consumo / descuento',
      'Estado',
    ];

    for (var index = 0; index < headers.length; index++) {
      writeText(3, index, headers[index]);
    }

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final excelRow = index + 4;
      writeText(excelRow, 0, row.trabajador.nombreTrabajador);
      writeText(excelRow, 1, row.trabajador.emailTrabajador);
      writeText(excelRow, 2, row.trabajador.cargoTrabajador);
      writeText(excelRow, 3, _formatMinutes(row.minutosTrabajados));
      writeInt(excelRow, 4, row.minutosTrabajados);
      writeText(excelRow, 5, _formatMinutes(row.minutosExtra));
      writeInt(excelRow, 6, row.minutosExtra);
      writeInt(excelRow, 7, row.atrasos);
      writeInt(excelRow, 8, row.consumoTotal);
      writeText(excelRow, 9, row.enTurno ? 'En turno' : 'Fuera');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      _showSnack('No se pudo generar el Excel.');
      return;
    }

    await _downloadReport(
      bytes: bytes,
      fileName: 'reporte_personal_${_reportMonthSlug()}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _downloadReport({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      await downloadBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
    } on UnsupportedError catch (error) {
      _showSnack(error.message ?? 'Descarga disponible desde panel web.');
    } on Object catch (error) {
      _showSnack('No se pudo descargar el reporte: $error');
    }
  }

  String _reportMonthSlug() {
    return '${_mesSeleccionado.year}_${_mesSeleccionado.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const destinations = [
      _DashboardDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Inicio',
      ),
      _DashboardDestination(
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt_rounded,
        label: 'Clientes',
      ),
      _DashboardDestination(
        icon: Icons.local_dining_outlined,
        selectedIcon: Icons.local_dining_rounded,
        label: 'Carta',
      ),
      _DashboardDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Cuenta',
      ),
      _DashboardDestination(
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge_rounded,
        label: 'Personal',
      ),
    ];
    final pages = [
      _HomeView(
        usuarios: _usuariosPermitidos,
        saldoPendiente: _saldoPendiente,
        totalConsumido: _totalConsumido,
        totalPagado: _totalPagado,
        saldoUsuario: _saldoUsuario,
        mesLabel: _monthLabel(_mesSeleccionado),
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onOpenUsuario: _openUsuarioDetail,
        onNuevoConsumo: _puedeAdministrar ? _openConsumoForm : null,
        onNuevoPago: _puedeAdministrar ? _openPagoForm : null,
      ),
      _UsuariosView(
        usuarios: _usuariosPermitidos,
        saldoUsuario: _saldoUsuario,
        puedeAdministrar: _puedeAdministrar,
        onNuevoUsuario: _puedeAdministrar ? () => _openUsuarioForm() : null,
        onOpenUsuario: _openUsuarioDetail,
        onEditarUsuario: _puedeAdministrar ? _openUsuarioForm : null,
        onToggleUsuario: _puedeAdministrar ? _toggleUsuario : null,
      ),
      _ProductosView(
        productos: _productos,
        puedeAdministrar: _puedeAdministrar,
        onNuevoProducto: _puedeAdministrar ? () => _openProductoForm() : null,
        onEditarProducto: _puedeAdministrar ? _openProductoForm : null,
        onToggleProducto: _puedeAdministrar ? _toggleProducto : null,
      ),
      _MovimientosView(
        usuarios: _usuariosPermitidos,
        consumos: _consumosMesPermitidos,
        pagos: _pagosMesPermitidos,
        puedeAdministrar: _puedeAdministrar,
        onNuevoConsumo: _puedeAdministrar ? _openConsumoForm : null,
        onNuevoPago: _puedeAdministrar ? _openPagoForm : null,
        onAnularConsumo: _puedeAdministrar
            ? (consumo) {
                _anularConsumo(consumo);
              }
            : null,
        onAnularPago: _puedeAdministrar
            ? (pago) {
                _anularPago(pago);
              }
            : null,
        onEditarConsumo: _puedeAdministrar
            ? (consumo) {
                _editarConsumo(consumo);
              }
            : null,
        onEditarPago: _puedeAdministrar
            ? (pago) {
                _editarPago(pago);
              }
            : null,
      ),
      _PersonalView(
        trabajadores: _trabajadoresActivos,
        asistencias: _asistenciasMes,
        consumosPersonal: _consumosPersonalMes,
        trabajadorPerfil: _trabajadorPerfil,
        puedeAdministrar: _puedeAdministrar,
        esTrabajador: _esTrabajador,
        mesLabel: _monthLabel(_mesSeleccionado),
        asistenciaAbierta: _trabajadorPerfil == null
            ? null
            : _asistenciaAbierta(_trabajadorPerfil!.idTrabajador),
        onNuevoTrabajador: _puedeAdministrar
            ? () => _openTrabajadorForm()
            : null,
        onRegistrarConsumo: _puedeAdministrar ? _openConsumoPersonalForm : null,
        onOpenTrabajador: _puedeAdministrar ? _openTrabajadorDetail : null,
        onExportPdf: _puedeAdministrar ? _exportPersonalPdf : null,
        onExportExcel: _puedeAdministrar ? _exportPersonalExcel : null,
        onIniciarTurno: _esTrabajador ? _iniciarTurno : null,
        onFinalizarTurno: _esTrabajador ? _finalizarTurno : null,
      ),
    ];
    final isWidePanel = MediaQuery.sizeOf(context).width >= 920;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/brand/kutral_ko_login_circle.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kutral Ko',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Panel de administración',
                  style: TextStyle(
                    color: KutralKoColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configuracion',
            onPressed: _puedeAdministrar ? _openConfiguracion : null,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isWidePanel
            ? _WebPanelShell(
                destinations: destinations,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                rolPerfil: _rolPerfil,
                emailPerfil: _emailPerfil,
                isLoading: _isPerfilLoading,
                idUsuarioPerfil: _idUsuarioPerfil,
                idTrabajadorPerfil: _idTrabajadorPerfil,
                child: pages[_selectedIndex],
              )
            : Column(
                children: [
                  _PerfilBanner(
                    isLoading: _isPerfilLoading,
                    rolPerfil: _rolPerfil,
                    emailPerfil: _emailPerfil,
                    idUsuarioPerfil: _idUsuarioPerfil,
                    idTrabajadorPerfil: _idTrabajadorPerfil,
                  ),
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
      ),
      bottomNavigationBar: isWidePanel
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }
}

class _DashboardDestination {
  const _DashboardDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _PersonalReportRow {
  const _PersonalReportRow({
    required this.trabajador,
    required this.minutosTrabajados,
    required this.minutosExtra,
    required this.atrasos,
    required this.consumoTotal,
    required this.enTurno,
  });

  final Trabajador trabajador;
  final int minutosTrabajados;
  final int minutosExtra;
  final int atrasos;
  final int consumoTotal;
  final bool enTurno;
}

class _WebPanelShell extends StatelessWidget {
  const _WebPanelShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.rolPerfil,
    required this.emailPerfil,
    required this.isLoading,
    required this.idUsuarioPerfil,
    required this.idTrabajadorPerfil,
    required this.child,
  });

  final List<_DashboardDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String rolPerfil;
  final String emailPerfil;
  final bool isLoading;
  final String? idUsuarioPerfil;
  final String? idTrabajadorPerfil;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isAdmin = rolPerfil == 'administrador';

    return Row(
      children: [
        Container(
          width: 284,
          color: KutralKoColors.carbon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _WebRoleCard(
                  isLoading: isLoading,
                  isAdmin: isAdmin,
                  emailPerfil: emailPerfil,
                  idUsuarioPerfil: idUsuarioPerfil,
                  idTrabajadorPerfil: idTrabajadorPerfil,
                ),
              ),
              Expanded(
                child: NavigationRail(
                  extended: true,
                  backgroundColor: KutralKoColors.carbon,
                  indicatorColor: KutralKoColors.gold.withValues(alpha: 0.18),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  selectedIconTheme: const IconThemeData(
                    color: KutralKoColors.gold,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: KutralKoColors.smoke,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: KutralKoColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: KutralKoColors.smoke,
                    fontWeight: FontWeight.w700,
                  ),
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(
                          _panelLabel(destination.label, isAdmin: isAdmin),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Text(
                  isAdmin
                      ? 'Responsabilidad: administrar clientes, carta, cargas, pagos y permisos.'
                      : 'Responsabilidad: revisar tu cuenta, consumos, pagos y saldo asociado.',
                  style: TextStyle(
                    color: KutralKoColors.smoke.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                children: [
                  _PerfilBanner(
                    isLoading: isLoading,
                    rolPerfil: rolPerfil,
                    emailPerfil: emailPerfil,
                    idUsuarioPerfil: idUsuarioPerfil,
                    idTrabajadorPerfil: idTrabajadorPerfil,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _panelLabel(String label, {required bool isAdmin}) {
    if (isAdmin) {
      return label;
    }

    return switch (label) {
      'Clientes' => 'Mi cuenta',
      'Cuenta' => 'Mi historial',
      _ => label,
    };
  }
}

class _WebRoleCard extends StatelessWidget {
  const _WebRoleCard({
    required this.isLoading,
    required this.isAdmin,
    required this.emailPerfil,
    required this.idUsuarioPerfil,
    required this.idTrabajadorPerfil,
  });

  final bool isLoading;
  final bool isAdmin;
  final String emailPerfil;
  final String? idUsuarioPerfil;
  final String? idTrabajadorPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: KutralKoColors.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Verificando'
                      : isAdmin
                      ? 'Panel administrador'
                      : 'Panel operativo',
                  style: const TextStyle(
                    color: KutralKoColors.ivory,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            emailPerfil.isEmpty ? 'Sesion activa' : emailPerfil,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: KutralKoColors.smoke,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (!isAdmin &&
              idUsuarioPerfil == null &&
              idTrabajadorPerfil == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Pendiente de vinculacion',
              style: TextStyle(
                color: KutralKoColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfilBanner extends StatelessWidget {
  const _PerfilBanner({
    required this.isLoading,
    required this.rolPerfil,
    required this.emailPerfil,
    required this.idUsuarioPerfil,
    required this.idTrabajadorPerfil,
  });

  final bool isLoading;
  final String rolPerfil;
  final String emailPerfil;
  final String? idUsuarioPerfil;
  final String? idTrabajadorPerfil;

  @override
  Widget build(BuildContext context) {
    final isAdmin = rolPerfil == 'administrador';
    final isWorker = rolPerfil == 'trabajador';
    final title = isLoading
        ? 'Verificando perfil'
        : isAdmin
        ? 'Modo administrador'
        : isWorker
        ? 'Modo trabajador'
        : 'Modo cliente';
    final subtitle = isLoading
        ? 'Cargando permisos reales'
        : isAdmin
        ? emailPerfil
        : isWorker
        ? idTrabajadorPerfil == null
              ? 'Lectura sin trabajador vinculado'
              : emailPerfil
        : idUsuarioPerfil == null
        ? 'Lectura sin cliente vinculado'
        : emailPerfil;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: KutralKoColors.carbon,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: KutralKoColors.gold.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : isWorker
                  ? Icons.badge_rounded
                  : Icons.person_rounded,
              color: KutralKoColors.gold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: KutralKoColors.ivory,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KutralKoColors.smoke,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _PerfilLinkSheet extends StatelessWidget {
  const _PerfilLinkSheet({required this.usuarios, required this.trabajadores});

  final List<Usuario> usuarios;
  final List<Trabajador> trabajadores;

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Vincular perfiles',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('perfiles')
            .orderBy('emailPerfil')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final administradores =
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final trabajadoresPerfil =
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final clientes = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final sinVincular = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          for (final doc in docs) {
            final data = doc.data();
            final rol = data['rolPerfil'] as String? ?? 'cliente';
            final tieneCliente =
                data['idUsuarioPerfil'] is String &&
                (data['idUsuarioPerfil'] as String).isNotEmpty;
            final tieneTrabajador =
                data['idTrabajadorPerfil'] is String &&
                (data['idTrabajadorPerfil'] as String).isNotEmpty;

            if (rol == 'administrador') {
              administradores.add(doc);
            } else if (rol == 'trabajador' && tieneTrabajador) {
              trabajadoresPerfil.add(doc);
            } else if (rol == 'cliente' && tieneCliente) {
              clientes.add(doc);
            } else {
              sinVincular.add(doc);
            }
          }

          if (docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.person_search_rounded,
              title: 'Sin perfiles',
              message: 'Cuando alguien cree cuenta, aparecera aqui.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PerfilSection(
                title: 'Sin vincular',
                icon: Icons.link_off_rounded,
                perfiles: sinVincular,
                usuarios: usuarios,
                trabajadores: trabajadores,
              ),
              _PerfilSection(
                title: 'Administradores',
                icon: Icons.admin_panel_settings_rounded,
                perfiles: administradores,
                usuarios: usuarios,
                trabajadores: trabajadores,
              ),
              _PerfilSection(
                title: 'Trabajadores',
                icon: Icons.badge_rounded,
                perfiles: trabajadoresPerfil,
                usuarios: usuarios,
                trabajadores: trabajadores,
              ),
              _PerfilSection(
                title: 'Clientes',
                icon: Icons.person_rounded,
                perfiles: clientes,
                usuarios: usuarios,
                trabajadores: trabajadores,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PerfilSection extends StatelessWidget {
  const _PerfilSection({
    required this.title,
    required this.icon,
    required this.perfiles,
    required this.usuarios,
    required this.trabajadores,
  });

  final String title;
  final IconData icon;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> perfiles;
  final List<Usuario> usuarios;
  final List<Trabajador> trabajadores;

  @override
  Widget build(BuildContext context) {
    if (perfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: KutralKoColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                perfiles.length.toString(),
                style: const TextStyle(
                  color: KutralKoColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final perfil in perfiles)
            _PerfilLinkTile(
              perfilId: perfil.id,
              perfil: perfil.data(),
              usuarios: usuarios,
              trabajadores: trabajadores,
            ),
        ],
      ),
    );
  }
}

class _PerfilLinkTile extends StatelessWidget {
  const _PerfilLinkTile({
    required this.perfilId,
    required this.perfil,
    required this.usuarios,
    required this.trabajadores,
  });

  final String perfilId;
  final Map<String, dynamic> perfil;
  final List<Usuario> usuarios;
  final List<Trabajador> trabajadores;

  @override
  Widget build(BuildContext context) {
    final idUsuarioPerfil = perfil['idUsuarioPerfil'] as String?;
    final idTrabajadorPerfil = perfil['idTrabajadorPerfil'] as String?;
    final rolPerfil = perfil['rolPerfil'] as String? ?? 'cliente';
    final email = perfil['emailPerfil'] as String? ?? 'Perfil sin correo';
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final selectedUsuario = usuarios.where(
      (usuario) => usuario.idUsuario == idUsuarioPerfil,
    );
    final selectedTrabajador = trabajadores.where(
      (trabajador) => trabajador.idTrabajador == idTrabajadorPerfil,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _RolePill(rolPerfil: rolPerfil),
              ],
            ),
            if (perfilId == currentUid) ...[
              const SizedBox(height: 6),
              const Text(
                'Tu sesion actual',
                style: TextStyle(
                  color: KutralKoColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RoleActionButton(
                  label: 'Hacer admin',
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: rolPerfil == 'administrador',
                  onPressed: () => _changeRole(context, 'administrador'),
                ),
                _RoleActionButton(
                  label: 'Hacer trabajador',
                  icon: Icons.badge_rounded,
                  isSelected: rolPerfil == 'trabajador',
                  onPressed: () => _changeRole(context, 'trabajador'),
                ),
                _RoleActionButton(
                  label: 'Hacer cliente',
                  icon: Icons.person_rounded,
                  isSelected: rolPerfil == 'cliente',
                  onPressed: () => _changeRole(context, 'cliente'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedUsuario.isEmpty
                  ? null
                  : selectedUsuario.first.idUsuario,
              decoration: const InputDecoration(labelText: 'Cliente vinculado'),
              items: [
                for (final usuario in usuarios)
                  DropdownMenuItem(
                    value: usuario.idUsuario,
                    child: Text(usuario.nombreUsuario),
                  ),
              ],
              onChanged: (idUsuario) => _linkCliente(context, idUsuario),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedTrabajador.isEmpty
                  ? null
                  : selectedTrabajador.first.idTrabajador,
              decoration: const InputDecoration(
                labelText: 'Trabajador vinculado',
              ),
              items: [
                for (final trabajador in trabajadores)
                  DropdownMenuItem(
                    value: trabajador.idTrabajador,
                    child: Text(trabajador.nombreTrabajador),
                  ),
              ],
              onChanged: (idTrabajador) =>
                  _linkTrabajador(context, idTrabajador),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, String nextRole) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentRole = perfil['rolPerfil'] as String? ?? 'cliente';
    if (currentRole == nextRole) {
      return;
    }

    if (perfilId == currentUid &&
        currentRole == 'administrador' &&
        nextRole != 'administrador') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes quitarte tu propio rol administrador.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await _confirmProfileAction(
      context: context,
      title: 'Cambiar rol',
      message:
          'El perfil pasara de ${_roleLabel(currentRole)} a ${_roleLabel(nextRole)}.',
    );
    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _updateProfile(context, {
      'rolPerfil': nextRole,
      if (nextRole == 'administrador') ...{
        'idUsuarioPerfil': FieldValue.delete(),
        'idTrabajadorPerfil': FieldValue.delete(),
      },
    }, action: 'cambiar_rol_$nextRole');
  }

  Future<void> _linkCliente(BuildContext context, String? idUsuario) async {
    if (idUsuario == null) {
      return;
    }

    final usuario = usuarios.firstWhere(
      (usuario) => usuario.idUsuario == idUsuario,
    );
    final confirmed = await _confirmProfileAction(
      context: context,
      title: 'Vincular cliente',
      message: 'Este perfil vera la cuenta de ${usuario.nombreUsuario}.',
    );
    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _updateProfile(context, {
      'rolPerfil': 'cliente',
      'idUsuarioPerfil': idUsuario,
      'idTrabajadorPerfil': FieldValue.delete(),
    }, action: 'vincular_cliente');
  }

  Future<void> _linkTrabajador(
    BuildContext context,
    String? idTrabajador,
  ) async {
    if (idTrabajador == null) {
      return;
    }

    final trabajador = trabajadores.firstWhere(
      (trabajador) => trabajador.idTrabajador == idTrabajador,
    );
    final confirmed = await _confirmProfileAction(
      context: context,
      title: 'Vincular trabajador',
      message:
          'Este perfil podra marcar turnos como ${trabajador.nombreTrabajador}.',
    );
    if (!confirmed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _updateProfile(context, {
      'rolPerfil': 'trabajador',
      'idTrabajadorPerfil': idTrabajador,
      'idUsuarioPerfil': FieldValue.delete(),
    }, action: 'vincular_trabajador');
  }

  Future<void> _updateProfile(
    BuildContext context,
    Map<String, dynamic> data, {
    required String action,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('perfiles')
          .doc(perfilId)
          .set(data, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('auditoria').add({
        'accionAuditoria': action,
        'tipoMovimientoAuditoria': 'perfil',
        'idMovimientoAuditoria': perfilId,
        'emailPerfilAfectadoAuditoria': perfil['emailPerfil'] as String? ?? '',
        'idPerfilAuditoria': user?.uid ?? '',
        'emailPerfilAuditoria': user?.email ?? '',
        'fechaAuditoria': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar perfil: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.rolPerfil});

  final String rolPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KutralKoColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _roleLabel(rolPerfil),
        style: const TextStyle(
          color: KutralKoColors.carbon,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  const _RoleActionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? FilledButton.icon(
            onPressed: null,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

Future<bool> _confirmProfileAction({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

String _roleLabel(String rolPerfil) {
  return switch (rolPerfil) {
    'administrador' => 'Administrador',
    'trabajador' => 'Trabajador',
    _ => 'Cliente',
  };
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.usuarios,
    required this.saldoPendiente,
    required this.totalConsumido,
    required this.totalPagado,
    required this.saldoUsuario,
    required this.mesLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenUsuario,
    required this.onNuevoConsumo,
    required this.onNuevoPago,
  });

  final List<Usuario> usuarios;
  final int saldoPendiente;
  final int totalConsumido;
  final int totalPagado;
  final int Function(String idUsuario) saldoUsuario;
  final String mesLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<Usuario> onOpenUsuario;
  final VoidCallback? onNuevoConsumo;
  final VoidCallback? onNuevoPago;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _BalanceHero(
          saldoPendiente: saldoPendiente,
          totalConsumido: totalConsumido,
          totalPagado: totalPagado,
          mesLabel: mesLabel,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
        ),
        const SizedBox(height: 16),
        _QuickActions(onNuevoConsumo: onNuevoConsumo, onNuevoPago: onNuevoPago),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Clientes activos'),
        const SizedBox(height: 12),
        if (usuarios.isEmpty)
          const _EmptyState(
            icon: Icons.people_alt_outlined,
            title: 'Sin clientes todavia',
            message: 'Crea el primer cliente para empezar a registrar cuentas.',
          )
        else
          for (final usuario in usuarios.where(
            (item) => item.estaActivoUsuario,
          ))
            _UsuarioTile(
              usuario: usuario,
              saldo: saldoUsuario(usuario.idUsuario),
              onOpen: () => onOpenUsuario(usuario),
            ),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.saldoPendiente,
    required this.totalConsumido,
    required this.totalPagado,
    required this.mesLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final int saldoPendiente;
  final int totalConsumido;
  final int totalPagado;
  final String mesLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KutralKoColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo pendiente',
                style: TextStyle(
                  color: KutralKoColors.smoke,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _MonthSelector(
                label: mesLabel,
                onPrevious: onPreviousMonth,
                onNext: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.clp(saldoPendiente),
            style: const TextStyle(
              color: KutralKoColors.ivory,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Consumido',
                  value: CurrencyFormatter.clp(totalConsumido),
                  color: KutralKoColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Abonado',
                  value: CurrencyFormatter.clp(totalPagado),
                  color: KutralKoColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KutralKoColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MonthIconButton(
            tooltip: 'Mes anterior',
            icon: Icons.chevron_left_rounded,
            onPressed: onPrevious,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 92),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KutralKoColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _MonthIconButton(
            tooltip: 'Mes siguiente',
            icon: Icons.chevron_right_rounded,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _MonthIconButton extends StatelessWidget {
  const _MonthIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: KutralKoColors.gold, size: 20),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KutralKoColors.smoke,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onNuevoConsumo,
    required this.onNuevoPago,
  });

  final VoidCallback? onNuevoConsumo;
  final VoidCallback? onNuevoPago;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onNuevoConsumo,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Agregar consumo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNuevoPago,
            icon: const Icon(Icons.payments_rounded),
            label: const Text('Registrar pago'),
          ),
        ),
      ],
    );
  }
}

class _UsuariosView extends StatelessWidget {
  const _UsuariosView({
    required this.usuarios,
    required this.saldoUsuario,
    required this.puedeAdministrar,
    required this.onNuevoUsuario,
    required this.onOpenUsuario,
    required this.onEditarUsuario,
    required this.onToggleUsuario,
  });

  final List<Usuario> usuarios;
  final int Function(String idUsuario) saldoUsuario;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoUsuario;
  final ValueChanged<Usuario> onOpenUsuario;
  final ValueChanged<Usuario>? onEditarUsuario;
  final ValueChanged<Usuario>? onToggleUsuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _SectionHeader(
          title: 'Clientes',
          action: puedeAdministrar ? 'Nuevo' : null,
          onAction: onNuevoUsuario,
        ),
        const SizedBox(height: 12),
        if (usuarios.isEmpty)
          const _EmptyState(
            icon: Icons.people_alt_outlined,
            title: 'Sin clientes',
            message: 'Agrega clientes o convenios internos para comenzar.',
          )
        else
          for (final usuario in usuarios)
            _UsuarioTile(
              usuario: usuario,
              saldo: saldoUsuario(usuario.idUsuario),
              onOpen: () => onOpenUsuario(usuario),
              onEdit: puedeAdministrar ? () => onEditarUsuario!(usuario) : null,
              onToggle: puedeAdministrar
                  ? () => onToggleUsuario!(usuario)
                  : null,
            ),
      ],
    );
  }
}

class _ProductosView extends StatelessWidget {
  const _ProductosView({
    required this.productos,
    required this.puedeAdministrar,
    required this.onNuevoProducto,
    required this.onEditarProducto,
    required this.onToggleProducto,
  });

  final List<Producto> productos;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoProducto;
  final ValueChanged<Producto>? onEditarProducto;
  final ValueChanged<Producto>? onToggleProducto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _SectionHeader(
          title: 'Carta editable',
          action: puedeAdministrar ? 'Producto' : null,
          onAction: onNuevoProducto,
        ),
        const SizedBox(height: 12),
        if (productos.isEmpty)
          const _EmptyState(
            icon: Icons.local_dining_outlined,
            title: 'Sin productos',
            message:
                'Crea los productos de carta o barra para cargar consumos.',
          )
        else
          for (final producto in productos)
            _ProductoTile(
              producto: producto,
              puedeAdministrar: puedeAdministrar,
              onEdit: puedeAdministrar
                  ? () => onEditarProducto!(producto)
                  : null,
              onToggle: puedeAdministrar
                  ? () => onToggleProducto!(producto)
                  : null,
            ),
      ],
    );
  }
}

class _MovimientosView extends StatelessWidget {
  const _MovimientosView({
    required this.usuarios,
    required this.consumos,
    required this.pagos,
    required this.puedeAdministrar,
    required this.onNuevoConsumo,
    required this.onNuevoPago,
    required this.onAnularConsumo,
    required this.onAnularPago,
    required this.onEditarConsumo,
    required this.onEditarPago,
  });

  final List<Usuario> usuarios;
  final List<Consumo> consumos;
  final List<Pago> pagos;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoConsumo;
  final VoidCallback? onNuevoPago;
  final ValueChanged<Consumo>? onAnularConsumo;
  final ValueChanged<Pago>? onAnularPago;
  final ValueChanged<Consumo>? onEditarConsumo;
  final ValueChanged<Pago>? onEditarPago;

  @override
  Widget build(BuildContext context) {
    final usuariosPorId = {
      for (final usuario in usuarios) usuario.idUsuario: usuario.nombreUsuario,
    };
    final movimientos = [
      for (final consumo in consumos)
        _MovimientoItem.consumo(
          consumo: consumo,
          nombreUsuario:
              usuariosPorId[consumo.idUsuario] ?? 'Cliente sin nombre',
          onAnular: onAnularConsumo == null || consumo.estaAnuladoConsumo
              ? null
              : () => onAnularConsumo!(consumo),
          onEditar: onEditarConsumo == null || consumo.estaAnuladoConsumo
              ? null
              : () => onEditarConsumo!(consumo),
        ),
      for (final pago in pagos)
        _MovimientoItem.pago(
          pago: pago,
          nombreUsuario: usuariosPorId[pago.idUsuario] ?? 'Cliente sin nombre',
          onAnular: onAnularPago == null || pago.estaAnuladoPago
              ? null
              : () => onAnularPago!(pago),
          onEditar: onEditarPago == null || pago.estaAnuladoPago
              ? null
              : () => onEditarPago!(pago),
        ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final hasMovimientos = movimientos.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SectionHeader(title: 'Cuenta mensual'),
        const SizedBox(height: 12),
        if (puedeAdministrar) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNuevoConsumo,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Agregar consumo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNuevoPago,
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Registrar pago'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Movimientos recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (!hasMovimientos)
                  const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    message:
                        'Registra consumos o abonos desde acciones reales.',
                  )
                else ...[
                  for (final movimiento in movimientos)
                    _MovementRow(
                      icon: movimiento.icon,
                      title: movimiento.title,
                      detail: movimiento.detail,
                      amount: movimiento.amount,
                      color: movimiento.color,
                      isAnulado: movimiento.isAnulado,
                      onAnular: movimiento.onAnular,
                      onEditar: movimiento.onEditar,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovimientoItem {
  const _MovimientoItem({
    required this.fecha,
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
    required this.color,
    required this.isAnulado,
    required this.onAnular,
    required this.onEditar,
  });

  factory _MovimientoItem.consumo({
    required Consumo consumo,
    required String nombreUsuario,
    bool mostrarUsuario = true,
    VoidCallback? onAnular,
    VoidCallback? onEditar,
  }) {
    final isAnulado = consumo.estaAnuladoConsumo;
    final cantidad = consumo.cantidadConsumo == 1
        ? '1 unidad'
        : '${consumo.cantidadConsumo} unidades';
    final detalleBase = mostrarUsuario
        ? '$nombreUsuario · $cantidad'
        : cantidad;
    final detalleActivo = consumo.notaConsumo.isEmpty
        ? detalleBase
        : '$detalleBase · ${consumo.notaConsumo}';
    final detalle = isAnulado ? 'Anulado · $detalleActivo' : detalleActivo;

    return _MovimientoItem(
      fecha: consumo.fechaConsumo,
      icon: Icons.restaurant_menu_rounded,
      title: consumo.nombreProductoSnapshot,
      detail: detalle,
      amount: CurrencyFormatter.clp(consumo.totalConsumo),
      color: isAnulado ? KutralKoColors.muted : KutralKoColors.orange,
      isAnulado: isAnulado,
      onAnular: onAnular,
      onEditar: onEditar,
    );
  }

  factory _MovimientoItem.pago({
    required Pago pago,
    required String nombreUsuario,
    bool mostrarUsuario = true,
    VoidCallback? onAnular,
    VoidCallback? onEditar,
  }) {
    final isAnulado = pago.estaAnuladoPago;
    final detalleBase = mostrarUsuario ? nombreUsuario : 'Abono registrado';
    final detalleActivo = pago.notaPago.isEmpty
        ? detalleBase
        : '$detalleBase · ${pago.notaPago}';
    final detalle = isAnulado ? 'Anulado · $detalleActivo' : detalleActivo;
    final title = pago.metodoPago.isEmpty
        ? 'Pago'
        : 'Pago · ${pago.metodoPago}';

    return _MovimientoItem(
      fecha: pago.fechaPago,
      icon: Icons.payments_rounded,
      title: title,
      detail: detalle,
      amount: '-${CurrencyFormatter.clp(pago.montoPago)}',
      color: isAnulado ? KutralKoColors.muted : KutralKoColors.success,
      isAnulado: isAnulado,
      onAnular: onAnular,
      onEditar: onEditar,
    );
  }

  final DateTime fecha;
  final IconData icon;
  final String title;
  final String detail;
  final String amount;
  final Color color;
  final bool isAnulado;
  final VoidCallback? onAnular;
  final VoidCallback? onEditar;
}

class _UsuarioDetailSheet extends StatelessWidget {
  const _UsuarioDetailSheet({
    required this.usuario,
    required this.consumos,
    required this.pagos,
    required this.totalConsumido,
    required this.totalPagado,
    required this.saldo,
    required this.puedeAdministrar,
    required this.onNuevoConsumo,
    required this.onNuevoPago,
    required this.onAnularConsumo,
    required this.onAnularPago,
    required this.onEditarConsumo,
    required this.onEditarPago,
  });

  final Usuario usuario;
  final List<Consumo> consumos;
  final List<Pago> pagos;
  final int totalConsumido;
  final int totalPagado;
  final int saldo;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoConsumo;
  final VoidCallback? onNuevoPago;
  final ValueChanged<Consumo>? onAnularConsumo;
  final ValueChanged<Pago>? onAnularPago;
  final ValueChanged<Consumo>? onEditarConsumo;
  final ValueChanged<Pago>? onEditarPago;

  @override
  Widget build(BuildContext context) {
    final movimientos = [
      for (final consumo in consumos.where(
        (consumo) => consumo.idUsuario == usuario.idUsuario,
      ))
        _MovimientoItem.consumo(
          consumo: consumo,
          nombreUsuario: usuario.nombreUsuario,
          mostrarUsuario: false,
          onAnular: onAnularConsumo == null || consumo.estaAnuladoConsumo
              ? null
              : () => onAnularConsumo!(consumo),
          onEditar: onEditarConsumo == null || consumo.estaAnuladoConsumo
              ? null
              : () => onEditarConsumo!(consumo),
        ),
      for (final pago in pagos.where(
        (pago) => pago.idUsuario == usuario.idUsuario,
      ))
        _MovimientoItem.pago(
          pago: pago,
          nombreUsuario: usuario.nombreUsuario,
          mostrarUsuario: false,
          onAnular: onAnularPago == null || pago.estaAnuladoPago
              ? null
              : () => onAnularPago!(pago),
          onEditar: onEditarPago == null || pago.estaAnuladoPago
              ? null
              : () => onEditarPago!(pago),
        ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return _FormScaffold(
      title: usuario.nombreUsuario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UsuarioBalancePanel(
            saldo: saldo,
            totalConsumido: totalConsumido,
            totalPagado: totalPagado,
          ),
          if (puedeAdministrar) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNuevoConsumo,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Agregar consumo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNuevoPago,
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Registrar pago'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Historial del cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (movimientos.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sin historial',
              message: 'Los consumos y pagos del cliente apareceran aqui.',
            )
          else
            for (final movimiento in movimientos)
              _MovementRow(
                icon: movimiento.icon,
                title: movimiento.title,
                detail: movimiento.detail,
                amount: movimiento.amount,
                color: movimiento.color,
                isAnulado: movimiento.isAnulado,
                onAnular: movimiento.onAnular,
                onEditar: movimiento.onEditar,
              ),
        ],
      ),
    );
  }
}

class _UsuarioBalancePanel extends StatelessWidget {
  const _UsuarioBalancePanel({
    required this.saldo,
    required this.totalConsumido,
    required this.totalPagado,
  });

  final int saldo;
  final int totalConsumido;
  final int totalPagado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KutralKoColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo actual',
            style: TextStyle(
              color: KutralKoColors.smoke,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.clp(saldo),
            style: const TextStyle(
              color: KutralKoColors.gold,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Consumido',
                  value: CurrencyFormatter.clp(totalConsumido),
                  color: KutralKoColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Abonado',
                  value: CurrencyFormatter.clp(totalPagado),
                  color: KutralKoColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalView extends StatelessWidget {
  const _PersonalView({
    required this.trabajadores,
    required this.asistencias,
    required this.consumosPersonal,
    required this.trabajadorPerfil,
    required this.puedeAdministrar,
    required this.esTrabajador,
    required this.mesLabel,
    required this.asistenciaAbierta,
    required this.onNuevoTrabajador,
    required this.onRegistrarConsumo,
    required this.onOpenTrabajador,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onIniciarTurno,
    required this.onFinalizarTurno,
  });

  final List<Trabajador> trabajadores;
  final List<Asistencia> asistencias;
  final List<ConsumoPersonal> consumosPersonal;
  final Trabajador? trabajadorPerfil;
  final bool puedeAdministrar;
  final bool esTrabajador;
  final String mesLabel;
  final Asistencia? asistenciaAbierta;
  final VoidCallback? onNuevoTrabajador;
  final VoidCallback? onRegistrarConsumo;
  final ValueChanged<Trabajador>? onOpenTrabajador;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onIniciarTurno;
  final VoidCallback? onFinalizarTurno;

  @override
  Widget build(BuildContext context) {
    final trabajadoresEnTurno = trabajadores.where((trabajador) {
      return asistencias.any(
        (asistencia) =>
            asistencia.idTrabajador == trabajador.idTrabajador &&
            asistencia.estaAbierta,
      );
    }).length;
    final minutosTrabajados = asistencias
        .where((asistencia) => !asistencia.estaAnuladaAsistencia)
        .fold(0, (total, asistencia) => total + asistencia.minutosTrabajados);
    final totalConsumos = consumosPersonal
        .where((consumo) => !consumo.estaAnuladoConsumoPersonal)
        .fold(0, (total, consumo) => total + consumo.montoConsumoPersonal);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _SectionHeader(
          title: puedeAdministrar ? 'Personal' : 'Mi turno',
          action: puedeAdministrar ? 'Trabajador' : null,
          onAction: onNuevoTrabajador,
        ),
        const SizedBox(height: 12),
        if (esTrabajador)
          _WorkerClockPanel(
            trabajador: trabajadorPerfil,
            asistenciaAbierta: asistenciaAbierta,
            minutosTrabajados: minutosTrabajados,
            totalConsumos: totalConsumos,
            mesLabel: mesLabel,
            onIniciarTurno: onIniciarTurno,
            onFinalizarTurno: onFinalizarTurno,
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _AdminMetricCard(
                  label: 'Activos',
                  value: trabajadores.length.toString(),
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminMetricCard(
                  label: 'En turno',
                  value: trabajadoresEnTurno.toString(),
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AdminMetricCard(
                  label: 'Horas mes',
                  value: _formatMinutes(minutosTrabajados),
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminMetricCard(
                  label: 'Consumo',
                  value: CurrencyFormatter.clp(totalConsumos),
                  icon: Icons.restaurant_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRegistrarConsumo,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Consumo personal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportExcel,
                  icon: const Icon(Icons.table_chart_rounded),
                  label: const Text('Excel'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _SectionHeader(title: puedeAdministrar ? 'Equipo' : 'Historial'),
        const SizedBox(height: 12),
        if (puedeAdministrar && trabajadores.isEmpty)
          const _EmptyState(
            icon: Icons.badge_outlined,
            title: 'Sin trabajadores',
            message: 'Crea el primer trabajador para controlar asistencia.',
          )
        else if (puedeAdministrar)
          for (final trabajador in trabajadores)
            _TrabajadorTile(
              trabajador: trabajador,
              onOpen: onOpenTrabajador == null
                  ? null
                  : () => onOpenTrabajador!(trabajador),
              asistenciaAbierta: _findAsistenciaAbierta(
                asistencias,
                trabajador.idTrabajador,
              ),
              consumoMes: _totalConsumoTrabajador(
                consumosPersonal,
                trabajador.idTrabajador,
              ),
              minutosMes: _totalMinutosTrabajador(
                asistencias,
                trabajador.idTrabajador,
              ),
            )
        else
          _PersonalHistory(
            asistencias: asistencias,
            consumosPersonal: consumosPersonal,
          ),
      ],
    );
  }

  static Asistencia? _findAsistenciaAbierta(
    List<Asistencia> asistencias,
    String idTrabajador,
  ) {
    for (final asistencia in asistencias) {
      if (asistencia.idTrabajador == idTrabajador && asistencia.estaAbierta) {
        return asistencia;
      }
    }
    return null;
  }

  static int _totalConsumoTrabajador(
    List<ConsumoPersonal> consumos,
    String idTrabajador,
  ) {
    return consumos
        .where(
          (consumo) =>
              consumo.idTrabajador == idTrabajador &&
              !consumo.estaAnuladoConsumoPersonal,
        )
        .fold(0, (total, consumo) => total + consumo.montoConsumoPersonal);
  }

  static int _totalMinutosTrabajador(
    List<Asistencia> asistencias,
    String idTrabajador,
  ) {
    return asistencias
        .where(
          (asistencia) =>
              asistencia.idTrabajador == idTrabajador &&
              !asistencia.estaAnuladaAsistencia,
        )
        .fold(0, (total, asistencia) => total + asistencia.minutosTrabajados);
  }
}

class _WorkerClockPanel extends StatelessWidget {
  const _WorkerClockPanel({
    required this.trabajador,
    required this.asistenciaAbierta,
    required this.minutosTrabajados,
    required this.totalConsumos,
    required this.mesLabel,
    required this.onIniciarTurno,
    required this.onFinalizarTurno,
  });

  final Trabajador? trabajador;
  final Asistencia? asistenciaAbierta;
  final int minutosTrabajados;
  final int totalConsumos;
  final String mesLabel;
  final VoidCallback? onIniciarTurno;
  final VoidCallback? onFinalizarTurno;

  @override
  Widget build(BuildContext context) {
    final isLinked = trabajador != null;
    final isWorking = asistenciaAbierta != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isWorking ? 'En turno' : 'Fuera de turno',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              isLinked
                  ? '${trabajador!.nombreTrabajador} · $mesLabel'
                  : 'Tu perfil aun no esta vinculado a trabajador.',
              style: const TextStyle(
                color: KutralKoColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    label: 'Horas',
                    value: _formatMinutes(minutosTrabajados),
                    icon: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminMetricCard(
                    label: 'Descuento',
                    value: CurrencyFormatter.clp(totalConsumos),
                    icon: Icons.payments_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLinked && !isWorking ? onIniciarTurno : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar turno'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLinked && isWorking ? onFinalizarTurno : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: KutralKoColors.gold),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: KutralKoColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrabajadorTile extends StatelessWidget {
  const _TrabajadorTile({
    required this.trabajador,
    required this.onOpen,
    required this.asistenciaAbierta,
    required this.consumoMes,
    required this.minutosMes,
  });

  final Trabajador trabajador;
  final VoidCallback? onOpen;
  final Asistencia? asistenciaAbierta;
  final int consumoMes;
  final int minutosMes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: asistenciaAbierta == null
              ? KutralKoColors.smoke
              : KutralKoColors.gold.withValues(alpha: 0.28),
          foregroundColor: KutralKoColors.carbon,
          child: Icon(
            asistenciaAbierta == null
                ? Icons.person_rounded
                : Icons.timer_rounded,
          ),
        ),
        title: Text(
          trabajador.nombreTrabajador,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${trabajador.cargoTrabajador} · ${asistenciaAbierta == null ? 'Fuera de turno' : 'En turno'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatMinutes(minutosMes),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              CurrencyFormatter.clp(consumoMes),
              style: const TextStyle(
                color: KutralKoColors.ember,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalHistory extends StatelessWidget {
  const _PersonalHistory({
    required this.asistencias,
    required this.consumosPersonal,
  });

  final List<Asistencia> asistencias;
  final List<ConsumoPersonal> consumosPersonal;

  @override
  Widget build(BuildContext context) {
    if (asistencias.isEmpty && consumosPersonal.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'Sin registros',
        message: 'Tus horas y consumos apareceran aqui.',
      );
    }

    return Column(
      children: [
        for (final asistencia in asistencias)
          _MovementRow(
            icon: Icons.schedule_rounded,
            title: asistencia.estaAbierta ? 'Turno en curso' : 'Turno cerrado',
            detail: _formatDate(asistencia.fechaAsistencia),
            amount: _formatMinutes(asistencia.minutosTrabajados),
            color: KutralKoColors.teal,
            isAnulado: asistencia.estaAnuladaAsistencia,
            onAnular: null,
            onEditar: null,
          ),
        for (final consumo in consumosPersonal)
          _MovementRow(
            icon: Icons.restaurant_rounded,
            title: consumo.nombreProductoSnapshot,
            detail: _formatDate(consumo.fechaConsumoPersonal),
            amount: CurrencyFormatter.clp(consumo.montoConsumoPersonal),
            color: KutralKoColors.orange,
            isAnulado: consumo.estaAnuladoConsumoPersonal,
            onAnular: null,
            onEditar: null,
          ),
      ],
    );
  }
}

class _TrabajadorDetailSheet extends StatelessWidget {
  const _TrabajadorDetailSheet({
    required this.trabajador,
    required this.asistencias,
    required this.consumosPersonal,
    required this.asistenciaAbierta,
    required this.onEditarTrabajador,
    required this.onEditarAsistencia,
    required this.onAnularConsumoPersonal,
  });

  final Trabajador trabajador;
  final List<Asistencia> asistencias;
  final List<ConsumoPersonal> consumosPersonal;
  final Asistencia? asistenciaAbierta;
  final VoidCallback onEditarTrabajador;
  final ValueChanged<Asistencia> onEditarAsistencia;
  final ValueChanged<ConsumoPersonal> onAnularConsumoPersonal;

  @override
  Widget build(BuildContext context) {
    final minutosTrabajados = asistencias
        .where((asistencia) => !asistencia.estaAnuladaAsistencia)
        .fold(0, (total, asistencia) => total + asistencia.minutosTrabajados);
    final minutosExtra = asistencias
        .where((asistencia) => !asistencia.estaAnuladaAsistencia)
        .fold(0, (total, asistencia) => total + asistencia.minutosExtra);
    final atrasos = asistencias
        .where(
          (asistencia) =>
              !asistencia.estaAnuladaAsistencia && asistencia.minutosAtraso > 0,
        )
        .length;
    final totalConsumos = consumosPersonal
        .where((consumo) => !consumo.estaAnuladoConsumoPersonal)
        .fold(0, (total, consumo) => total + consumo.montoConsumoPersonal);

    return _FormScaffold(
      title: trabajador.nombreTrabajador,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _AdminMetricCard(
                  label: 'Horas',
                  value: _formatMinutes(minutosTrabajados),
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminMetricCard(
                  label: 'Descuento',
                  value: CurrencyFormatter.clp(totalConsumos),
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AdminMetricCard(
                  label: 'Extras',
                  value: _formatMinutes(minutosExtra),
                  icon: Icons.more_time_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminMetricCard(
                  label: 'Atrasos',
                  value: atrasos.toString(),
                  icon: Icons.alarm_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                asistenciaAbierta == null
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
                color: KutralKoColors.gold,
              ),
              title: Text(
                asistenciaAbierta == null ? 'Fuera de turno' : 'En turno',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${trabajador.cargoTrabajador} · ${trabajador.emailTrabajador.isEmpty ? 'sin correo' : trabajador.emailTrabajador}',
              ),
              trailing: IconButton(
                tooltip: 'Editar trabajador',
                onPressed: onEditarTrabajador,
                icon: const Icon(Icons.edit_rounded),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Asistencia'),
          const SizedBox(height: 10),
          if (asistencias.isEmpty)
            const _EmptyState(
              icon: Icons.schedule_rounded,
              title: 'Sin asistencias',
              message: 'Los turnos marcados apareceran aqui.',
            )
          else
            for (final asistencia in asistencias)
              _MovementRow(
                icon: asistencia.estaAbierta
                    ? Icons.play_circle_rounded
                    : Icons.check_circle_rounded,
                title: asistencia.estaAbierta
                    ? 'Turno en curso'
                    : 'Turno cerrado',
                detail:
                    '${_formatDate(asistencia.fechaAsistencia)} · ${asistencia.observacionAsistencia.isEmpty ? 'Sin observacion' : asistencia.observacionAsistencia}',
                amount: _formatMinutes(asistencia.minutosTrabajados),
                color: KutralKoColors.teal,
                isAnulado: asistencia.estaAnuladaAsistencia,
                onEditar: () => onEditarAsistencia(asistencia),
                onAnular: null,
              ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Consumos internos'),
          const SizedBox(height: 10),
          if (consumosPersonal.isEmpty)
            const _EmptyState(
              icon: Icons.restaurant_rounded,
              title: 'Sin consumos',
              message: 'Los consumos internos apareceran aqui.',
            )
          else
            for (final consumo in consumosPersonal)
              _MovementRow(
                icon: Icons.restaurant_rounded,
                title: consumo.nombreProductoSnapshot,
                detail:
                    '${_formatDate(consumo.fechaConsumoPersonal)} · ${consumo.notaConsumoPersonal.isEmpty ? 'Sin nota' : consumo.notaConsumoPersonal}',
                amount: CurrencyFormatter.clp(consumo.montoConsumoPersonal),
                color: KutralKoColors.orange,
                isAnulado: consumo.estaAnuladoConsumoPersonal,
                onEditar: null,
                onAnular: consumo.estaAnuladoConsumoPersonal
                    ? null
                    : () => onAnularConsumoPersonal(consumo),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: KutralKoColors.carbon,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  const _UsuarioTile({
    required this.usuario,
    required this.saldo,
    this.onOpen,
    this.onEdit,
    this.onToggle,
  });

  final Usuario usuario;
  final int saldo;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = usuario.estaActivoUsuario
        ? KutralKoColors.carbon
        : KutralKoColors.muted;

    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: usuario.estaActivoUsuario
              ? KutralKoColors.smoke
              : KutralKoColors.smoke.withValues(alpha: 0.45),
          foregroundColor: foreground,
          child: Text(
            usuario.nombreUsuario.characters.first.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          usuario.nombreUsuario,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          usuario.estaActivoUsuario ? usuario.notaUsuario : 'Cliente inactivo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onEdit == null
            ? _SaldoBadge(saldo: saldo)
            : Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: usuario.estaActivoUsuario
                        ? 'Desactivar'
                        : 'Activar',
                    onPressed: onToggle,
                    icon: Icon(
                      usuario.estaActivoUsuario
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SaldoBadge extends StatelessWidget {
  const _SaldoBadge({required this.saldo});

  final int saldo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Saldo',
          style: TextStyle(
            color: KutralKoColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          CurrencyFormatter.clp(saldo),
          style: const TextStyle(
            color: KutralKoColors.ember,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProductoTile extends StatelessWidget {
  const _ProductoTile({
    required this.producto,
    required this.puedeAdministrar,
    required this.onEdit,
    required this.onToggle,
  });

  final Producto producto;
  final bool puedeAdministrar;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = producto.estaActivoProducto
        ? KutralKoColors.carbon
        : KutralKoColors.muted;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: KutralKoColors.gold.withValues(
              alpha: producto.estaActivoProducto ? 0.18 : 0.08,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_dining_rounded, color: foreground),
        ),
        title: Text(
          producto.nombreProducto,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          producto.estaActivoProducto
              ? '${producto.nombreCategoriaProducto} · ${CurrencyFormatter.clp(producto.precioProducto)}'
              : 'Producto inactivo · ${CurrencyFormatter.clp(producto.precioProducto)}',
        ),
        trailing: puedeAdministrar
            ? Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: producto.estaActivoProducto
                        ? 'Desactivar'
                        : 'Activar',
                    onPressed: onToggle,
                    icon: Icon(
                      producto.estaActivoProducto
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ],
              )
            : Text(
                CurrencyFormatter.clp(producto.precioProducto),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
    required this.color,
    required this.isAnulado,
    required this.onAnular,
    required this.onEditar,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String amount;
  final Color color;
  final bool isAnulado;
  final VoidCallback? onAnular;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAnulado
                        ? KutralKoColors.muted
                        : KutralKoColors.carbon,
                    decoration: isAnulado ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: KutralKoColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isAnulado ? KutralKoColors.muted : KutralKoColors.carbon,
              decoration: isAnulado ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onEditar != null || onAnular != null)
            PopupMenuButton<String>(
              tooltip: 'Acciones',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'editar') {
                  onEditar?.call();
                  return;
                }
                if (value == 'anular') {
                  onAnular?.call();
                }
              },
              itemBuilder: (context) => [
                if (onEditar != null)
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                if (onAnular != null)
                  const PopupMenuItem(
                    value: 'anular',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: KutralKoColors.ember),
                        SizedBox(width: 10),
                        Text('Anular'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KutralKoColors.smoke.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: KutralKoColors.muted, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: KutralKoColors.muted),
          ),
        ],
      ),
    );
  }
}

class _UsuarioFormSheet extends StatefulWidget {
  const _UsuarioFormSheet({this.usuario});

  final Usuario? usuario;

  @override
  State<_UsuarioFormSheet> createState() => _UsuarioFormSheetState();
}

class _UsuarioFormSheetState extends State<_UsuarioFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _notaController;
  late bool _estaActivoUsuario;

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuario;
    _nombreController = TextEditingController(
      text: usuario?.nombreUsuario ?? '',
    );
    _telefonoController = TextEditingController(
      text: usuario?.telefonoUsuario ?? '',
    );
    _notaController = TextEditingController(text: usuario?.notaUsuario ?? '');
    _estaActivoUsuario = usuario?.estaActivoUsuario ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Usuario(
        idUsuario: widget.usuario?.idUsuario ?? '',
        nombreUsuario: _nombreController.text.trim(),
        telefonoUsuario: _telefonoController.text.trim(),
        notaUsuario: _notaController.text.trim(),
        estaActivoUsuario: _estaActivoUsuario,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.usuario == null ? 'Nuevo cliente' : 'Editar cliente',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                hintText: 'Ingrese el nombre del cliente',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                hintText: 'Ingrese un telefono de contacto',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota del cliente',
                hintText: 'Agregue una nota opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaActivoUsuario,
              onChanged: (value) => setState(() => _estaActivoUsuario = value),
              title: const Text('Cliente activo'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _ProductoFormSheet extends StatefulWidget {
  const _ProductoFormSheet({this.producto});

  final Producto? producto;

  @override
  State<_ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<_ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _precioController;
  late bool _estaActivoProducto;
  late bool _esProductoFrecuente;

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombreController = TextEditingController(
      text: producto?.nombreProducto ?? '',
    );
    _categoriaController = TextEditingController(
      text: producto?.nombreCategoriaProducto ?? '',
    );
    _precioController = TextEditingController(
      text: producto == null ? '' : producto.precioProducto.toString(),
    );
    _estaActivoProducto = producto?.estaActivoProducto ?? true;
    _esProductoFrecuente = producto?.esProductoFrecuente ?? false;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Producto(
        idProducto: widget.producto?.idProducto ?? '',
        nombreProducto: _nombreController.text.trim(),
        nombreCategoriaProducto: _categoriaController.text.trim(),
        precioProducto: int.parse(_precioController.text.trim()),
        estaActivoProducto: _estaActivoProducto,
        esProductoFrecuente: _esProductoFrecuente,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.producto == null ? 'Nuevo producto' : 'Editar producto',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                hintText: 'Ej: Pisco sour',
                prefixIcon: Icon(Icons.local_dining_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                hintText: 'Ej: Cocteleria',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                hintText: 'Ej: 8500',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaActivoProducto,
              onChanged: (value) => setState(() => _estaActivoProducto = value),
              title: const Text('Producto activo'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _esProductoFrecuente,
              onChanged: (value) =>
                  setState(() => _esProductoFrecuente = value),
              title: const Text('Producto frecuente'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _TrabajadorFormSheet extends StatefulWidget {
  const _TrabajadorFormSheet({this.trabajador});

  final Trabajador? trabajador;

  @override
  State<_TrabajadorFormSheet> createState() => _TrabajadorFormSheetState();
}

class _TrabajadorFormSheetState extends State<_TrabajadorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _cargoController;
  late final TextEditingController _idPerfilController;
  late bool _estaActivoTrabajador;

  @override
  void initState() {
    super.initState();
    final trabajador = widget.trabajador;
    _nombreController = TextEditingController(
      text: trabajador?.nombreTrabajador ?? '',
    );
    _emailController = TextEditingController(
      text: trabajador?.emailTrabajador ?? '',
    );
    _telefonoController = TextEditingController(
      text: trabajador?.telefonoTrabajador ?? '',
    );
    _cargoController = TextEditingController(
      text: trabajador?.cargoTrabajador ?? '',
    );
    _idPerfilController = TextEditingController(
      text: trabajador?.idPerfil ?? '',
    );
    _estaActivoTrabajador = trabajador?.estaActivoTrabajador ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cargoController.dispose();
    _idPerfilController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Trabajador(
        idTrabajador: widget.trabajador?.idTrabajador ?? '',
        nombreTrabajador: _nombreController.text.trim(),
        emailTrabajador: _emailController.text.trim(),
        telefonoTrabajador: _telefonoController.text.trim(),
        cargoTrabajador: _cargoController.text.trim(),
        estaActivoTrabajador: _estaActivoTrabajador,
        idPerfil: _idPerfilController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.trabajador == null
          ? 'Nuevo trabajador'
          : 'Editar trabajador',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del trabajador',
                hintText: 'Ingrese nombre y apellido',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                hintText: 'correo@ejemplo.cl',
                prefixIcon: Icon(Icons.mail_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cargoController,
              decoration: const InputDecoration(
                labelText: 'Cargo',
                hintText: 'Ej: Garzon, cocina, barra',
                prefixIcon: Icon(Icons.work_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idPerfilController,
              decoration: const InputDecoration(
                labelText: 'ID perfil Firebase',
                hintText: 'Opcional para vincular login trabajador',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaActivoTrabajador,
              onChanged: (value) =>
                  setState(() => _estaActivoTrabajador = value),
              title: const Text('Trabajador activo'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _ConsumoPersonalFormSheet extends StatefulWidget {
  const _ConsumoPersonalFormSheet({
    required this.trabajadores,
    required this.productos,
  });

  final List<Trabajador> trabajadores;
  final List<Producto> productos;

  @override
  State<_ConsumoPersonalFormSheet> createState() =>
      _ConsumoPersonalFormSheetState();
}

class _ConsumoPersonalFormSheetState extends State<_ConsumoPersonalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _notaController = TextEditingController();
  late Trabajador _trabajador;
  late Producto _producto;

  @override
  void initState() {
    super.initState();
    _trabajador = widget.trabajadores.first;
    _producto = widget.productos.first;
    _montoController.text = _producto.precioProducto.toString();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      ConsumoPersonal(
        idConsumoPersonal: '',
        idTrabajador: _trabajador.idTrabajador,
        idProducto: _producto.idProducto,
        nombreProductoSnapshot: _producto.nombreProducto,
        montoConsumoPersonal: int.parse(_montoController.text.trim()),
        fechaConsumoPersonal: DateTime.now(),
        notaConsumoPersonal: _notaController.text.trim(),
        estaAnuladoConsumoPersonal: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Consumo personal',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<Trabajador>(
              initialValue: _trabajador,
              decoration: const InputDecoration(labelText: 'Trabajador'),
              items: [
                for (final trabajador in widget.trabajadores)
                  DropdownMenuItem(
                    value: trabajador,
                    child: Text(trabajador.nombreTrabajador),
                  ),
              ],
              onChanged: (value) => setState(() => _trabajador = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Producto>(
              initialValue: _producto,
              decoration: const InputDecoration(labelText: 'Producto'),
              items: [
                for (final producto in widget.productos)
                  DropdownMenuItem(
                    value: producto,
                    child: Text(producto.nombreProducto),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _producto = value!;
                  _montoController.text = _producto.precioProducto.toString();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Valor a descontar',
                hintText: 'Ej: 3500',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _AsistenciaEditFormSheet extends StatefulWidget {
  const _AsistenciaEditFormSheet({required this.asistencia});

  final Asistencia asistencia;

  @override
  State<_AsistenciaEditFormSheet> createState() =>
      _AsistenciaEditFormSheetState();
}

class _AsistenciaEditFormSheetState extends State<_AsistenciaEditFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutosTrabajadosController;
  late final TextEditingController _minutosExtraController;
  late final TextEditingController _minutosAtrasoController;
  late final TextEditingController _observacionController;
  late bool _estaAnuladaAsistencia;

  @override
  void initState() {
    super.initState();
    final asistencia = widget.asistencia;
    _minutosTrabajadosController = TextEditingController(
      text: asistencia.minutosTrabajados.toString(),
    );
    _minutosExtraController = TextEditingController(
      text: asistencia.minutosExtra.toString(),
    );
    _minutosAtrasoController = TextEditingController(
      text: asistencia.minutosAtraso.toString(),
    );
    _observacionController = TextEditingController(
      text: asistencia.observacionAsistencia,
    );
    _estaAnuladaAsistencia = asistencia.estaAnuladaAsistencia;
  }

  @override
  void dispose() {
    _minutosTrabajadosController.dispose();
    _minutosExtraController.dispose();
    _minutosAtrasoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      widget.asistencia.copyWith(
        minutosTrabajados: int.parse(_minutosTrabajadosController.text.trim()),
        minutosExtra: int.parse(_minutosExtraController.text.trim()),
        minutosAtraso: int.parse(_minutosAtrasoController.text.trim()),
        observacionAsistencia: _observacionController.text.trim(),
        estaCorregidaAsistencia: true,
        estaAnuladaAsistencia: _estaAnuladaAsistencia,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Corregir asistencia',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _minutosTrabajadosController,
              decoration: const InputDecoration(
                labelText: 'Minutos trabajados',
                hintText: 'Ej: 480',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _nonNegativeNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minutosExtraController,
              decoration: const InputDecoration(
                labelText: 'Minutos extra',
                hintText: 'Ej: 30',
                prefixIcon: Icon(Icons.more_time_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _nonNegativeNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minutosAtrasoController,
              decoration: const InputDecoration(
                labelText: 'Minutos atraso',
                hintText: 'Ej: 10',
                prefixIcon: Icon(Icons.alarm_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _nonNegativeNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionController,
              decoration: const InputDecoration(
                labelText: 'Observacion',
                hintText: 'Motivo de la correccion',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaAnuladaAsistencia,
              onChanged: (value) =>
                  setState(() => _estaAnuladaAsistencia = value),
              title: const Text('Anular asistencia'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _ConsumoEditFormSheet extends StatefulWidget {
  const _ConsumoEditFormSheet({
    required this.consumo,
    required this.usuarios,
    required this.productos,
  });

  final Consumo consumo;
  final List<Usuario> usuarios;
  final List<Producto> productos;

  @override
  State<_ConsumoEditFormSheet> createState() => _ConsumoEditFormSheetState();
}

class _ConsumoEditFormSheetState extends State<_ConsumoEditFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidadController;
  late final TextEditingController _notaController;
  late Usuario _usuario;
  late Producto _producto;

  @override
  void initState() {
    super.initState();
    final consumo = widget.consumo;
    _usuario = widget.usuarios.firstWhere(
      (usuario) => usuario.idUsuario == consumo.idUsuario,
      orElse: () => widget.usuarios.first,
    );
    _producto = widget.productos.firstWhere(
      (producto) => producto.idProducto == consumo.idProducto,
      orElse: () => Producto(
        idProducto: consumo.idProducto,
        nombreProducto: consumo.nombreProductoSnapshot,
        nombreCategoriaProducto: 'Historial',
        precioProducto: consumo.precioProductoSnapshot,
        estaActivoProducto: true,
        esProductoFrecuente: false,
      ),
    );
    _cantidadController = TextEditingController(
      text: consumo.cantidadConsumo.toString(),
    );
    _notaController = TextEditingController(text: consumo.notaConsumo);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      widget.consumo.copyWith(
        idUsuario: _usuario.idUsuario,
        idProducto: _producto.idProducto,
        nombreProductoSnapshot: _producto.nombreProducto,
        precioProductoSnapshot: _producto.precioProducto,
        cantidadConsumo: int.parse(_cantidadController.text.trim()),
        notaConsumo: _notaController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Editar consumo',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<Usuario>(
              initialValue: _usuario,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                for (final usuario in widget.usuarios)
                  DropdownMenuItem(
                    value: usuario,
                    child: Text(usuario.nombreUsuario),
                  ),
              ],
              onChanged: (value) => setState(() => _usuario = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Producto>(
              initialValue: _producto,
              decoration: const InputDecoration(labelText: 'Producto'),
              items: [
                if (!widget.productos.contains(_producto))
                  DropdownMenuItem(
                    value: _producto,
                    child: Text(_producto.nombreProducto),
                  ),
                for (final producto in widget.productos)
                  DropdownMenuItem(
                    value: producto,
                    child: Text(producto.nombreProducto),
                  ),
              ],
              onChanged: (value) => setState(() => _producto = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej: 2',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota del consumo',
                hintText: 'Agregue una nota opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _ConsumoFormSheet extends StatefulWidget {
  const _ConsumoFormSheet({
    required this.usuarios,
    required this.productos,
    this.usuarioInicial,
  });

  final List<Usuario> usuarios;
  final List<Producto> productos;
  final Usuario? usuarioInicial;

  @override
  State<_ConsumoFormSheet> createState() => _ConsumoFormSheetState();
}

class _ConsumoFormSheetState extends State<_ConsumoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController(text: '1');
  final _notaController = TextEditingController();
  final List<_ConsumoDraftLine> _lineas = [];
  late Usuario _usuario;
  late Producto _producto;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioInicial == null
        ? widget.usuarios.first
        : widget.usuarios.firstWhere(
            (usuario) => usuario.idUsuario == widget.usuarioInicial!.idUsuario,
            orElse: () => widget.usuarios.first,
          );
    _producto = widget.productos.first;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  int get _totalCarga {
    return _lineas.fold(0, (total, linea) => total + linea.total);
  }

  void _agregarProducto() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = int.parse(_cantidadController.text.trim());
    final index = _lineas.indexWhere(
      (linea) => linea.producto.idProducto == _producto.idProducto,
    );

    setState(() {
      if (index == -1) {
        _lineas.add(_ConsumoDraftLine(producto: _producto, cantidad: cantidad));
      } else {
        final linea = _lineas[index];
        _lineas[index] = linea.copyWith(cantidad: linea.cantidad + cantidad);
      }
      _cantidadController.text = '1';
    });
  }

  void _cambiarCantidad(_ConsumoDraftLine linea, int cantidad) {
    if (cantidad <= 0) {
      _quitarProducto(linea);
      return;
    }

    setState(() {
      final index = _lineas.indexOf(linea);
      _lineas[index] = linea.copyWith(cantidad: cantidad);
    });
  }

  void _quitarProducto(_ConsumoDraftLine linea) {
    setState(() => _lineas.remove(linea));
  }

  void _submit() {
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto a la carga.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fechaCarga = DateTime.now();
    final nota = _notaController.text.trim();

    Navigator.of(context).pop([
      for (final linea in _lineas)
        Consumo(
          idConsumo: '',
          idUsuario: _usuario.idUsuario,
          idProducto: linea.producto.idProducto,
          nombreProductoSnapshot: linea.producto.nombreProducto,
          precioProductoSnapshot: linea.producto.precioProducto,
          cantidadConsumo: linea.cantidad,
          fechaConsumo: fechaCarga,
          notaConsumo: nota,
          estaAnuladoConsumo: false,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Nueva carga',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Usuario>(
              initialValue: _usuario,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                for (final usuario in widget.usuarios)
                  DropdownMenuItem(
                    value: usuario,
                    child: Text(usuario.nombreUsuario),
                  ),
              ],
              onChanged: (value) => setState(() => _usuario = value!),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Producto>(
                    initialValue: _producto,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: [
                      for (final producto in widget.productos)
                        DropdownMenuItem(
                          value: producto,
                          child: Text(producto.nombreProducto),
                        ),
                    ],
                    onChanged: (value) => setState(() => _producto = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cant.',
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    validator: _positiveNumberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar producto'),
            ),
            const SizedBox(height: 14),
            _ConsumoDraftSummary(
              lineas: _lineas,
              total: _totalCarga,
              onDecrease: (linea) =>
                  _cambiarCantidad(linea, linea.cantidad - 1),
              onIncrease: (linea) =>
                  _cambiarCantidad(linea, linea.cantidad + 1),
              onRemove: _quitarProducto,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota de la carga',
                hintText: 'Agregue una nota opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit, label: 'Guardar carga'),
          ],
        ),
      ),
    );
  }
}

class _ConsumoDraftLine {
  const _ConsumoDraftLine({required this.producto, required this.cantidad});

  final Producto producto;
  final int cantidad;

  int get total => producto.precioProducto * cantidad;

  _ConsumoDraftLine copyWith({int? cantidad}) {
    return _ConsumoDraftLine(
      producto: producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

class _ConsumoDraftSummary extends StatelessWidget {
  const _ConsumoDraftSummary({
    required this.lineas,
    required this.total,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final List<_ConsumoDraftLine> lineas;
  final int total;
  final ValueChanged<_ConsumoDraftLine> onDecrease;
  final ValueChanged<_ConsumoDraftLine> onIncrease;
  final ValueChanged<_ConsumoDraftLine> onRemove;

  @override
  Widget build(BuildContext context) {
    if (lineas.isEmpty) {
      return const _EmptyState(
        icon: Icons.playlist_add_rounded,
        title: 'Sin productos en la carga',
        message: 'Selecciona un producto, define la cantidad y agregalo.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: KutralKoColors.carbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.26)),
      ),
      child: Column(
        children: [
          for (final linea in lineas)
            _ConsumoDraftTile(
              linea: linea,
              onDecrease: () => onDecrease(linea),
              onIncrease: () => onIncrease(linea),
              onRemove: () => onRemove(linea),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total de la carga',
                    style: TextStyle(
                      color: KutralKoColors.smoke,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.clp(total),
                  style: const TextStyle(
                    color: KutralKoColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumoDraftTile extends StatelessWidget {
  const _ConsumoDraftTile({
    required this.linea,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final _ConsumoDraftLine linea;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.producto.nombreProducto,
                  style: const TextStyle(
                    color: KutralKoColors.ivory,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.clp(linea.producto.precioProducto)} c/u',
                  style: const TextStyle(
                    color: KutralKoColors.smoke,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Restar',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
            color: KutralKoColors.smoke,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${linea.cantidad}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KutralKoColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sumar',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
            color: KutralKoColors.smoke,
          ),
          IconButton(
            tooltip: 'Quitar',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: KutralKoColors.gold,
          ),
        ],
      ),
    );
  }
}

class _PagoEditFormSheet extends StatefulWidget {
  const _PagoEditFormSheet({required this.pago, required this.usuarios});

  final Pago pago;
  final List<Usuario> usuarios;

  @override
  State<_PagoEditFormSheet> createState() => _PagoEditFormSheetState();
}

class _PagoEditFormSheetState extends State<_PagoEditFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montoController;
  late final TextEditingController _metodoController;
  late final TextEditingController _notaController;
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    final pago = widget.pago;
    _usuario = widget.usuarios.firstWhere(
      (usuario) => usuario.idUsuario == pago.idUsuario,
      orElse: () => widget.usuarios.first,
    );
    _montoController = TextEditingController(text: pago.montoPago.toString());
    _metodoController = TextEditingController(text: pago.metodoPago);
    _notaController = TextEditingController(text: pago.notaPago);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _metodoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      widget.pago.copyWith(
        idUsuario: _usuario.idUsuario,
        montoPago: int.parse(_montoController.text.trim()),
        metodoPago: _metodoController.text.trim(),
        notaPago: _notaController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Editar pago',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<Usuario>(
              initialValue: _usuario,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                for (final usuario in widget.usuarios)
                  DropdownMenuItem(
                    value: usuario,
                    child: Text(usuario.nombreUsuario),
                  ),
              ],
              onChanged: (value) => setState(() => _usuario = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto pagado',
                hintText: 'Ej: 25000',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _metodoController,
              decoration: const InputDecoration(
                labelText: 'Metodo de pago',
                hintText: 'Ej: Transferencia',
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota del pago',
                hintText: 'Agregue una nota opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _PagoFormSheet extends StatefulWidget {
  const _PagoFormSheet({required this.usuarios, this.usuarioInicial});

  final List<Usuario> usuarios;
  final Usuario? usuarioInicial;

  @override
  State<_PagoFormSheet> createState() => _PagoFormSheetState();
}

class _PagoFormSheetState extends State<_PagoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _metodoController = TextEditingController(text: 'Transferencia');
  final _notaController = TextEditingController();
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioInicial == null
        ? widget.usuarios.first
        : widget.usuarios.firstWhere(
            (usuario) => usuario.idUsuario == widget.usuarioInicial!.idUsuario,
            orElse: () => widget.usuarios.first,
          );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _metodoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Pago(
        idPago: '',
        idUsuario: _usuario.idUsuario,
        montoPago: int.parse(_montoController.text.trim()),
        metodoPago: _metodoController.text.trim(),
        fechaPago: DateTime.now(),
        notaPago: _notaController.text.trim(),
        estaAnuladoPago: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Nuevo pago',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<Usuario>(
              initialValue: _usuario,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: [
                for (final usuario in widget.usuarios)
                  DropdownMenuItem(
                    value: usuario,
                    child: Text(usuario.nombreUsuario),
                  ),
              ],
              onChanged: (value) => setState(() => _usuario = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto pagado',
                hintText: 'Ej: 25000',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _metodoController,
              decoration: const InputDecoration(
                labelText: 'Metodo de pago',
                hintText: 'Ej: Transferencia',
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota del pago',
                hintText: 'Agregue una nota opcional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _SubmitButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onPressed, this.label = 'Guardar'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded),
        label: Text(label),
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Campo requerido';
  }
  return null;
}

String? _positiveNumberValidator(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) {
    return 'Ingresa un numero mayor a cero';
  }
  return null;
}

String? _nonNegativeNumberValidator(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  if (number == null || number < 0) {
    return 'Ingresa un numero igual o mayor a cero';
  }
  return null;
}

String _formatMinutes(int minutes) {
  final safeMinutes = minutes < 0 ? 0 : minutes;
  final hours = safeMinutes ~/ 60;
  final remainingMinutes = safeMinutes % 60;
  return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _monthLabel(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${months[date.month - 1]} ${date.year}';
}
