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
}
