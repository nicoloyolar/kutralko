class Usuario {
  const Usuario({
    required this.idUsuario,
    required this.nombreUsuario,
    required this.telefonoUsuario,
    required this.notaUsuario,
    required this.estaActivoUsuario,
  });

  final String idUsuario;
  final String nombreUsuario;
  final String telefonoUsuario;
  final String notaUsuario;
  final bool estaActivoUsuario;
}
