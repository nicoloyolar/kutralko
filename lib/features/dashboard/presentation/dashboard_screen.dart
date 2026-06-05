import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/data/kutral_ko_repository.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../consumos/domain/consumo.dart';
import '../../pagos/domain/pago.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final KutralKoRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Usuario> _usuarios = [];
  final List<Producto> _productos = [];
  final List<Consumo> _consumos = [];
  final List<Pago> _pagos = [];
  final List<StreamSubscription<dynamic>> _dataSubscriptions = [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _perfilSubscription;

  int _selectedIndex = 0;
  bool _isPerfilLoading = true;
  String _rolPerfil = 'cliente';
  String _emailPerfil = '';
  String? _idUsuarioPerfil;
  late DateTime _mesSeleccionado;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSeleccionado = DateTime(now.year, now.month);
    _watchPerfil();
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
        .listen((snapshot) {
          final data = snapshot.data() ?? {};
          final rolPerfil = data['rolPerfil'] as String? ?? 'cliente';
          final idUsuarioPerfil = data['idUsuarioPerfil'] as String?;
          setState(() {
            _rolPerfil = rolPerfil;
            _emailPerfil = data['emailPerfil'] as String? ?? user.email ?? '';
            _idUsuarioPerfil = idUsuarioPerfil;
            _isPerfilLoading = false;
          });
          _restartDataStreams(
            idUsuario: rolPerfil == 'administrador' ? null : idUsuarioPerfil,
          );
        }, onError: (error) {
          setState(() => _isPerfilLoading = false);
          _handleStreamError(error);
        });
  }

  @override
  void dispose() {
    _perfilSubscription?.cancel();
    for (final subscription in _dataSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _restartDataStreams({required String? idUsuario}) {
    for (final subscription in _dataSubscriptions) {
      subscription.cancel();
    }
    _dataSubscriptions.clear();

    setState(() {
      _usuarios.clear();
      _productos.clear();
      _consumos.clear();
      _pagos.clear();
    });

    if (!_puedeAdministrar && (idUsuario == null || idUsuario.isEmpty)) {
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
        widget.repository.watchUsuarios(idUsuario: idUsuario).listen((usuarios) {
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
        widget.repository.watchConsumos(idUsuario: idUsuario).listen((consumos) {
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

    return _usuarios.where((usuario) => usuario.idUsuario == idUsuario).toList();
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
      builder: (context) => _PagoEditFormSheet(
        pago: pago,
        usuarios: _usuarios,
      ),
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
      await widget.repository.guardarPago(
        pago.copyWith(estaAnuladoPago: true),
      );
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

  Future<void> _openConfiguracion() async {
    if (!_puedeAdministrar) {
      _showSnack('Solo administradores pueden abrir configuracion.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PerfilLinkSheet(usuarios: _usuarios),
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

  @override
  Widget build(BuildContext context) {
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
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/brand/kutral_ko_logo_refined.png',
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
                  'cuentas mensuales',
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
        child: Column(
          children: [
            _PerfilBanner(
              isLoading: _isPerfilLoading,
              rolPerfil: _rolPerfil,
              emailPerfil: _emailPerfil,
              idUsuarioPerfil: _idUsuarioPerfil,
            ),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_dining_outlined),
            selectedIcon: Icon(Icons.local_dining_rounded),
            label: 'Carta',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Cuenta',
          ),
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
  });

  final bool isLoading;
  final String rolPerfil;
  final String emailPerfil;
  final String? idUsuarioPerfil;

  @override
  Widget build(BuildContext context) {
    final isAdmin = rolPerfil == 'administrador';
    final title = isLoading
        ? 'Verificando perfil'
        : isAdmin
            ? 'Modo administrador'
            : 'Modo cliente';
    final subtitle = isLoading
        ? 'Cargando permisos reales'
        : isAdmin
            ? emailPerfil
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
          border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
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
  const _PerfilLinkSheet({required this.usuarios});

  final List<Usuario> usuarios;

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Vincular clientes',
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
          final perfilesCliente = docs.where((doc) {
            final data = doc.data();
            return data['rolPerfil'] == 'cliente';
          }).toList();

          if (perfilesCliente.isEmpty) {
            return const _EmptyState(
              icon: Icons.person_search_rounded,
              title: 'Sin perfiles cliente',
              message: 'Cuando un cliente cree cuenta, aparecera aqui.',
            );
          }

          return Column(
            children: [
              for (final perfil in perfilesCliente)
                _PerfilLinkTile(
                  perfilId: perfil.id,
                  perfil: perfil.data(),
                  usuarios: usuarios,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PerfilLinkTile extends StatelessWidget {
  const _PerfilLinkTile({
    required this.perfilId,
    required this.perfil,
    required this.usuarios,
  });

  final String perfilId;
  final Map<String, dynamic> perfil;
  final List<Usuario> usuarios;

  @override
  Widget build(BuildContext context) {
    final idUsuarioPerfil = perfil['idUsuarioPerfil'] as String?;
    final selectedUsuario = usuarios.where(
      (usuario) => usuario.idUsuario == idUsuarioPerfil,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              perfil['emailPerfil'] as String? ?? 'Cliente sin correo',
              style: const TextStyle(fontWeight: FontWeight.w900),
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
              onChanged: (idUsuario) {
                FirebaseFirestore.instance
                    .collection('perfiles')
                    .doc(perfilId)
                    .set({'idUsuarioPerfil': idUsuario}, SetOptions(merge: true));
              },
            ),
          ],
        ),
      ),
    );
  }
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
            message: 'Crea los productos de carta o barra para cargar consumos.',
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
            _SubmitButton(
              onPressed: _submit,
              label: 'Guardar carga',
            ),
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
