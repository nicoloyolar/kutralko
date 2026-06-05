# Roadmap Kutral Ko

## Principios

- Mobile first: la primera entrega vive en Flutter movil.
- Interfaz premium: sobria, rapida, clara para uso diario en local.
- Todo editable o anulable: usuarios, productos, consumos y pagos.
- Saldos calculados: el saldo se obtiene desde consumos activos menos pagos activos.
- Campos representativos: usar nombres como `idUsuario`, `nombreUsuario`, `idProducto`, `montoPago`.
- Textos visibles para personas: en pantalla usar "Nombre del producto", "Cliente", "Monto pagado", etc.; los nombres tecnicos quedan para codigo y datos.
- Estetica objetivo: negro/carbon como base, dorado como acento premium, interfaz compacta para operacion diaria.

## Iteracion 1

- Base visual con paleta carbon, dorado, ambar y naranja.
- Entidades iniciales: `Usuario`, `Producto`, `Consumo`, `Pago`.
- Dashboard con saldo pendiente, consumido y abonado.
- Vistas iniciales de clientes, carta y cuenta mensual.
- Datos mock para validar flujo y diseno.

## Iteracion 2

- Formularios reales para crear y editar usuarios.
- Formularios reales para crear y editar productos.
- Formulario de "Nueva carga" para seleccionar un cliente y agregar varios productos antes de guardar.
- Subtotal/total visible antes de confirmar consumos.
- Historial general de movimientos con consumos y pagos mezclados por fecha y nombres de cliente visibles.
- Detalle inicial de cliente con saldo, totales, historial y acciones rapidas.
- Filtro mensual inicial desde el balance principal.
- Edicion y anulacion inicial de consumos/pagos activos.
- Validaciones de campos y estados vacios.
- Acciones para anular registros sin borrarlos definitivamente.

## Iteracion 3

- Firebase Auth y Cloud Firestore como fuente compartida.
- Roles reales desde `perfiles/{uid}`.
- Reglas Firestore por administrador/cliente.
- Vinculo `idUsuarioPerfil` para asociar cuenta auth con cliente operativo.
- Consultas Firestore filtradas por cliente para perfiles no administradores.
- Auditoria inicial de ediciones/anulaciones.
- Drift/SQLite queda como opcion posterior para cache/offline avanzado.
- Seed inicial opcional de categorias/productos.

## Iteracion 4

- Registro real de consumos multi-producto.
- Registro real de pagos/abonos manuales.
- Profundizar detalle de usuario con detalle expandido de cada movimiento.
- Fortalecer auditoria con diff antes/despues y motivo obligatorio para anulaciones.

## Iteracion 5

- Cierre y reapertura de mes.
- Auditoria basica de ediciones/anulaciones.
- PIN de administrador.
- Preparacion para panel web y backend.
