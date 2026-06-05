class Pago {
  const Pago({
    required this.idPago,
    required this.idUsuario,
    required this.montoPago,
    required this.metodoPago,
    required this.fechaPago,
    required this.notaPago,
    required this.estaAnuladoPago,
  });

  final String idPago;
  final String idUsuario;
  final int montoPago;
  final String metodoPago;
  final DateTime fechaPago;
  final String notaPago;
  final bool estaAnuladoPago;

  Pago copyWith({
    String? idPago,
    String? idUsuario,
    int? montoPago,
    String? metodoPago,
    DateTime? fechaPago,
    String? notaPago,
    bool? estaAnuladoPago,
  }) {
    return Pago(
      idPago: idPago ?? this.idPago,
      idUsuario: idUsuario ?? this.idUsuario,
      montoPago: montoPago ?? this.montoPago,
      metodoPago: metodoPago ?? this.metodoPago,
      fechaPago: fechaPago ?? this.fechaPago,
      notaPago: notaPago ?? this.notaPago,
      estaAnuladoPago: estaAnuladoPago ?? this.estaAnuladoPago,
    );
  }
}
