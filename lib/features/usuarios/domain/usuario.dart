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

  Usuario copyWith({
    String? idUsuario,
    String? nombreUsuario,
    String? telefonoUsuario,
    String? notaUsuario,
    bool? estaActivoUsuario,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      telefonoUsuario: telefonoUsuario ?? this.telefonoUsuario,
      notaUsuario: notaUsuario ?? this.notaUsuario,
      estaActivoUsuario: estaActivoUsuario ?? this.estaActivoUsuario,
    );
  }
}
