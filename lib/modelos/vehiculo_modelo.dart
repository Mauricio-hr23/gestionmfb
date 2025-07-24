class VehiculoModelo {
  final String id;
  final String numeroVehiculo;
  final String placa;
  final String? anio;
  final String estado;
  final String? fotoUrl;
  final String? choferId;

  VehiculoModelo({
    required this.id,
    required this.numeroVehiculo,
    required this.placa,
    this.anio,
    required this.estado,
    this.fotoUrl,
    this.choferId,
  });

  factory VehiculoModelo.fromMap(Map<String, dynamic> data, String docId) {
    return VehiculoModelo(
      id: docId,
      numeroVehiculo:
          data['numero_vehiculo'] ??
          '', // Ajusta a 'numero_vehiculo' si la clave en Firestore es esta
      placa: data['placa'] ?? '',
      anio: data['anio']?.toString(),
      estado: data['estado'] ?? 'activo',
      fotoUrl: data['fotoUrl'],
      choferId:
          data['chofer_id'] ??
          '', // Asegúrate de que el nombre en Firestore sea 'chofer_id'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero_vehiculo':
          numeroVehiculo, // Asegúrate de que la clave en Firestore coincida
      'placa': placa,
      'anio': anio,
      'estado': estado,
      'fotoUrl': fotoUrl,
      'chofer_id':
          choferId ??
          '', // Asegúrate de que el nombre en Firestore sea 'chofer_id'
    };
  }
}
