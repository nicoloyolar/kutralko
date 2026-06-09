class ConsumoPersonal {
  const ConsumoPersonal({
    required this.idConsumoPersonal,
    required this.idTrabajador,
    required this.idProducto,
    required this.nombreProductoSnapshot,
    required this.montoConsumoPersonal,
    required this.fechaConsumoPersonal,
    required this.notaConsumoPersonal,
    required this.estaAnuladoConsumoPersonal,
  });

  final String idConsumoPersonal;
  final String idTrabajador;
  final String idProducto;
  final String nombreProductoSnapshot;
  final int montoConsumoPersonal;
  final DateTime fechaConsumoPersonal;
  final String notaConsumoPersonal;
  final bool estaAnuladoConsumoPersonal;

  ConsumoPersonal copyWith({
    String? idConsumoPersonal,
    String? idTrabajador,
    String? idProducto,
    String? nombreProductoSnapshot,
    int? montoConsumoPersonal,
    DateTime? fechaConsumoPersonal,
    String? notaConsumoPersonal,
    bool? estaAnuladoConsumoPersonal,
  }) {
    return ConsumoPersonal(
      idConsumoPersonal: idConsumoPersonal ?? this.idConsumoPersonal,
      idTrabajador: idTrabajador ?? this.idTrabajador,
      idProducto: idProducto ?? this.idProducto,
      nombreProductoSnapshot:
          nombreProductoSnapshot ?? this.nombreProductoSnapshot,
      montoConsumoPersonal: montoConsumoPersonal ?? this.montoConsumoPersonal,
      fechaConsumoPersonal: fechaConsumoPersonal ?? this.fechaConsumoPersonal,
      notaConsumoPersonal: notaConsumoPersonal ?? this.notaConsumoPersonal,
      estaAnuladoConsumoPersonal:
          estaAnuladoConsumoPersonal ?? this.estaAnuladoConsumoPersonal,
    );
  }
}
