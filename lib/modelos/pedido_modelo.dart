class PedidoModelo {
  String? id;
  String choferId;
  List<String> ticketId; // Cambiado de productos a ticketId
  DateTime fechaEstimada;
  String estado;
  final Map<String, dynamic>? ubicacion;

  PedidoModelo({
    this.id,
    required this.choferId,
    required this.ticketId, // Cambiado de productos a ticketId
    required this.fechaEstimada,
    this.estado = 'pendiente',
    this.ubicacion,
  });

  // Método para convertir el modelo a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'choferId': choferId,
      'ticketId': ticketId, // Cambiado de productos a ticketId
      'fechaEstimada': fechaEstimada.toIso8601String(),
      'estado': estado,
      'ubicacion': ubicacion,
    };
  }

  // Método para crear un PedidoModelo a partir de un mapa
  static PedidoModelo fromMap(Map<String, dynamic> map, String id) {
    return PedidoModelo(
      id: id,
      choferId: map['clienteId'],
      ticketId: List<String>.from(
        map['ticketId'],
      ), // Cambiado de productos a ticketId
      fechaEstimada: DateTime.parse(map['fechaEstimada']),
      estado: map['estado'],
      ubicacion: map['ubicacion'],
    );
  }

  // Método para convertir un documento de Firestore en un PedidoModelo
  static PedidoModelo fromFirestore(
    Map<String, dynamic> firestoreDoc,
    String id,
  ) {
    return PedidoModelo(
      id: id,
      choferId: firestoreDoc['clienteId'],
      ticketId: List<String>.from(
        firestoreDoc['ticketId'],
      ), // Cambiado de productos a ticketId
      fechaEstimada: DateTime.parse(firestoreDoc['fechaEstimada']),
      estado: firestoreDoc['estado'],
      ubicacion: firestoreDoc['ubicacion'],
    );
  }
}
