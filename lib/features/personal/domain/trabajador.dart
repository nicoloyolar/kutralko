class Trabajador {
  const Trabajador({
    required this.idTrabajador,
    required this.nombreTrabajador,
    required this.emailTrabajador,
    required this.telefonoTrabajador,
    required this.cargoTrabajador,
    required this.estaActivoTrabajador,
    required this.idPerfil,
  });

  final String idTrabajador;
  final String nombreTrabajador;
  final String emailTrabajador;
  final String telefonoTrabajador;
  final String cargoTrabajador;
  final bool estaActivoTrabajador;
  final String idPerfil;

  Trabajador copyWith({
    String? idTrabajador,
    String? nombreTrabajador,
    String? emailTrabajador,
    String? telefonoTrabajador,
    String? cargoTrabajador,
    bool? estaActivoTrabajador,
    String? idPerfil,
  }) {
    return Trabajador(
      idTrabajador: idTrabajador ?? this.idTrabajador,
      nombreTrabajador: nombreTrabajador ?? this.nombreTrabajador,
      emailTrabajador: emailTrabajador ?? this.emailTrabajador,
      telefonoTrabajador: telefonoTrabajador ?? this.telefonoTrabajador,
      cargoTrabajador: cargoTrabajador ?? this.cargoTrabajador,
      estaActivoTrabajador: estaActivoTrabajador ?? this.estaActivoTrabajador,
      idPerfil: idPerfil ?? this.idPerfil,
    );
  }
}
