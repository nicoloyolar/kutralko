# Plan de Trabajo Kutral Ko

## Estado Actual

Estamos en la base inicial de la app movil. Ya existe un proyecto Flutter fuente con interfaz inicial, entidades de dominio, datos mock, paleta visual basada en el logo y pruebas basicas.
Actualizacion 2026-06-03: la app ya arranca sin datos mock para permitir carga real desde UI. La capa Firebase/Firestore ya esta preparada en codigo y `android/app/google-services.json` fue agregado desde el proyecto Firebase real.
Actualizacion 2026-06-05: se inicio pulido de producto con lenguaje visible menos tecnico, estetica mas negra/dorada y flujo de "Nueva carga" para agregar varios productos a un mismo cliente antes de guardar. La vista de movimientos ahora muestra nombres de cliente y mezcla consumos/pagos por fecha. Los clientes ya abren un detalle con resumen, historial propio y acciones rapidas preseleccionadas. Se agrego anulacion de consumos/pagos con confirmacion, manteniendo trazabilidad y recalculo de saldos. Luego se reemplazo el selector local por roles reales desde `perfiles/{uid}`, se agrego filtro mensual, edicion de consumos/pagos, reglas Firestore versionadas, indices para consultas por cliente, auditoria basica y vinculacion admin de perfil-cliente.
Actualizacion 2026-06-08: se inicio panel web usando el mismo proyecto Flutter/Firebase. Se genero runner `web/`, branding web y navegacion lateral responsive para pantallas anchas, manteniendo bottom navigation en movil. El panel conserva diferenciacion de responsabilidades: administrador administra clientes/carta/cargas/pagos/permisos; cliente revisa su cuenta e historial vinculado.
Actualizacion 2026-06-08 tarde: se inicio MVP de Personal Interno con modelos `Trabajador`, `Asistencia` y `ConsumoPersonal`; repositorio Firestore; reglas/indices; seccion "Personal" en mobile/web; alta de trabajadores; registro admin de consumo interno; y acciones trabajador para iniciar/finalizar turno.
Actualizacion 2026-06-08 noche: se agrego ficha individual de trabajador para admin, con resumen mensual, estado de turno, historial de asistencias, historial de consumos internos, correccion de asistencia y anulacion de consumos internos con auditoria.
Actualizacion 2026-06-09: se agrego exportacion de reporte mensual de personal en PDF y Excel desde la seccion Personal del panel web.
Actualizacion 2026-06-09 perfiles: la configuracion admin ahora agrupa perfiles en sin vincular, administradores, trabajadores y clientes; agrega acciones amigables para cambiar rol, vincular cliente/trabajador, confirmaciones y auditoria.

Repositorio local activo:

`C:\Users\FULLUNLOCK\AndroidStudioProjects\kutral_ko`

Estado Git actual:

- Rama local: `master`
- Commits: primer commit base creado (`1083c2c chore: estado base inicial`)
- Remoto: no configurado

## Objetivo Del Producto

Construir una aplicacion movil premium para restobares que permita administrar cuentas mensuales de clientes o convenios internos.
El producto se expande hacia una plataforma interna de operacion para Kutral Ko,
manteniendo el modulo original de cuentas/consumos de clientes y sumando gestion
de personal, asistencia y consumos internos.

La app debe permitir:

- Crear y editar usuarios/clientes.
- Crear y editar productos de carta/barra.
- Registrar consumos asociados a un usuario.
- Registrar pagos o abonos manuales.
- Calcular saldo como consumos activos menos pagos activos.
- Anular movimientos sin perder trazabilidad.
- Usar perfiles diferenciados: administrador/dueño del bar y cliente.
- Compartir una fuente de verdad entre administrador y cliente.
- Controlar horarios y asistencia del personal.
- Controlar consumos internos del personal.
- Generar reportes mensuales para remuneraciones/descuentos.
- Prepararse para un futuro panel administrativo vendible.
- Usar un panel web conectado a la misma fuente de verdad.

## Reglas De Arquitectura

- Mobile first: primero Flutter movil.
- Campos representativos en espanol tecnico: `idUsuario`, `nombreUsuario`, `idProducto`, `montoPago`, `fechaConsumo`.
- No borrar informacion critica: preferir estados como activo/anulado.
- Saldos calculados desde movimientos, no guardados como fuente principal.
- Separar features por dominio: usuarios, productos, consumos, pagos, dashboard, configuracion.
- Separar tambien dominios internos: trabajadores, turnos, asistencias, consumos del personal, reportes.
- Mantener UI premium, sobria y rapida para uso diario en local.
- Formato monetario chileno: `$` a la izquierda y separador de miles con punto.
- En UI visible, usar lenguaje humano y operativo; reservar nombres tecnicos como `nombreProducto` o `idUsuario` para codigo, Firestore y documentacion tecnica.
- Para el flujo diario, priorizar acciones de baja friccion: seleccionar cliente una vez, cargar varios productos, revisar total y confirmar.

## Iteracion 1 - Base Movil Premium

Estado: completada parcialmente.

Incluye:

- Tema visual inicial carbon/dorado/ambar/naranja.
- Asset de logo refinado.
- Entidades `Usuario`, `Producto`, `Consumo`, `Pago`.
- Dashboard con saldo pendiente, total consumido y total abonado.
- Vistas iniciales de clientes, carta y cuenta mensual.
- Datos mock para validar flujo.
- Test de calculo de saldo.

Pendiente de esta iteracion:

- Generar runners reales de Flutter: `android/` y `web/` creados; `ios/` pendiente.
- Crear primer commit Git. Hecho: `1083c2c chore: estado base inicial`.
- Definir si el nombre de carpeta queda como `kutral_ko` o si usamos otro nombre comercial.
- Branding Android: icono launcher y splash screen usando logo Kutral Ko. Hecho inicial.

Nota 2026-06-03: se intento generar runners con
`flutter create --platforms=android,ios,web --project-name kutral_ko --org com.kutralko .`,
pero el comando quedo bloqueado sin salida y no escribio carpetas de plataforma. `flutter doctor -v`
responde correctamente; quedan pendientes cmdline-tools/licencias Android y reintentar generacion.
Luego se genero correctamente el runner Android con
`flutter create --platforms=android --project-name kutral_ko --org com.kutralko .`.
La app compila e instala en el emulador `emulator-5554`.

## Iteracion 2 - Formularios y Edicion

Estado: en progreso.

Objetivo: convertir la maqueta funcional en una app editable.

Tareas:

- Crear formulario de usuario. Hecho inicial en memoria.
- Editar usuario existente. Hecho inicial en memoria.
- Activar/desactivar usuario. Hecho inicial en memoria.
- Crear formulario de producto. Hecho inicial en memoria.
- Editar producto existente. Hecho inicial en memoria.
- Activar/desactivar producto. Hecho inicial en memoria.
- Crear formulario de consumo. Hecho inicial en memoria.
- Mejorar formulario de consumo para cargar varios productos a un cliente en una sola confirmacion. Hecho inicial: la UI arma una "Nueva carga" y guarda cada producto como un `Consumo` individual para mantener compatibilidad con el modelo actual.
- Crear formulario de pago/abono. Hecho inicial en memoria.
- Agregar validaciones visuales. Hecho inicial para campos requeridos y montos/cantidades.
- Agregar estados vacios profesionales. Hecho inicial.
- Reemplazar labels tecnicos visibles por textos de producto. Hecho inicial: campos como `nombreProducto`, `idUsuario`, `montoPago` pasaron a etiquetas humanas.
- Elevar estetica negro/dorado premium. Hecho inicial: app bar y navegacion inferior en carbon oscuro con acentos dorados.
- Mejorar legibilidad de movimientos. Hecho inicial: consumos y pagos se muestran en una sola lista ordenada por fecha y con nombre de cliente resuelto desde `usuarios`.
- Crear detalle de cliente. Hecho inicial: tocar un cliente abre una hoja con saldo, total consumido, total abonado, historial propio y acciones rapidas para cargar consumo o pago con cliente preseleccionado.
- Anular consumos y pagos desde historiales. Hecho inicial: la accion pide confirmacion, marca el movimiento como anulado, lo mantiene visible y deja de afectar el saldo.
- Editar consumos y pagos desde historiales. Hecho inicial: se conservan id/fecha/anulacion y se actualizan datos operativos.
- Filtro mensual. Hecho inicial: el balance, clientes, historial general y detalle de cliente usan el mes seleccionado.
- Separar estado editable en repositorios/controladores cuando empiece persistencia local.
- Agregar persistencia remota compartida. En progreso: Firebase Auth + Cloud Firestore agregados al proyecto Flutter.
- Reemplazar selector local Admin/Cliente por autenticacion real y permisos por rol. Hecho inicial: dashboard lee `perfiles/{uid}.rolPerfil`; nuevas cuentas parten como cliente.
- Privacidad real por cliente. Hecho inicial: el repositorio consulta `usuarios`, `consumos` y `pagos` por `idUsuarioPerfil` cuando el perfil es cliente.

Criterio de exito:

- Se puede crear y editar usuarios/productos desde la app.
- Se puede simular un consumo y un pago desde acciones reales de UI.
- Se puede cargar mas de un producto para el mismo cliente sin repetir todo el flujo.
- Se puede abrir un cliente y operar desde su detalle sin perder contexto.
- Se puede anular un consumo o pago sin borrar su registro.
- Se puede filtrar por mes y editar movimientos activos.
- El cliente vinculado no descarga movimientos de otros clientes.

## Iteracion 3 - Persistencia Compartida

Estado: en progreso.

Objetivo: guardar datos reales y compartir una fuente de verdad entre administrador y cliente.

Stack propuesto:

- Firebase Auth para perfiles administrador/cliente.
- Cloud Firestore para usuarios, productos, consumos y pagos compartidos.
- Reglas de seguridad por rol.
- Drift + SQLite opcional mas adelante para cache/offline avanzado.
- Repositorios por feature.
- Migraciones/control de esquema.

Tareas:

- Crear proyecto Firebase. Hecho manualmente desde Firebase Console.
- Agregar `google-services.json` para Android. Hecho.
- Agregar `firebase_core`, `firebase_auth`, `cloud_firestore`. Hecho.
- Inicializar Firebase en `main.dart`. Hecho.
- Configurar plugin Android `com.google.gms.google-services`. Hecho.
- Implementar repositorio Firestore para `usuarios`, `productos`, `consumos`, `pagos`. Hecho inicial.
- Modelar roles: administrador y cliente. Hecho inicial en registro (`perfiles/{uid}.rolPerfil`).
- Leer roles reales desde `perfiles/{uid}` en dashboard. Hecho.
- Agregar reglas Firestore versionadas. Hecho inicial en `firestore.rules`; bloquean escrituras a no administradores, deshabilitan borrado y restringen lectura de usuarios/movimientos al cliente vinculado.
- Agregar indices Firestore para consultas por cliente. Hecho en `firestore.indexes.json`.
- Vincular perfiles cliente a `usuarios` con `idUsuarioPerfil`. Hecho inicial desde configuracion admin.
- Definir tablas `usuarios`, `productos`, `consumos`, `pagos`, `categorias`.
- Implementar DAOs o repositorios.
- Reemplazar estado en memoria por consultas reales.
- Crear seed inicial opcional.

Criterio de exito:

- Administrador y cliente ven la misma fuente de verdad.
- La app conserva usuarios, productos, consumos y pagos al cerrarse y abrirse.

## Iteracion 4 - Flujo Diario Del Local

Estado: pendiente.

Objetivo: que el administrador pueda usar la app en operacion real.

Tareas:

- Flujo rapido: seleccionar usuario -> agregar consumo -> confirmar.
- Flujo rapido: seleccionar usuario -> agregar varios productos -> revisar total -> confirmar. Hecho inicial en Iteracion 2 como "Nueva carga".
- Flujo rapido: seleccionar usuario -> registrar pago -> confirmar.
- Detalle de usuario con historial mixto de consumos y pagos. Hecho inicial como hoja inferior desde Inicio/Clientes.
- Historial general mixto de consumos y pagos con nombre de cliente. Hecho inicial en vista "Cuenta mensual".
- Filtros por mes. Hecho inicial desde balance principal.
- Edicion/anulacion de consumo. Hecho inicial.
- Edicion/anulacion de pago. Hecho inicial.
- Auditoria basica de ediciones/anulaciones. Hecho inicial en coleccion `auditoria`.

Criterio de exito:

- Un consumo aumenta el saldo.
- Un pago disminuye el saldo.
- Una anulacion recalcula el saldo correctamente.

## Iteracion 5 - Cuenta Mensual

Estado: pendiente.

Objetivo: administrar meses de cuenta.

Tareas:

- Vista de resumen mensual por usuario.
- Total consumido mensual.
- Total abonado mensual.
- Saldo pendiente mensual.
- Cerrar mes.
- Reabrir mes solo como accion administradora.
- Estado visual: abierto, cerrado, pagado, pendiente.

Criterio de exito:

- Se puede revisar un mes y saber exactamente cuanto se debe, cuanto se pago y que movimientos lo componen.

## Iteracion 6 - Seguridad y Auditoria

Estado: pendiente.

Objetivo: preparar la app para uso confiable en local.

Tareas:

- PIN de administrador.
- Bloquear acciones sensibles.
- Registro de auditoria para ediciones y anulaciones.
- Confirmaciones de acciones destructivas o sensibles.

Criterio de exito:

- No se puede alterar informacion importante sin dejar rastro.

## Iteracion 7 - Pulido Premium

Estado: pendiente.

Objetivo: elevar calidad visual y experiencia.

Tareas:

- Mejorar logo final con fondo transparente real.
- Ajustar tipografia, espaciados y estados visuales.
- Microinteracciones sobrias.
- Iconografia consistente.
- Pruebas en mobile chico y mobile grande.
- Preparar identidad para venta del producto.

Criterio de exito:

- La app se siente como producto comercial, no prototipo.

## Iteracion 8 - Preparacion Panel Admin

Estado: en progreso.

Objetivo: preparar venta como sistema para locales.

Tareas futuras:

- Backend.
- Panel web administrativo.
- Panel web administrativo. Hecho inicial: runner web, branding y navegacion lateral responsive.
- Modulo personal interno: futuro inmediato.
- Multi-local.
- Roles y permisos.
- Reportes.
- Exportacion PDF/Excel.
- Sincronizacion en la nube.
- Planes comerciales.

## Proxima Decision

Antes de seguir desarrollando conviene resolver:

1. Abrir `C:\Users\FULLUNLOCK\AndroidStudioProjects\kutral_ko` como proyecto principal.
2. Generar runners restantes (`ios/`, `web/`) cuando sean necesarios.
3. Definir y aplicar reglas Firestore para perfiles administrador/cliente.
4. Definir nombre comercial/carpeta.
5. Continuar Iteracion 2 con detalle de usuario, anulaciones editables y preparacion para repositorios.

## Iteracion 9 - Personal Interno

Estado: propuesta prioritaria.

Objetivo: integrar control de horarios y consumos internos del personal sin
romper el modulo actual de cuentas de clientes.

Documento base:

- `docs/requisitos-personal.md`

Modulos:

- Trabajadores.
- Turnos programados.
- Asistencias.
- Consumos del personal.
- Dashboard administrativo de personal.
- Vista trabajador de solo lectura/acciones permitidas.
- Reporte mensual para remuneraciones.

Roles:

- `administrador`: crea turnos, corrige asistencia, registra consumos, genera reportes y gestiona personal.
- `trabajador`: marca entrada/salida y consulta horas/consumos/descuentos propios.
- `cliente`: mantiene acceso de cuenta mensual vinculada actual.

Colecciones Firestore propuestas:

- `trabajadores`
- `turnosProgramados`
- `asistencias`
- `consumosPersonal`
- `cierresPersonal`

Criterio de exito MVP:

- Un trabajador puede iniciar y finalizar turno.
- El administrador puede ver quien esta en turno. Hecho inicial.
- El administrador puede registrar consumo interno a un trabajador. Hecho inicial.
- El trabajador ve sus consumos y descuentos estimados. Hecho inicial.
- El administrador puede generar un resumen mensual por trabajador. Hecho inicial en ficha individual.
- El administrador puede exportar reporte mensual para remuneraciones en PDF y Excel. Hecho inicial.
