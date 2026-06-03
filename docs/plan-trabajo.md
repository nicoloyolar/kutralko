# Plan de Trabajo Kutral Ko

## Estado Actual

Estamos en la base inicial de la app movil. Ya existe un proyecto Flutter fuente con interfaz inicial, entidades de dominio, datos mock, paleta visual basada en el logo y pruebas basicas.

Repositorio local activo:

`C:\Users\FULLUNLOCK\AndroidStudioProjects\kutral_ko`

Estado Git actual:

- Rama local: `master`
- Commits: pendiente primer commit
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
- Prepararse para un futuro panel administrativo vendible.

## Reglas De Arquitectura

- Mobile first: primero Flutter movil.
- Campos representativos en espanol tecnico: `idUsuario`, `nombreUsuario`, `idProducto`, `montoPago`, `fechaConsumo`.
- No borrar informacion critica: preferir estados como activo/anulado.
- Saldos calculados desde movimientos, no guardados como fuente principal.
- Separar features por dominio: usuarios, productos, consumos, pagos, dashboard, configuracion.
- Mantener UI premium, sobria y rapida para uso diario en local.

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

- Generar runners reales de Flutter: `android/`, `ios/`, `web/`.
- Crear primer commit Git.
- Definir si el nombre de carpeta queda como `kutral_ko` o si usamos otro nombre comercial.

## Iteracion 2 - Formularios y Edicion

Estado: pendiente.

Objetivo: convertir la maqueta funcional en una app editable.

Tareas:

- Crear formulario de usuario.
- Editar usuario existente.
- Activar/desactivar usuario.
- Crear formulario de producto.
- Editar producto existente.
- Activar/desactivar producto.
- Crear formulario de consumo.
- Crear formulario de pago/abono.
- Agregar validaciones visuales.
- Agregar estados vacios profesionales.

Criterio de exito:

- Se puede crear y editar usuarios/productos desde la app.
- Se puede simular un consumo y un pago desde acciones reales de UI.

## Iteracion 3 - Persistencia Local

Estado: pendiente.

Objetivo: guardar datos reales en el dispositivo.

Stack propuesto:

- Drift + SQLite para persistencia local.
- Repositorios por feature.
- Migraciones controladas.

Tareas:

- Agregar Drift.
- Definir tablas `usuarios`, `productos`, `consumos`, `pagos`, `categorias`.
- Implementar DAOs o repositorios.
- Reemplazar datos mock por consultas reales.
- Crear seed inicial opcional.

Criterio de exito:

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
2. Generar runners Flutter si Android Studio no los genera automaticamente.
3. Crear primer commit.
4. Empezar Iteracion 2 con formularios de usuario y producto.
