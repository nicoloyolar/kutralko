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

  Producto copyWith({
    String? idProducto,
    String? nombreProducto,
    String? nombreCategoriaProducto,
    int? precioProducto,
    bool? estaActivoProducto,
    bool? esProductoFrecuente,
  }) {
    return Producto(
      idProducto: idProducto ?? this.idProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      nombreCategoriaProducto:
          nombreCategoriaProducto ?? this.nombreCategoriaProducto,
      precioProducto: precioProducto ?? this.precioProducto,
      estaActivoProducto: estaActivoProducto ?? this.estaActivoProducto,
      esProductoFrecuente: esProductoFrecuente ?? this.esProductoFrecuente,
    );
  }
}
