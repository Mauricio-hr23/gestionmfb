class PedidoModelo {
  String? id;
  String clienteId;
  List<String> productos;
  DateTime fechaEstimada;
  String estado;
  final Map<String, dynamic>? ubicacion;

  PedidoModelo({
    this.id,
    required this.clienteId,
    required this.productos,
    required this.fechaEstimada,
    this.estado = 'pendiente',
    this.ubicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'productos': productos,
      'fechaEstimada': fechaEstimada.toIso8601String(),
      'estado': estado,
      'ubicacion': ubicacion,
    };
  }

  static PedidoModelo fromMap(Map<String, dynamic> map, String id) {
    return PedidoModelo(
      id: id,
      clienteId: map['clienteId'],
      productos: List<String>.from(map['productos']),
      fechaEstimada: DateTime.parse(map['fechaEstimada']),
      estado: map['estado'],
      ubicacion: map['ubicacion'],
    );
  }
}
