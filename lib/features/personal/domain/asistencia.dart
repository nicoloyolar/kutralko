class Asistencia {
  const Asistencia({
    required this.idAsistencia,
    required this.idTrabajador,
    required this.fechaAsistencia,
    required this.horaEntrada,
    required this.horaSalida,
    required this.minutosTrabajados,
    required this.minutosExtra,
    required this.minutosAtraso,
    required this.observacionAsistencia,
    required this.estaCorregidaAsistencia,
    required this.estaAnuladaAsistencia,
  });

  final String idAsistencia;
  final String idTrabajador;
  final DateTime fechaAsistencia;
  final DateTime horaEntrada;
  final DateTime? horaSalida;
  final int minutosTrabajados;
  final int minutosExtra;
  final int minutosAtraso;
  final String observacionAsistencia;
  final bool estaCorregidaAsistencia;
  final bool estaAnuladaAsistencia;

  bool get estaAbierta => horaSalida == null && !estaAnuladaAsistencia;

  Asistencia copyWith({
    String? idAsistencia,
    String? idTrabajador,
    DateTime? fechaAsistencia,
    DateTime? horaEntrada,
    DateTime? horaSalida,
    bool clearHoraSalida = false,
    int? minutosTrabajados,
    int? minutosExtra,
    int? minutosAtraso,
    String? observacionAsistencia,
    bool? estaCorregidaAsistencia,
    bool? estaAnuladaAsistencia,
  }) {
    return Asistencia(
      idAsistencia: idAsistencia ?? this.idAsistencia,
      idTrabajador: idTrabajador ?? this.idTrabajador,
      fechaAsistencia: fechaAsistencia ?? this.fechaAsistencia,
      horaEntrada: horaEntrada ?? this.horaEntrada,
      horaSalida: clearHoraSalida ? null : horaSalida ?? this.horaSalida,
      minutosTrabajados: minutosTrabajados ?? this.minutosTrabajados,
      minutosExtra: minutosExtra ?? this.minutosExtra,
      minutosAtraso: minutosAtraso ?? this.minutosAtraso,
      observacionAsistencia:
          observacionAsistencia ?? this.observacionAsistencia,
      estaCorregidaAsistencia:
          estaCorregidaAsistencia ?? this.estaCorregidaAsistencia,
      estaAnuladaAsistencia:
          estaAnuladaAsistencia ?? this.estaAnuladaAsistencia,
    );
  }
}
