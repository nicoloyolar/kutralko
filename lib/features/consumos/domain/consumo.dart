class Consumo {
  const Consumo({
    required this.idConsumo,
    required this.idUsuario,
    required this.idProducto,
    required this.nombreProductoSnapshot,
    required this.precioProductoSnapshot,
    required this.cantidadConsumo,
    required this.fechaConsumo,
    required this.notaConsumo,
    required this.estaAnuladoConsumo,
  });

  final String idConsumo;
  final String idUsuario;
  final String idProducto;
  final String nombreProductoSnapshot;
  final int precioProductoSnapshot;
  final int cantidadConsumo;
  final DateTime fechaConsumo;
  final String notaConsumo;
  final bool estaAnuladoConsumo;

  int get totalConsumo => precioProductoSnapshot * cantidadConsumo;
}
