import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../productos/domain/producto.dart';
import '../../usuarios/domain/usuario.dart';
import 'dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeView(),
      const _UsuariosView(),
      const _ProductosView(),
      const _MovimientosView(),
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
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

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final totalConsumido = DashboardData.usuarios.fold(
      0,
      (total, usuario) =>
          total + DashboardData.totalConsumidoUsuario(usuario.idUsuario),
    );
    final totalPagado = DashboardData.usuarios.fold(
      0,
      (total, usuario) =>
          total + DashboardData.totalPagadoUsuario(usuario.idUsuario),
    );
    final saldoPendiente = totalConsumido - totalPagado;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _BalanceHero(
          saldoPendiente: saldoPendiente,
          totalConsumido: totalConsumido,
          totalPagado: totalPagado,
        ),
        const SizedBox(height: 16),
        const _QuickActions(),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Clientes activos', action: 'Ver todos'),
        const SizedBox(height: 12),
        for (final usuario in DashboardData.usuarios) _UsuarioTile(usuario),
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
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Consumo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.payments_rounded),
            label: const Text('Pago'),
          ),
        ),
      ],
    );
  }
}

class _UsuariosView extends StatelessWidget {
  const _UsuariosView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SectionHeader(title: 'Clientes', action: 'Nuevo'),
        const SizedBox(height: 12),
        for (final usuario in DashboardData.usuarios) _UsuarioTile(usuario),
      ],
    );
  }
}

class _ProductosView extends StatelessWidget {
  const _ProductosView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SectionHeader(title: 'Carta editable', action: 'Producto'),
        const SizedBox(height: 12),
        for (final producto in DashboardData.productos) _ProductoTile(producto),
      ],
    );
  }
}

class _MovimientosView extends StatelessWidget {
  const _MovimientosView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SectionHeader(title: 'Cuenta mensual', action: 'Cerrar mes'),
        const SizedBox(height: 12),
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
                for (final consumo in DashboardData.consumos)
                  _MovementRow(
                    icon: Icons.restaurant_menu_rounded,
                    title: consumo.nombreProductoSnapshot,
                    detail: '${consumo.cantidadConsumo} unidad(es)',
                    amount: CurrencyFormatter.clp(consumo.totalConsumo),
                    color: KutralKoColors.orange,
                  ),
                for (final pago in DashboardData.pagos)
                  _MovementRow(
                    icon: Icons.payments_rounded,
                    title: pago.metodoPago,
                    detail: pago.notaPago,
                    amount: '-${CurrencyFormatter.clp(pago.montoPago)}',
                    color: KutralKoColors.success,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

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
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  const _UsuarioTile(this.usuario);

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final saldo = DashboardData.saldoUsuario(usuario.idUsuario);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: KutralKoColors.smoke,
          foregroundColor: KutralKoColors.carbon,
          child: Text(
            usuario.nombreUsuario.characters.first.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          usuario.nombreUsuario,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          usuario.notaUsuario,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
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
        ),
      ),
    );
  }
}

class _ProductoTile extends StatelessWidget {
  const _ProductoTile(this.producto);

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: KutralKoColors.gold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.local_dining_rounded,
            color: KutralKoColors.carbon,
          ),
        ),
        title: Text(
          producto.nombreProducto,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(producto.nombreCategoriaProducto),
        trailing: Text(
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
