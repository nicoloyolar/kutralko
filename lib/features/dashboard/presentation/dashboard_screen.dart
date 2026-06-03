import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/data/kutral_ko_repository.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../consumos/domain/consumo.dart';
import '../../pagos/domain/pago.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';

enum _PerfilActivo { administrador, cliente }

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
  final List<StreamSubscription<Object?>> _subscriptions = [];

  int _selectedIndex = 0;
  _PerfilActivo _perfilActivo = _PerfilActivo.administrador;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(
        widget.repository.watchUsuarios().listen((usuarios) {
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
        widget.repository.watchConsumos().listen((consumos) {
          setState(() {
            _consumos
              ..clear()
              ..addAll(consumos);
          });
        }, onError: _handleStreamError),
      )
      ..add(
        widget.repository.watchPagos().listen((pagos) {
          setState(() {
            _pagos
              ..clear()
              ..addAll(pagos);
          });
        }, onError: _handleStreamError),
      );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  int get _totalConsumido {
    return _usuarios.fold(0, (total, usuario) {
      return total + _totalConsumidoUsuario(usuario.idUsuario);
    });
  }

  int get _totalPagado {
    return _usuarios.fold(0, (total, usuario) {
      return total + _totalPagadoUsuario(usuario.idUsuario);
    });
  }

  int get _saldoPendiente => _totalConsumido - _totalPagado;

  List<Usuario> get _usuariosActivos {
    return _usuarios.where((usuario) => usuario.estaActivoUsuario).toList();
  }

  List<Producto> get _productosActivos {
    return _productos.where((producto) => producto.estaActivoProducto).toList();
  }

  int _totalConsumidoUsuario(String idUsuario) {
    return _consumos
        .where(
          (consumo) =>
              consumo.idUsuario == idUsuario && !consumo.estaAnuladoConsumo,
        )
        .fold(0, (total, consumo) => total + consumo.totalConsumo);
  }

  int _totalPagadoUsuario(String idUsuario) {
    return _pagos
        .where((pago) => pago.idUsuario == idUsuario && !pago.estaAnuladoPago)
        .fold(0, (total, pago) => total + pago.montoPago);
  }

  int _saldoUsuario(String idUsuario) {
    return _totalConsumidoUsuario(idUsuario) - _totalPagadoUsuario(idUsuario);
  }

  bool get _puedeAdministrar {
    return _perfilActivo == _PerfilActivo.administrador;
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

  Future<void> _openConsumoForm() async {
    if (_usuariosActivos.isEmpty || _productosActivos.isEmpty) {
      _showSnack('Necesitas al menos un cliente y un producto activos.');
      return;
    }

    final result = await showModalBottomSheet<Consumo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ConsumoFormSheet(
        usuarios: _usuariosActivos,
        productos: _productosActivos,
      ),
    );

    if (result == null) {
      return;
    }

    await _save(() => widget.repository.guardarConsumo(result));
  }

  Future<void> _openPagoForm() async {
    if (_usuariosActivos.isEmpty) {
      _showSnack('Necesitas al menos un cliente activo.');
      return;
    }

    final result = await showModalBottomSheet<Pago>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PagoFormSheet(usuarios: _usuariosActivos),
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeView(
        usuarios: _usuarios,
        saldoPendiente: _saldoPendiente,
        totalConsumido: _totalConsumido,
        totalPagado: _totalPagado,
        saldoUsuario: _saldoUsuario,
        onNuevoConsumo: _puedeAdministrar ? _openConsumoForm : null,
        onNuevoPago: _puedeAdministrar ? _openPagoForm : null,
      ),
      _UsuariosView(
        usuarios: _usuarios,
        saldoUsuario: _saldoUsuario,
        puedeAdministrar: _puedeAdministrar,
        onNuevoUsuario: _puedeAdministrar ? () => _openUsuarioForm() : null,
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
        consumos: _consumos,
        pagos: _pagos,
        puedeAdministrar: _puedeAdministrar,
        onNuevoConsumo: _puedeAdministrar ? _openConsumoForm : null,
        onNuevoPago: _puedeAdministrar ? _openPagoForm : null,
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
                    color: KutralKoColors.muted,
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
            tooltip: 'Ajustes',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PerfilBar(
              perfilActivo: _perfilActivo,
              onChanged: (perfil) => setState(() => _perfilActivo = perfil),
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

class _PerfilBar extends StatelessWidget {
  const _PerfilBar({required this.perfilActivo, required this.onChanged});

  final _PerfilActivo perfilActivo;
  final ValueChanged<_PerfilActivo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SegmentedButton<_PerfilActivo>(
        segments: const [
          ButtonSegment(
            value: _PerfilActivo.administrador,
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: Text('Admin'),
          ),
          ButtonSegment(
            value: _PerfilActivo.cliente,
            icon: Icon(Icons.person_rounded),
            label: Text('Cliente'),
          ),
        ],
        selected: {perfilActivo},
        onSelectionChanged: (values) => onChanged(values.first),
        showSelectedIcon: false,
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
    required this.onNuevoConsumo,
    required this.onNuevoPago,
  });

  final List<Usuario> usuarios;
  final int saldoPendiente;
  final int totalConsumido;
  final int totalPagado;
  final int Function(String idUsuario) saldoUsuario;
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
            message: 'Crea el primer cliente para empezar a registrar cuenta.',
          )
        else
          for (final usuario in usuarios.where(
            (item) => item.estaActivoUsuario,
          ))
            _UsuarioTile(
              usuario: usuario,
              saldo: saldoUsuario(usuario.idUsuario),
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
  });

  final int saldoPendiente;
  final int totalConsumido;
  final int totalPagado;

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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: KutralKoColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Junio 2026',
                  style: TextStyle(
                    color: KutralKoColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
            label: const Text('Consumo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNuevoPago,
            icon: const Icon(Icons.payments_rounded),
            label: const Text('Pago'),
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
    required this.onEditarUsuario,
    required this.onToggleUsuario,
  });

  final List<Usuario> usuarios;
  final int Function(String idUsuario) saldoUsuario;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoUsuario;
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
            message: 'Agrega clientes o convenios internos para operar.',
          )
        else
          for (final usuario in usuarios)
            _UsuarioTile(
              usuario: usuario,
              saldo: saldoUsuario(usuario.idUsuario),
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
            message: 'Crea los productos frecuentes de carta o barra.',
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
    required this.consumos,
    required this.pagos,
    required this.puedeAdministrar,
    required this.onNuevoConsumo,
    required this.onNuevoPago,
  });

  final List<Consumo> consumos;
  final List<Pago> pagos;
  final bool puedeAdministrar;
  final VoidCallback? onNuevoConsumo;
  final VoidCallback? onNuevoPago;

  @override
  Widget build(BuildContext context) {
    final hasMovimientos = consumos.isNotEmpty || pagos.isNotEmpty;

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
                  label: const Text('Consumo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNuevoPago,
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Pago'),
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
                  for (final consumo in consumos)
                    _MovementRow(
                      icon: Icons.restaurant_menu_rounded,
                      title: consumo.nombreProductoSnapshot,
                      detail: '${consumo.cantidadConsumo} unidad(es)',
                      amount: CurrencyFormatter.clp(consumo.totalConsumo),
                      color: KutralKoColors.orange,
                    ),
                  for (final pago in pagos)
                    _MovementRow(
                      icon: Icons.payments_rounded,
                      title: pago.metodoPago,
                      detail: pago.notaPago.isEmpty
                          ? pago.idUsuario
                          : pago.notaPago,
                      amount: '-${CurrencyFormatter.clp(pago.montoPago)}',
                      color: KutralKoColors.success,
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
    this.onEdit,
    this.onToggle,
  });

  final Usuario usuario;
  final int saldo;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = usuario.estaActivoUsuario
        ? KutralKoColors.carbon
        : KutralKoColors.muted;

    return Card(
      child: ListTile(
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
  });

  final IconData icon;
  final String title;
  final String detail;
  final String amount;
  final Color color;

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
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)),
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
                labelText: 'nombreUsuario',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'telefonoUsuario',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'notaUsuario',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaActivoUsuario,
              onChanged: (value) => setState(() => _estaActivoUsuario = value),
              title: const Text('estaActivoUsuario'),
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
                labelText: 'nombreProducto',
                prefixIcon: Icon(Icons.local_dining_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(
                labelText: 'nombreCategoriaProducto',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'precioProducto',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _estaActivoProducto,
              onChanged: (value) => setState(() => _estaActivoProducto = value),
              title: const Text('estaActivoProducto'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _esProductoFrecuente,
              onChanged: (value) =>
                  setState(() => _esProductoFrecuente = value),
              title: const Text('esProductoFrecuente'),
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

class _ConsumoFormSheet extends StatefulWidget {
  const _ConsumoFormSheet({required this.usuarios, required this.productos});

  final List<Usuario> usuarios;
  final List<Producto> productos;

  @override
  State<_ConsumoFormSheet> createState() => _ConsumoFormSheetState();
}

class _ConsumoFormSheetState extends State<_ConsumoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController(text: '1');
  final _notaController = TextEditingController();
  late Usuario _usuario;
  late Producto _producto;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarios.first;
    _producto = widget.productos.first;
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
      Consumo(
        idConsumo: '',
        idUsuario: _usuario.idUsuario,
        idProducto: _producto.idProducto,
        nombreProductoSnapshot: _producto.nombreProducto,
        precioProductoSnapshot: _producto.precioProducto,
        cantidadConsumo: int.parse(_cantidadController.text.trim()),
        fechaConsumo: DateTime.now(),
        notaConsumo: _notaController.text.trim(),
        estaAnuladoConsumo: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Nuevo consumo',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<Usuario>(
              initialValue: _usuario,
              decoration: const InputDecoration(labelText: 'idUsuario'),
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
              decoration: const InputDecoration(labelText: 'idProducto'),
              items: [
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
                labelText: 'cantidadConsumo',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'notaConsumo',
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
  const _PagoFormSheet({required this.usuarios});

  final List<Usuario> usuarios;

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
    _usuario = widget.usuarios.first;
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
              decoration: const InputDecoration(labelText: 'idUsuario'),
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
                labelText: 'montoPago',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: _positiveNumberValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _metodoController,
              decoration: const InputDecoration(
                labelText: 'metodoPago',
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'notaPago',
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
  const _SubmitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Guardar'),
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
