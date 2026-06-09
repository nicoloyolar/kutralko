# Modulo Personal Kutral Ko

## Objetivo

Extender Kutral Ko hacia una plataforma interna para administrar personal,
asistencia y consumos internos del equipo, usando la misma base Firebase y una
experiencia diferenciada por rol.

## Roles

### Administrador

Puede:

- Crear y editar trabajadores.
- Crear turnos programados.
- Corregir asistencia.
- Registrar consumos del personal.
- Aprobar solicitudes futuras.
- Generar reportes mensuales.
- Gestionar vinculacion entre perfil Firebase y trabajador.

### Trabajador

Puede:

- Marcar entrada.
- Marcar salida.
- Ver horas trabajadas.
- Ver horas extras y atrasos.
- Ver consumos acumulados.
- Ver descuentos estimados.

No puede:

- Modificar registros.
- Agregar consumos.
- Eliminar informacion.
- Alterar horarios.
- Aprobar solicitudes.

### Cliente

Mantiene el alcance actual:

- Ver cuenta mensual propia.
- Ver consumos y pagos vinculados a `idUsuarioPerfil`.
- Sin acciones administrativas.

## Modulo 1 - Control De Horarios

### Trabajador

Pantalla inicial:

- Estado actual: en turno / fuera de turno.
- Turno asignado del dia.
- Boton iniciar turno.
- Boton finalizar turno.

Al iniciar turno se registra:

- `idTrabajador`
- `fechaAsistencia`
- `horaEntrada`
- `origenRegistro`
- `creadoPorPerfil`

Al finalizar turno se registra:

- `horaSalida`
- `minutosTrabajados`
- `minutosExtra`
- `minutosAtraso`

Vista mensual:

- Horas trabajadas del mes.
- Horas extras acumuladas.
- Cantidad de atrasos.
- Historial de turnos realizados.

### Administrador

Dashboard de asistencia:

- Personal activo.
- Personal en turno.
- Personal fuera de turno.
- Horas extras acumuladas.
- Atrasos del dia.

Ficha individual:

- Turno programado.
- Hora de ingreso.
- Hora de salida.
- Horas trabajadas.
- Horas extras.
- Observaciones.

Acciones:

- Editar registro.
- Corregir horario.
- Agregar observaciones.
- Registrar auditoria de cambios.

## Modulo 2 - Consumo Del Personal

### Trabajador

Vista de solo lectura:

- Consumo acumulado del mes.
- Historial de consumos.
- Total estimado a descontar.

### Administrador

Registro de consumos:

- Seleccionar trabajador.
- Seleccionar producto.
- Ingresar valor.
- Registrar consumo.

Dashboard de consumos:

- Consumo total del personal.
- Consumo por trabajador.
- Historial de movimientos.
- Ranking de consumos.
- Reporte mensual.

## Cierre De Mes

Reporte para remuneraciones:

- Trabajador.
- Total consumido.
- Horas trabajadas.
- Horas extras.
- Atrasos.
- Observaciones.

## Colecciones Firestore Propuestas

- `trabajadores`
- `turnosProgramados`
- `asistencias`
- `consumosPersonal`
- `cierresPersonal`
- `auditoria`

## Campos Base

### `trabajadores`

- `idTrabajador`
- `nombreTrabajador`
- `emailTrabajador`
- `telefonoTrabajador`
- `cargoTrabajador`
- `estaActivoTrabajador`
- `idPerfil`

### `turnosProgramados`

- `idTurno`
- `idTrabajador`
- `fechaTurno`
- `horaInicioProgramada`
- `horaFinProgramada`
- `notaTurno`
- `estaActivoTurno`

### `asistencias`

- `idAsistencia`
- `idTrabajador`
- `fechaAsistencia`
- `horaEntrada`
- `horaSalida`
- `minutosTrabajados`
- `minutosExtra`
- `minutosAtraso`
- `observacionAsistencia`
- `estaCorregidaAsistencia`
- `estaAnuladaAsistencia`

### `consumosPersonal`

- `idConsumoPersonal`
- `idTrabajador`
- `idProducto`
- `nombreProductoSnapshot`
- `montoConsumoPersonal`
- `fechaConsumoPersonal`
- `notaConsumoPersonal`
- `estaAnuladoConsumoPersonal`

## MVP

1. Registro de entrada y salida.
2. Historial de horas trabajadas.
3. Registro de consumos por administrador.
4. Consulta de consumos por trabajador.
5. Dashboard administrativo.
6. Reporte mensual para remuneraciones.

## Avance Inicial Implementado

- Modelos Flutter: `Trabajador`, `Asistencia`, `ConsumoPersonal`.
- Colecciones Firestore conectadas: `trabajadores`, `asistencias`, `consumosPersonal`.
- Seccion "Personal" visible en app movil y panel web.
- Administrador puede crear trabajadores.
- Administrador puede registrar consumos internos desde productos existentes.
- Trabajador vinculado por `idTrabajadorPerfil` puede iniciar/finalizar turno.
- Trabajador puede ver horas del mes, consumos y descuento estimado.
- Reglas e indices Firestore iniciales agregados.
- Ficha individual de trabajador para administracion con resumen de horas,
  extras, atrasos, consumo/descuento e historial.
- Correccion administrativa de asistencia: minutos trabajados, extras,
  atrasos, observacion y anulacion.
- Anulacion de consumos internos con trazabilidad via auditoria.
- Exportacion mensual de reporte de personal en PDF y Excel desde panel web.
- Gestion amigable de perfiles desde configuracion admin: promover admin,
  asignar trabajador, asignar cliente, confirmaciones y auditoria.

## Decision De Arquitectura

Este modulo debe vivir junto a la app actual, pero separado por dominio. La app
actual de cuentas de clientes no se elimina: se convierte en un modulo mas de la
plataforma interna Kutral Ko.
