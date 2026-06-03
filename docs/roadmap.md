# Roadmap Kutral Ko

## Principios

- Mobile first: la primera entrega vive en Flutter movil.
- Interfaz premium: sobria, rapida, clara para uso diario en local.
- Todo editable o anulable: usuarios, productos, consumos y pagos.
- Saldos calculados: el saldo se obtiene desde consumos activos menos pagos activos.
- Campos representativos: usar nombres como `idUsuario`, `nombreUsuario`, `idProducto`, `montoPago`.

## Iteracion 1

- Base visual con paleta carbon, dorado, ambar y naranja.
- Entidades iniciales: `Usuario`, `Producto`, `Consumo`, `Pago`.
- Dashboard con saldo pendiente, consumido y abonado.
- Vistas iniciales de clientes, carta y cuenta mensual.
- Datos mock para validar flujo y diseno.

## Iteracion 2

- Formularios reales para crear y editar usuarios.
- Formularios reales para crear y editar productos.
- Validaciones de campos y estados vacios.
- Acciones para anular registros sin borrarlos definitivamente.

## Iteracion 3

- Persistencia local con Drift/SQLite.
- Repositorios por feature.
- Migraciones de base de datos.
- Seed inicial de categorias/productos.

## Iteracion 4

- Registro real de consumos.
- Registro real de pagos/abonos manuales.
- Detalle de usuario con historial y saldo.
- Filtro mensual.

## Iteracion 5

- Cierre y reapertura de mes.
- Auditoria basica de ediciones/anulaciones.
- PIN de administrador.
- Preparacion para panel web y backend.
