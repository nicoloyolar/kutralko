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

  Consumo copyWith({
    String? idConsumo,
    String? idUsuario,
    String? idProducto,
    String? nombreProductoSnapshot,
    int? precioProductoSnapshot,
    int? cantidadConsumo,
    DateTime? fechaConsumo,
    String? notaConsumo,
    bool? estaAnuladoConsumo,
  }) {
    return Consumo(
      idConsumo: idConsumo ?? this.idConsumo,
      idUsuario: idUsuario ?? this.idUsuario,
      idProducto: idProducto ?? this.idProducto,
      nombreProductoSnapshot:
          nombreProductoSnapshot ?? this.nombreProductoSnapshot,
      precioProductoSnapshot:
          precioProductoSnapshot ?? this.precioProductoSnapshot,
      cantidadConsumo: cantidadConsumo ?? this.cantidadConsumo,
      fechaConsumo: fechaConsumo ?? this.fechaConsumo,
      notaConsumo: notaConsumo ?? this.notaConsumo,
      estaAnuladoConsumo: estaAnuladoConsumo ?? this.estaAnuladoConsumo,
    );
  }
}
