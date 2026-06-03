# Plan de Trabajo Kutral Ko

## Estado Actual

Estamos en la base inicial de la app movil. Ya existe un proyecto Flutter fuente con interfaz inicial, entidades de dominio, datos mock, paleta visual basada en el logo y pruebas basicas.
Actualizacion 2026-06-03: la app ya arranca sin datos mock para permitir carga real desde UI. La capa Firebase/Firestore ya esta preparada en codigo y `android/app/google-services.json` fue agregado desde el proyecto Firebase real.

Repositorio local activo:

`C:\Users\FULLUNLOCK\AndroidStudioProjects\kutral_ko`

Estado Git actual:

- Rama local: `master`
- Commits: primer commit base creado (`1083c2c chore: estado base inicial`)
- Remoto: no configurado

## Objetivo Del Producto

Construir una aplicacion movil premium para restobares que permita administrar cuentas mensuales de clientes o convenios internos.

La app debe permitir:

- Crear y editar usuarios/clientes.
- Crear y editar productos de carta/barra.
- Registrar consumos asociados a un usuario.
- Registrar pagos o abonos manuales.
- Calcular saldo como consumos activos menos pagos activos.
- Anular movimientos sin perder trazabilidad.
- Usar perfiles diferenciados: administrador/dueño del bar y cliente.
- Compartir una fuente de verdad entre administrador y cliente.
- Prepararse para un futuro panel administrativo vendible.

## Reglas De Arquitectura

- Mobile first: primero Flutter movil.
- Campos representativos en espanol tecnico: `idUsuario`, `nombreUsuario`, `idProducto`, `montoPago`, `fechaConsumo`.
- No borrar informacion critica: preferir estados como activo/anulado.
- Saldos calculados desde movimientos, no guardados como fuente principal.
- Separar features por dominio: usuarios, productos, consumos, pagos, dashboard, configuracion.
- Mantener UI premium, sobria y rapida para uso diario en local.
- Formato monetario chileno: `$` a la izquierda y separador de miles con punto.

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

- Generar runners reales de Flutter: `android/` creado; `ios/` y `web/` pendientes.
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
- Crear formulario de pago/abono. Hecho inicial en memoria.
- Agregar validaciones visuales. Hecho inicial para campos requeridos y montos/cantidades.
- Agregar estados vacios profesionales. Hecho inicial.
- Separar estado editable en repositorios/controladores cuando empiece persistencia local.
- Agregar persistencia remota compartida. En progreso: Firebase Auth + Cloud Firestore agregados al proyecto Flutter.
- Reemplazar selector local Admin/Cliente por autenticacion real y permisos por rol. En progreso: login/registro email-password creado; perfiles se guardan en `perfiles/{uid}`.

Criterio de exito:

- Se puede crear y editar usuarios/productos desde la app.
- Se puede simular un consumo y un pago desde acciones reales de UI.

## Iteracion 3 - Persistencia Compartida

Estado: pendiente.

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
- Flujo rapido: seleccionar usuario -> registrar pago -> confirmar.
- Detalle de usuario con historial mixto de consumos y pagos.
- Filtros por mes.
- Edicion/anulacion de consumo.
- Edicion/anulacion de pago.

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

Estado: futuro.

Objetivo: preparar venta como sistema para locales.

Tareas futuras:

- Backend.
- Panel web administrativo.
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
