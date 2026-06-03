class Producto {
  const Producto({
    required this.idProducto,
    required this.nombreProducto,
    required this.nombreCategoriaProducto,
    required this.precioProducto,
    required this.estaActivoProducto,
    required this.esProductoFrecuente,
  });

  final String idProducto;
  final String nombreProducto;
  final String nombreCategoriaProducto;
  final int precioProducto;
  final bool estaActivoProducto;
  final bool esProductoFrecuente;
}
